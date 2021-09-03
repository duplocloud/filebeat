FROM duplocloud/kibana:7.14.0
COPY ./entrypoint.sh /usr/share/kibana
COPY ./insertSavedObjects.sh /usr/share/kibana
USER root
RUN chmod 777 /usr/share/kibana/entrypoint.sh /usr/share/kibana/insertSavedObjects.sh 
USER kibana
COPY ./SavedObjects /usr/share/kibana/SavedObjects
ENTRYPOINT [ "./entrypoint.sh" ]