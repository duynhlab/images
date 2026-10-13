-- Every statement that raised (err_elevel > 0) with its full context, kept
-- for 30 days: long enough to find what the auto_explain 7-day window has
-- already dropped. Upstream keeps 7 days; errors are a small fraction of
-- events_raw so the longer window is cheap. Same TO-style shape as 60.
-- Must be created AFTER 50-pg_stat_ch_events_raw.sql.
CREATE TABLE IF NOT EXISTS pg_stat_ch.errors_recent
(
    `ts` DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
    `db_name` LowCardinality(String),
    `db_user` LowCardinality(String),
    `app` LowCardinality(String),
    `client_addr` String,
    `pid` Int32,
    `query_id` Int64,
    `err_sqlstate` LowCardinality(String),
    `err_elevel` UInt8,
    `err_message` String CODEC(ZSTD(1)),
    `query_text` String CODEC(ZSTD(3))
)
ENGINE = ReplicatedMergeTree
PARTITION BY toDate(ts)
ORDER BY (db_name, ts)
TTL toDateTime(ts) + toIntervalDay(7) TO VOLUME 'cold', toDateTime(ts) + toIntervalDay(30)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1, storage_policy = 'hot_cold';

CREATE MATERIALIZED VIEW IF NOT EXISTS pg_stat_ch.errors_recent_mv TO pg_stat_ch.errors_recent
AS SELECT
    ts,
    db_name,
    db_user,
    app,
    client_addr,
    pid,
    query_id,
    err_sqlstate,
    err_elevel,
    err_message,
    query_text
FROM pg_stat_ch.events_raw
WHERE err_elevel > 0;
