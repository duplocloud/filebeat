# Use the official Logstash image as a base
FROM docker.elastic.co/logstash/logstash:8.16.1

# Install the OpenSearch output plugin and Azure Event Hub input plugin
RUN bin/logstash-plugin install logstash-output-opensearch && \
    bin/logstash-plugin install logstash-input-azure_event_hubs

COPY logstash.conf /usr/share/logstash/pipeline/logstash.conf