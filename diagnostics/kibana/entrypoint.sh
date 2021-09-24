#!/bin/bash

echo "Starting thread to push the SavedObjects: Index Patterns"
./insertSavedObjects.sh & 

echo "Starting Kibana"
/bin/tini -- /usr/local/bin/kibana-docker