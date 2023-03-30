FROM duplocloud/filebeat-oss:7.11.1-r5
COPY ./conf/filebeat.yml /usr/share/filebeat/filebeat.yml
COPY ./filebeat-entrypoint.sh /filebeat-entrypoint.sh
USER root
RUN chmod +x /filebeat-entrypoint.sh
RUN chmod go-w /usr/share/filebeat/filebeat.yml
USER filebeat