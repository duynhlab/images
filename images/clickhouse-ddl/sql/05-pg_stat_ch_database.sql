-- Applied to EVERY replica individually, like 00-database.sql, and for the same
-- reason: the database's own Keeper log then carries the table DDL in 50..80.
-- A second database rather than tables inside `otel`: the writer is PostgreSQL
-- (the pg_stat_ch extension, native protocol) with its own INSERT-only user,
-- and the extension's `clickhouse_database` setting names this database.
CREATE DATABASE IF NOT EXISTS pg_stat_ch
    ENGINE = Replicated('/clickhouse/databases/pg_stat_ch', '{shard}', '{replica}');
