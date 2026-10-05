# clickhouse-ddl changelog

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
