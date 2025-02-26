# OpenSearch with Azure Snapshot Support

This document provides instructions for setting up and using OpenSearch with Azure Snapshot support, allowing you to back up your indexes to Azure Storage.

## Deployment Configuration

### Service Configuration

Use the following configuration to update the OpenSearch service with Azure Snapshot support:

| Configuration | Value |
|---------------|-------|
| Service Name | system-svc-es-oc |
| Docker Image | duplocloud/opensearch:2.11.0-azure |
| Replicas | 1 |
| Docker Networks | Host Network |
| Volumes | /data/es:/usr/share/opensearch/data |
| Other Docker Config | {"Labels":{"co.elastic.logs/enabled":"false"}} |

### Environment Variables

The service requires the following environment variables:

```json
{
  "discovery.type": "single-node",
  "plugins.security.disabled": "true",
  "compatibility.override_main_response_version": "true",
  "AZURE_STORAGE_ACCOUNT": "your-storage-account-name",
  "AZURE_STORAGE_KEY": "your-storage-account-key"
}
```

Replace `your-storage-account-name` and `your-storage-account-key` with your Azure Storage account credentials.

## Setting up Azure Storage

1. Create an Azure Storage account in your Azure portal
2. Create a container in the storage account (e.g., "opensearch-snapshots")
3. Note the storage account name and access key for the environment variables

## Creating a Snapshot Repository

Once your OpenSearch instance is running with the above configuration, you can create a snapshot repository:

1. Access the OpenSearch Dashboard
2. Navigate to Dev Tools
3. Run the following command:

```json
PUT _snapshot/azure_backup
{
  "type": "azure",
  "settings": {
    "container": "opensearch-snapshots",
    "base_path": "snapshots",
    "client": "default"
  }
}
```

## Managing Snapshots

### Creating a Snapshot

To create a snapshot of all indices:

```json
PUT _snapshot/azure_backup/snapshot_1
```

You can also create a snapshot of specific indices:

```json
PUT _snapshot/azure_backup/snapshot_1
{
  "indices": "index1,index2",
  "ignore_unavailable": true,
  "include_global_state": false
}
```

### Viewing Snapshots

To view all snapshots in the repository:

```json
GET _snapshot/azure_backup/_all
```

To check the status of a specific snapshot:

```json
GET _snapshot/azure_backup/snapshot_1
```

### Restoring a Snapshot

To restore a specific snapshot:

```json
POST _snapshot/azure_backup/snapshot_1/_restore
{
  "indices": "index1,index2",
  "include_global_state": true
}
```

## Troubleshooting

If you encounter issues:

1. Verify your Azure Storage credentials are correct
2. Ensure the container exists in your Azure Storage account
3. Check OpenSearch logs for any error messages
4. Verify the Azure Storage account is accessible from your deployment environment
