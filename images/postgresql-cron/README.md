# PostgreSQL with pg_cron

Qualification candidate for homelab RFC-0030 / ADR-068; not released or deployed.
The exact CNPG 18.6 system base and PGDG 1.6.8-1.pgdg13+2 Debian package
payloads are pinned by SHA-256 for AMD64 and ARM64. Extracting only the extension
avoids replacing the base PostgreSQL binary or resolving floating apt dependencies.
Package control metadata is not registered in dpkg; the Dockerfile is the artifact inventory.

Build through `make digest IMAGE=postgresql-cron`. Reproducibility remains false
until two clean builds agree. Verify library dependencies, extension activation,
CNPG restore and promotion before release. Do not add shared_preload_libraries
on an existing cluster before the tested image is deployed on every instance.
The Compose image in homelab is a distinct entrypoint/base, not a CNPG runtime test.
