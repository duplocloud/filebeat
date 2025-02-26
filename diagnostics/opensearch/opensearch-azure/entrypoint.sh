#!/bin/bash
set -e

# Run the keystore script to set up Azure credentials
/usr/share/opensearch/create-keystore.sh

# Start OpenSearch with the original entrypoint
exec /usr/share/opensearch/opensearch-docker-entrypoint.sh "$@"
