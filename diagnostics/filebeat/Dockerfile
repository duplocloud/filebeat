ARG BASE_IMAGE=docker.elastic.co/beats/filebeat:7.14.0
FROM ${BASE_IMAGE}
COPY ./conf/filebeat.yml /usr/share/filebeat/filebeat.yml
USER root
RUN chmod go-w /usr/share/filebeat/filebeat.yml
USER filebeat