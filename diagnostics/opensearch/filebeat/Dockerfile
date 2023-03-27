ARG BASE_IMAGE=secureimages/filebeat-oss:7.11.1-alpine-3.13.2
FROM ${BASE_IMAGE}
COPY ./conf/filebeat.yml /usr/share/filebeat/filebeat.yml
USER root
RUN chmod go-w /usr/share/filebeat/filebeat.yml
USER filebeat