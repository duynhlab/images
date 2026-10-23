# PostgreSQL with pg_cron

The CloudNativePG PostgreSQL 18.6 operand with pg_cron 1.6.8, used by homelab's
`product-db` for the RFC-0030 / ADR-068 CDC heartbeats (three 30-second
`cron.schedule_in_database` jobs owned by `analytics_heartbeat`).

The exact CNPG `18.6-system-trixie` base and the PGDG `1.6.8-1.pgdg13+2` Debian
package payloads are pinned by SHA-256 for AMD64 and ARM64. Only the extension
files are extracted, so the base PostgreSQL binaries and their dependencies are
never replaced or upgraded. Package control metadata is not registered in dpkg;
the Dockerfile is the artifact inventory.

The extract stage runs the `ldd` check against the operand's own libraries; the
final stage only copies files, so two builds produce the same digest.

## Changing it

- Bump the base digest together with the consumer's `imageName` (homelab
  `product-db` and `product-db-replica`) — the operand must match the running
  major/minor.
- `shared_preload_libraries` gains `pg_cron` only after this image runs on every
  instance; a cluster that preloads pg_cron on the stock image does not start.
- Verify on Kind before release: extension activation on all instances, a
  restore from backup with this image, `cnpg promote`, and a rollback to the
  previous image.
