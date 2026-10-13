# pg-stat-ch

[pg_stat_ch](https://github.com/ClickHouse/pg_stat_ch) packaged as a
CloudNativePG image-volume extension: PostgreSQL mounts it read-only at
`/extensions/pg_stat_ch` and loads `pg_stat_ch.so` through
`shared_preload_libraries`, the same way the CloudNativePG catalog ships
`pgaudit` and `timescaledb`.

| Quick facts | |
|---|---|
| Upstream | `ClickHouse/pg_stat_ch` v0.4.0 release tarballs (`pg18-linux-{amd64,arm64}`), checksum-pinned |
| Operand it is built against | `ghcr.io/cloudnative-pg/postgresql:18.6-system-trixie` (digest in the Dockerfile) |
| Layout | `/lib/pg_stat_ch.so`, `/share/extension/pg_stat_ch.control` + upgrade scripts |
| Runtime libraries | `libstdc++.so.6`, `libssl.so.3`, `libcrypto.so.3`, glibc ≥ 2.34 — all in the `system` operand, verified by `ldd` at build time |
| Consumer | homelab `product-db` and `platform-db` `Cluster` manifests (`spec.postgresql.extensions`) |

## What the build proves

The extraction stage runs inside the exact operand image, so `ldd` resolves the
extension against the libraries PostgreSQL will actually load. A missing or
mismatched library fails the build instead of the first pod start. The
`default_version` check pins the control file to the SQL scripts this release
ships.

## Changing it

- **New upstream release:** update `PG_STAT_CH_VERSION`, both `--checksum`
  values (`shasum -a 256` on the downloaded tarballs) and the
  `default_version` assertion; add a CHANGELOG entry; open a pull request. CI
  builds twice and must produce one digest.
- **New operand digest:** the consumer and this image must move together — the
  `.so` is only tested against the operand it was built with.
- The extension requires `shared_preload_libraries` and a PostgreSQL restart;
  rollout notes live in the homelab docs, not here.
