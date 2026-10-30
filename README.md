# images — platform-built OCI images for duynhlab

This repository builds reproducible OCI images for platform config and tooling. Each image is versioned independently and released from its own tag line.

## Images

| Image | Purpose |
|---|---|
| [`clickhouse-ddl`](images/clickhouse-ddl/) | ClickHouse schema image for observability datasets and helper SQL objects. |
| [`pg-stat-ch`](images/pg-stat-ch/) | PostgreSQL extension image for `pg_stat_ch`. |
| [`postgresql-cron`](images/postgresql-cron/) | PostgreSQL operand image with `pg_cron` for operational jobs. |

## Common workflow

1. Add a new image under `images/<image>/` with `image.yaml`, `Dockerfile`, `README.md`, and `CHANGELOG.md`.
2. Validate it with `make lint` and `make digest IMAGE=<image>`.
3. Release from `main` using the tag pattern `<image>/vX.Y.Z`; the workflow signs and attests the image before publishing the GitHub Release.

## Verify an image

```bash
cosign verify \
  --certificate-identity-regexp '^https://github\.com/duynhlab/images/\.github/workflows/release\.yml@refs/tags/<image>/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/duynhlab/images/<image>@sha256:<digest>
```
