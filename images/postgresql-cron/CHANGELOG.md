# Changelog

## 1.0.0

- CNPG PostgreSQL 18.6 (`18.6-system-trixie@sha256:5efb6699…`) with PGDG pg_cron
  1.6.8 (`1.6.8-1.pgdg13+2`), AMD64 and ARM64. The `ldd` check moved into the
  extract stage, so the final stage only copies files and the build is
  reproducible.
