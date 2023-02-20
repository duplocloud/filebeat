# Filebeat
We use hints based autodiscover of filebeat to automatically discover the servicename and other labels. 
With recent change of filebaet config. We now support Tenant level and Service level logs  
Native Linux Docker image: **duplocloud/filebeat-oss:7.11.1-alpine-3.13.2-r2-tenantNServiceLevelLogs**  
For **Tenant level logs**: Add the env varibale `"TENANT_LEVEL_INDEX": "yes"`  
For the **Service level logs**: add the lables to the service.  
```
{
	"Labels": {
		"co.elastic.logs/enabled": "true",
		"co.elastic.logs/processors.1.add_fields.target": "",
		"co.elastic.logs/processors.1.add_fields.fields.serviceLevelIndex": "yes"
	}
}
```
