FROM duplocloud/filebeat-oss:7.11.1-r5
COPY ./diagnostics/opensearch/filebeat/conf/filebeat.yml /usr/share/filebeat/filebeat.yml
COPY ./diagnostics/opensearch/filebeat/filebeat-entrypoint.sh /filebeat-entrypoint.sh
USER root
RUN chmod +x /filebeat-entrypoint.sh
RUN chmod go-w /usr/share/filebeat/filebeat.yml
USER filebeat