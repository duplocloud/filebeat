FROM docker.elastic.co/kibana/kibana:8.5.3
COPY ./kibana/entrypoint.sh /usr/share/kibana
COPY ./kibana/insertSavedObjects.sh /usr/share/kibana
COPY ./kibana/config/kibana.yml /usr/share/kibana/config/kibana.yml
COPY ./tls/kibana/elasticsearch-ca.pem /usr/share/kibana/config/elasticsearch-ca.pem
USER root
RUN chmod 777 /usr/share/kibana/entrypoint.sh /usr/share/kibana/insertSavedObjects.sh 
USER kibana
COPY ./kibana/SavedObjects /usr/share/kibana/SavedObjects
ENTRYPOINT [ "./entrypoint.sh" ]