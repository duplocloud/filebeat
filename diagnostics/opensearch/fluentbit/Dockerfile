# Single source of truth for the Fluent Bit version: drives both the base image tag and
# the agent.version reported by tenant_extract.lua. Bumping this one line is sufficient.
ARG FLUENTBIT_VERSION=5.0.6

FROM cr.fluentbit.io/fluent/fluent-bit:${FLUENTBIT_VERSION}

# Re-declared because a pre-FROM ARG is only in scope for the FROM instruction itself.
ARG FLUENTBIT_VERSION
ENV FLUENTBIT_VERSION=${FLUENTBIT_VERSION}

COPY ./diagnostics/opensearch/fluentbit/conf/fluent-bit.conf /fluent-bit/etc/fluent-bit.conf
COPY ./diagnostics/opensearch/fluentbit/conf/parsers.conf /fluent-bit/etc/parsers.conf
COPY ./diagnostics/opensearch/fluentbit/scripts/tenant_extract.lua /fluent-bit/scripts/tenant_extract.lua
