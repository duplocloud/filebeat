#!/bin/bash

echo "Starting thread to push the SavedObjects: Index Patterns"
./isertSavedObjects.sh & 

echo "Starting Kibana"
/bin/tini -- /usr/local/bin/kibana-docker