# pg_stat_ch as a CloudNativePG image-volume extension (PostgreSQL 18).
#
# The payload is the upstream release tarball, checksum-pinned per architecture
# (https://github.com/ClickHouse/pg_stat_ch/releases/tag/v0.4.2). The builder is
# the exact CNPG operand image the consumer runs, so the `ldd` check below proves
# the .so resolves against the operand's libstdc++/libssl/glibc before anything
# is published. Bump the operand digest here together with the consumer.
FROM ghcr.io/cloudnative-pg/postgresql:18.6-system-trixie@sha256:5efb66993894055f0aa50bd94337c6c4ff2e2129f4d433c527151aebbf283fb0 AS extract
USER root
ARG TARGETARCH
ARG PG_STAT_CH_VERSION=0.4.2
ADD --checksum=sha256:0579e19fe8afc32a31245ff0d3c191e0236683753a01011e8f8f3aff89b90483 https://github.com/ClickHouse/pg_stat_ch/releases/download/v${PG_STAT_CH_VERSION}/pg_stat_ch-v${PG_STAT_CH_VERSION}-pg18-linux-amd64.tar.gz /tmp/pg_stat_ch-amd64.tar.gz
ADD --checksum=sha256:31b021032729e23cadc86e5fcd22779a8a01b821efb9e40b934f2d0149462049 https://github.com/ClickHouse/pg_stat_ch/releases/download/v${PG_STAT_CH_VERSION}/pg_stat_ch-v${PG_STAT_CH_VERSION}-pg18-linux-arm64.tar.gz /tmp/pg_stat_ch-arm64.tar.gz
RUN set -eux; \
    mkdir -p /extension/lib /extension/share/extension; \
    tar -xzf /tmp/pg_stat_ch-${TARGETARCH}.tar.gz -C /tmp; \
    src=/tmp/pg_stat_ch-v${PG_STAT_CH_VERSION}-pg18-linux-${TARGETARCH}; \
    cp "${src}/pg_stat_ch.so" /extension/lib/; \
    cp "${src}/pg_stat_ch.control" "${src}"/pg_stat_ch--*.sql /extension/share/extension/; \
    ldd /extension/lib/pg_stat_ch.so > /tmp/ldd.txt; \
    ! grep -q "not found" /tmp/ldd.txt; \
    grep -q "default_version = '0.4'" /extension/share/extension/pg_stat_ch.control

# CNPG mounts the image at /extensions/pg_stat_ch and appends
# <mount>/lib to dynamic_library_path and <mount>/share to
# extension_control_path, so this layout needs no path overrides in the Cluster.
FROM scratch
COPY --from=extract /extension/lib/ /lib/
COPY --from=extract /extension/share/ /share/
USER 65532:65532
