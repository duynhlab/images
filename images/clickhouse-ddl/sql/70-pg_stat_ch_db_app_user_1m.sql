-- Load attribution per minute: which database, application_name and role
-- carried the calls, time and errors. Same TO-style shape as 60.
-- Must be created AFTER 50-pg_stat_ch_events_raw.sql.
CREATE TABLE IF NOT EXISTS pg_stat_ch.db_app_user_1m
(
    `bucket` DateTime COMMENT '1-minute bucket start',
    `db_name` LowCardinality(String),
    `application_name` LowCardinality(String),
    `db_user` LowCardinality(String),
    `db_operation` LowCardinality(String),
    `calls_state` AggregateFunction(count),
    `duration_sum_state` AggregateFunction(sum, UInt64),
    `duration_q_state` AggregateFunction(quantilesTDigest(0.5, 0.95, 0.99), UInt64),
    `errors_sum_state` AggregateFunction(sum, UInt64)
)
ENGINE = ReplicatedAggregatingMergeTree
PARTITION BY toYYYYMM(bucket)
ORDER BY (db_name, bucket, application_name, db_user, db_operation)
TTL bucket + toIntervalDay(30) TO VOLUME 'cold', bucket + toIntervalDay(90)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1, storage_policy = 'hot_cold';

-- Runs as `default`: the writer (pg_stat_ch) holds INSERT only, and a view
-- without SQL SECURITY would check SELECT on events_raw against it.
CREATE MATERIALIZED VIEW IF NOT EXISTS pg_stat_ch.db_app_user_1m_mv TO pg_stat_ch.db_app_user_1m
DEFINER = default SQL SECURITY DEFINER
AS SELECT
    toStartOfMinute(toDateTime(ts)) AS bucket,
    db_name,
    application_name,
    db_user,
    db_operation,
    countState() AS calls_state,
    sumState(duration_us) AS duration_sum_state,
    quantilesTDigestState(0.5, 0.95, 0.99)(duration_us) AS duration_q_state,
    sumState(toUInt64(err_elevel > 0)) AS errors_sum_state
FROM pg_stat_ch.events_raw
GROUP BY bucket, db_name, application_name, db_user, db_operation;
