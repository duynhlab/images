# clickhouse-ddl changelog

## 2.1.0 — 2026-10-23

- Add `06-analytics_database.sql`: the Replicated `analytics` database for the
  RFC-0030 commerce read model, applied to every replica. No table DDL — the
  CDC tables are created by PeerDB.

## 2.0.0 — 2026-10-16

- **Breaking:** the client's `application_name` is now stored and queried as
  `application_name` instead of upstream's `app`. In `events_raw`, `app`
  becomes an `EPHEMERAL` column (the extension still inserts it by name; it is
  never stored and cannot be selected) and `application_name` takes its value
  through `DEFAULT app`. `db_app_user_1m` (including its `ORDER BY`) and
  `errors_recent` name the column `application_name`, and their views read it.
  Verified on `clickhouse-server:26.9`: a named-column insert that includes
  `app` fills `application_name` in `events_raw` and in both rollups. Every
  query that reads `app` must change. Fresh-only, with no migration.

## 1.2.1 — 2026-10-15

- The three `pg_stat_ch` rollup views (`60`, `70`, `80`) are now created with
  `DEFINER = default SQL SECURITY DEFINER`. Without a SQL SECURITY clause,
  ClickHouse checks `SELECT` on `events_raw` against whoever inserts, and the
  extension's writer holds `INSERT` only, so every batch failed with
  `Not enough privileges … while pushing to view` and the rollups stayed empty.
  Found on the homelab Kind audit; the writer stays INSERT-only. Fresh-only as
  before: a live database gets `ALTER TABLE … MODIFY DEFINER = default SQL
  SECURITY DEFINER` on each view.

## 1.2.0 — 2026-10-13

- New Replicated database `pg_stat_ch` for the PostgreSQL query-telemetry
  extension of the same name (v0.4.0): `05-pg_stat_ch_database.sql` (per
  replica, like `00`), `50-pg_stat_ch_events_raw.sql` (upstream's 52-column
  `events_raw` on `ReplicatedMergeTree`, `ORDER BY (db_name, ts)`, 7 days hot →
  `cold`, 90 days total) and three TO-style rollups with their target tables:
  `60` `query_stats_5m` (p50/p95/p99 TDigest states per statement fingerprint),
  `70` `db_app_user_1m`, `80` `errors_recent` (30 days). Seven objects in the
  new database; `otel` is untouched. The homelab `clickhouse-schema` Job needs
  the matching file list and per-database verification.

## 1.1.0 — 2026-10-05

- `otel_logs` gains `idx_log_attr_kv`, a `keyValuePairs` text index on
  `LogAttributes` that answers `LogAttributes['k'] = 'v'` from one index. The
  existing `mapKeys`/`mapValues` pair cannot tell which key a value sat under.
  The DDL now needs ClickHouse **26.9+**, since 26.8 rejects the tokenizer.
  Fresh-only as before: a live table gets the index by hand (`ADD INDEX`, then
  `MATERIALIZE INDEX`; homelab's ClickHouse README has the procedure).

## 1.0.0 — 2026-10-01

- First release from `duynhlab/images`. The SQL is byte-identical to the last
  homelab build (`ghcr.io/duynhlab/homelab/clickhouse-ddl:sql-6589f616b41c`); the
  image gains the `org.opencontainers.image.source` label and index annotations,
  so its digest differs.
