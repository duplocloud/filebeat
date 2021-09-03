FROM duplocloud/kibana:7.14.0
COPY ./entrypoint.sh /usr/share/kibana
COPY ./insertSavedObjects.sh /usr/share/kibana
COPY ./SavedObjects /usr/share/kibana
ENTRYPOINT [ "bash" "./entrypoint.sh" ]