# CNPG PostgreSQL 18.6 operand with pg_cron 1.6.8 for the RFC-0030 CDC heartbeats.
#
# The PGDG package payload is checksum-pinned per architecture; PostgreSQL itself
# is never upgraded. The extract stage is the exact operand image, so the `ldd`
# check proves pg_cron.so resolves against the operand's libraries before
# anything is published. The final stage only copies files, which keeps the
# build reproducible. Bump the operand digest here together with the consumer.
FROM ghcr.io/cloudnative-pg/postgresql:18.6-system-trixie@sha256:5efb66993894055f0aa50bd94337c6c4ff2e2129f4d433c527151aebbf283fb0 AS extract
USER root
ARG TARGETARCH
ADD --checksum=sha256:512826a6247ad098dae3df7544361de70bc219ccc4585943ca7ad90a4bf68109 https://apt.postgresql.org/pub/repos/apt/pool/main/p/pg-cron/postgresql-18-cron_1.6.8-1.pgdg13+2_amd64.deb /tmp/cron-amd64.deb
ADD --checksum=sha256:fc12361081929e415f08f9c83556f296c8f732872e50be9687bd63d966c7f11a https://apt.postgresql.org/pub/repos/apt/pool/main/p/pg-cron/postgresql-18-cron_1.6.8-1.pgdg13+2_arm64.deb /tmp/cron-arm64.deb
RUN set -eux; \
    dpkg-deb --extract /tmp/cron-${TARGETARCH}.deb /extension; \
    test -f /extension/usr/share/postgresql/18/extension/pg_cron.control; \
    grep -q "default_version = '1.6'" /extension/usr/share/postgresql/18/extension/pg_cron.control; \
    ldd /extension/usr/lib/postgresql/18/lib/pg_cron.so > /tmp/ldd.txt; \
    ! grep -q "not found" /tmp/ldd.txt

FROM ghcr.io/cloudnative-pg/postgresql:18.6-system-trixie@sha256:5efb66993894055f0aa50bd94337c6c4ff2e2129f4d433c527151aebbf283fb0
COPY --from=extract /extension/usr/lib/postgresql/18/lib/pg_cron.so /usr/lib/postgresql/18/lib/pg_cron.so
COPY --from=extract /extension/usr/share/postgresql/18/extension/ /usr/share/postgresql/18/extension/
USER 26
