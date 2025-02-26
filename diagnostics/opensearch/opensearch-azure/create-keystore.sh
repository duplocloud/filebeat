#!/bin/bash
set -e

# Create a new keystore
/usr/share/opensearch/bin/opensearch-keystore create

# Add Azure storage account credentials to the keystore
if [ ! -z "$AZURE_STORAGE_ACCOUNT" ]; then
  echo "$AZURE_STORAGE_ACCOUNT" | /usr/share/opensearch/bin/opensearch-keystore add --stdin azure.client.default.account
  echo "Added Azure storage account to keystore"
fi

if [ ! -z "$AZURE_STORAGE_KEY" ]; then
  echo "$AZURE_STORAGE_KEY" | /usr/share/opensearch/bin/opensearch-keystore add --stdin azure.client.default.key
  echo "Added Azure storage key to keystore"
fi
