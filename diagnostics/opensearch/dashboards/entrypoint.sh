#!/bin/bash

echo "Starting thread to push the SavedObjects: Index Patterns"
./insertSavedObjects.sh & 

echo "Starting Dashboards"
./opensearch-dashboards-docker-entrypoint.sh