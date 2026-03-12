FROM cr.fluentbit.io/fluent/fluent-bit:4.2.3

COPY ./diagnostics/opensearch/fluentbit/conf/fluent-bit.conf /fluent-bit/etc/fluent-bit.conf
COPY ./diagnostics/opensearch/fluentbit/conf/parsers.conf /fluent-bit/etc/parsers.conf
COPY ./diagnostics/opensearch/fluentbit/scripts/tenant_extract.lua /fluent-bit/scripts/tenant_extract.lua
