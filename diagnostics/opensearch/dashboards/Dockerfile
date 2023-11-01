FROM opensearchproject/opensearch-dashboards:2.11.0
COPY ./entrypoint.sh /usr/share/opensearch-dashboards
COPY ./insertSavedObjects.sh /usr/share/opensearch-dashboards
USER root
RUN chmod 777 /usr/share/opensearch-dashboards/entrypoint.sh /usr/share/opensearch-dashboards/insertSavedObjects.sh 
USER opensearch-dashboards
COPY ./SavedObjects /usr/share/opensearch-dashboards/SavedObjects
ENTRYPOINT [ "./entrypoint.sh" ]
