# Filebeat
We use hints based autodiscover of filebeat to automatically discover the servicename and other labels. 
With recent change of filebaet config. We now support Tenant level and Service level logs  
Native Linux Docker image: **duplocloud/filebeat-oss:7.11.1-alpine-3.13.2-r2-tenantNServiceLevelLogs**

K8S image: **duplocloud/filebeat-oss:7.11.1-alpine-3.13.2-r5-tenantNServiceLevelLogs-k8**

For **Tenant level logs**: Add the env varibale `"TENANT_LEVEL_INDEX": "yes"`  
For the **Service level logs**: add the lables to the service.  
```
{
	"Labels": {
		"co.elastic.logs/processors.1.add_fields.target": "",
		"co.elastic.logs/processors.1.add_fields.fields.serviceLevelIndex": "yes"
	}
}
```


We can also process the logs for each service seperately. Filebeat looks at container lables for native docker & pod annotations for the K8 and process the logs of those services.

**For K8**
```
PodAnnotations:
  co.elastic.logs/processors.1.copy_fields.fail_on_error: 'true'
  co.elastic.logs/processors.1.copy_fields.fields.0.from: message
  co.elastic.logs/processors.1.copy_fields.fields.0.to: _message
  co.elastic.logs/processors.1.copy_fields.ignore_missing: 'true'
  co.elastic.logs/processors.2.decode_json_fields.add_error_key: 'true'
  co.elastic.logs/processors.2.decode_json_fields.fields: message
  co.elastic.logs/processors.2.decode_json_fields.target: ''
  co.elastic.logs/processors.2.decode_json_fields.overwrite_keys: 'true'
  ```
  
**Native docker**
  ```
 {
	"Labels": {
		"co.elastic.logs/processors.1.decode_json_fields.add_error_key": "true",
		"co.elastic.logs/processors.1.decode_json_fields.fields": "message",
		"co.elastic.logs/processors.1.decode_json_fields.target": "",
		"co.elastic.logs/processors.1.decode_json_fields.overwrite_keys": "true"
	}
}
```

Refer to https://www.elastic.co/guide/en/beats/filebeat/current/configuration-autodiscover-hints.html
