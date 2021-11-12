FROM duplocloud/elasticsearch:7.14.0
COPY ./es/config/elasticsearch.yml /usr/share/elasticsearch/config/elasticsearch.yml
COPY ./tls/elasticsearch/elasticsearch.p12 /usr/share/elasticsearch/config/elasticsearch.p12
COPY ./tls/elasticsearch/http.p12 /usr/share/elasticsearch/config/http.p12
RUN echo "y" |  bin/elasticsearch-plugin install repository-s3
