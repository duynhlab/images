-- Per-statement 5-minute rollup: the dashboard's long-range source, so a
-- 30-day "top statements" query reads this table instead of events_raw.
-- Target table first, then a TO-style view that owns no storage (the only
-- legal view shape inside a Replicated database — see 40-otel_traces_*_mv).
-- Partial aggregates: finalise with countMerge / sumMerge / minMerge /
-- maxMerge / quantilesTDigestMerge(0.5, 0.95, 0.99). The quantile list is
-- part of the column type; changing it means a new table.
-- Must be created AFTER 50-pg_stat_ch_events_raw.sql.
CREATE TABLE IF NOT EXISTS pg_stat_ch.query_stats_5m
(
    `bucket` DateTime COMMENT '5-minute bucket start',
    `db_name` LowCardinality(String),
    `query_id` Int64,
    `db_operation` LowCardinality(String),
    `calls_state` AggregateFunction(count),
    `duration_sum_state` AggregateFunction(sum, UInt64),
    `duration_min_state` AggregateFunction(min, UInt64),
    `duration_max_state` AggregateFunction(max, UInt64),
    `duration_q_state` AggregateFunction(quantilesTDigest(0.5, 0.95, 0.99), UInt64),
    `rows_sum_state` AggregateFunction(sum, UInt64),
    `shared_hit_sum_state` AggregateFunction(sum, Int64),
    `shared_read_sum_state` AggregateFunction(sum, Int64),
    `errors_sum_state` AggregateFunction(sum, UInt64),
    `query_text_state` AggregateFunction(any, String) COMMENT 'One sample text per fingerprint; finalise with anyMerge'
)
ENGINE = ReplicatedAggregatingMergeTree
PARTITION BY toYYYYMM(bucket)
ORDER BY (db_name, bucket, query_id, db_operation)
TTL bucket + toIntervalDay(30) TO VOLUME 'cold', bucket + toIntervalDay(90)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1, storage_policy = 'hot_cold';

CREATE MATERIALIZED VIEW IF NOT EXISTS pg_stat_ch.query_stats_5m_mv TO pg_stat_ch.query_stats_5m
AS SELECT
    toStartOfFiveMinutes(toDateTime(ts)) AS bucket,
    db_name,
    query_id,
    db_operation,
    countState() AS calls_state,
    sumState(duration_us) AS duration_sum_state,
    minState(duration_us) AS duration_min_state,
    maxState(duration_us) AS duration_max_state,
    quantilesTDigestState(0.5, 0.95, 0.99)(duration_us) AS duration_q_state,
    sumState(rows) AS rows_sum_state,
    sumState(shared_blks_hit) AS shared_hit_sum_state,
    sumState(shared_blks_read) AS shared_read_sum_state,
    sumState(toUInt64(err_elevel > 0)) AS errors_sum_state,
    anyState(query_text) AS query_text_state
FROM pg_stat_ch.events_raw
GROUP BY bucket, db_name, query_id, db_operation;
