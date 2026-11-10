# pg-stat-ch changelog

## 0.2.0 — 2026-11-10

- pg_stat_ch v0.4.1. Fixes a double free when an interrupted dequeue is
  retried, clamps `batch_max` to `queue_capacity`, and decodes ZSTD responses
  from ClickHouse, so the writer no longer needs an LZ4-only profile. Adds the
  `pg_stat_ch.track_labels` GUC (sqlcommenter labels, off by default; needs a
  `labels` column in `events_raw` before it is turned on). The control file
  stays at `default_version = '0.4'`: no `ALTER EXTENSION` step.

## 0.1.0 — 2026-10-13

- First image: pg_stat_ch v0.4.0 for PostgreSQL 18 (amd64 + arm64) from the
  upstream release tarballs, laid out as a CloudNativePG image-volume extension
  and `ldd`-checked against `postgresql:18.6-system-trixie`.
