-- One row per PostgreSQL statement execution, inserted by the pg_stat_ch
-- extension (v0.4.0) over the native protocol as
-- `INSERT INTO events_raw (<44 named columns>)`. The column set and types are
-- upstream's schema/migrations/20260519000001_create_initial_schema.sql; the
-- engine, ordering, TTL and storage policy are ours. The upstream file is plain
-- MergeTree with ORDER BY (instance_ubid, ts) and a 180-day TTL, which fits
-- neither this three-replica store nor its 7-day hot / 90-day retention.
--
-- Renaming or retyping a column the extension inserts is a runtime insert
-- failure (send_failures in pg_stat_ch_stats()), not an apply-time error.
-- The eight resource columns at the end (instance_ubid .. pod_name) are only
-- filled by the extension's Arrow/OTel path; the native path leaves them at
-- their defaults. db_name is what tells the two CNPG clusters apart on this
-- platform, because every database name is unique across them.
--
-- The extension inserts the client's application_name as `app`. That column is
-- EPHEMERAL: it is accepted on INSERT but never stored, and its value is
-- stored as `application_name` through the DEFAULT. Query `application_name`;
-- `app` cannot be selected.
CREATE TABLE IF NOT EXISTS pg_stat_ch.events_raw
(
    `ts` DateTime64(6, 'UTC') COMMENT 'Statement start time' CODEC(Delta(8), ZSTD(1)),
    `duration_us` UInt64 COMMENT 'Wall-clock duration in microseconds',
    `db_name` LowCardinality(String) COMMENT 'Database name',
    `db_user` LowCardinality(String) COMMENT 'Session role',
    `pid` Int32 COMMENT 'Backend process id',
    `query_id` Int64 COMMENT 'PostgreSQL compute_query_id fingerprint; 0 when unavailable',
    `db_operation` LowCardinality(String) COMMENT 'SELECT, INSERT, UPDATE, DELETE, MERGE, UTILITY, ...',
    `rows` UInt64 COMMENT 'Rows returned or affected',
    `query_text` String COMMENT 'Normalised statement, literals replaced by $N, truncated at 2 KB' CODEC(ZSTD(3)),
    `shared_blks_hit` Int64,
    `shared_blks_read` Int64,
    `shared_blks_dirtied` Int64,
    `shared_blks_written` Int64,
    `local_blks_hit` Int64,
    `local_blks_read` Int64,
    `local_blks_dirtied` Int64,
    `local_blks_written` Int64,
    `temp_blks_read` Int64,
    `temp_blks_written` Int64,
    `shared_blk_read_time_us` Int64 COMMENT 'Needs track_io_timing = on',
    `shared_blk_write_time_us` Int64,
    `local_blk_read_time_us` Int64,
    `local_blk_write_time_us` Int64,
    `temp_blk_read_time_us` Int64,
    `temp_blk_write_time_us` Int64,
    `wal_records` Int64,
    `wal_fpi` Int64,
    `wal_bytes` UInt64,
    `cpu_user_time_us` Int64 COMMENT 'getrusage delta over the statement',
    `cpu_sys_time_us` Int64,
    `jit_functions` Int32,
    `jit_generation_time_us` Int32,
    `jit_deform_time_us` Int32,
    `jit_inlining_time_us` Int32,
    `jit_optimization_time_us` Int32,
    `jit_emission_time_us` Int32,
    `parallel_workers_planned` Int16,
    `parallel_workers_launched` Int16,
    `err_sqlstate` LowCardinality(String) COMMENT 'SQLSTATE when the statement raised; empty otherwise',
    `err_elevel` UInt8 COMMENT 'PostgreSQL elevel; 0 = no error, 21 = ERROR',
    `err_message` String COMMENT 'Error text, truncated at 2 KB' CODEC(ZSTD(1)),
    `app` String EPHEMERAL COMMENT 'Insert-only: the extension writes application_name under this name',
    `application_name` LowCardinality(String) DEFAULT app COMMENT 'Client application_name',
    `client_addr` String COMMENT 'Client address; the pooler for pooled sessions',
    `instance_ubid` String DEFAULT '' COMMENT 'Arrow/OTel path only',
    `server_ubid` String DEFAULT '' COMMENT 'Arrow/OTel path only',
    `server_role` LowCardinality(String) DEFAULT '' COMMENT 'Arrow/OTel path only',
    `read_replica_type` LowCardinality(String) DEFAULT 'none' COMMENT 'Arrow/OTel path only',
    `region` LowCardinality(String) DEFAULT '' COMMENT 'Arrow/OTel path only',
    `cell` LowCardinality(String) DEFAULT '' COMMENT 'Arrow/OTel path only',
    `service_version` LowCardinality(String) DEFAULT '' COMMENT 'Arrow/OTel path only',
    `host_id` String DEFAULT '' COMMENT 'Arrow/OTel path only',
    `pod_name` String DEFAULT '' COMMENT 'Arrow/OTel path only'
)
ENGINE = ReplicatedMergeTree
PARTITION BY toDate(ts)
ORDER BY (db_name, ts)
TTL toDateTime(ts) + toIntervalDay(7) TO VOLUME 'cold', toDateTime(ts) + toIntervalDay(90)
SETTINGS index_granularity = 8192, ttl_only_drop_parts = 1, storage_policy = 'hot_cold';
