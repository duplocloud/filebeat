# Filebeat
We use hints based autodiscover of filebeat to automatically discover the servicename and other labels. 
With recent change of filebaet config. We now support Tenant level and Service level logs. Also these images are multi arch images can also be used with graviton instances.
Native Linux Docker image: **duplocloud/filebeat-oss:7.11.1-00895c38db61c343a16ff9c02295dc096eb82db6**

K8S image: **duplocloud/filebeat-oss:7.11.1-00895c38db61c343a16ff9c02295dc096eb82db6-k8s**

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
