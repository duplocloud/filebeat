FROM linuxspace/filebeat:latest

ENV FILEBEAT_VERSION 5.4.3

ENV FILEBEAT_HOME /opt/filebeat-5.4.3-linux-x86_64
ADD filebeat.yml ${FILEBEAT_HOME}/
ADD startup.sh /startup.sh
RUN chmod +x /startup.sh
ENTRYPOINT ["/bin/bash", "-c", "/startup.sh"]
