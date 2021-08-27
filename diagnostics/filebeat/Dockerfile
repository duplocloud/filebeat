FROM docker.elastic.co/beats/filebeat:7.14.0
COPY ./conf/filebeat.yml /usr/share/filebeat/filebeat.yml
USER root
RUN chown root:filebeat /usr/share/filebeat/filebeat.yml
USER filebeat