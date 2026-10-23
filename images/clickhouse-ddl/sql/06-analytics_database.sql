-- Applied to EVERY replica individually, like 00-database.sql. The commerce
-- read model (RFC-0030): PeerDB's mirrors create the raw tables here as
-- analytics_ingest (ReplicatedReplacingMergeTree, so they replicate through
-- this database's Keeper log); the serving *_live views follow. No table DDL
-- ships in this image — the CDC tables are PeerDB's.
CREATE DATABASE IF NOT EXISTS analytics
    ENGINE = Replicated('/clickhouse/databases/analytics', '{shard}', '{replica}');
