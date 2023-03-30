#!/bin/bash

echo "Starting thread to push the SavedObjects: Index Patterns"
./insertSavedObjects.sh & 

sed -ie "s/\"#ELASTICSEARCH_PASSWORD#\"/$(echo $ELASTICSEARCH_PASSWORD)/g" /usr/share/kibana/config/kibana.yml

echo "Starting Kibana"
/bin/tini -- /usr/local/bin/kibana-docker