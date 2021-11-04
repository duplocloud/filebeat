# Setting up the Diagnostics
## Install Elasticsearch and Kibana
DuploCloud uses Elasticsearch for storing and Kibana for visualizing logs. Following are the steps to install Elasticsearch and Kibana using the DuploCloud **Service Description** feature.
1. Download the latest version of the Diagnostics Service Description `JSON` from [Here](sd.json)
2. Replace all the strings `<TO_BE_UPDATED>` with the appropriate AWS SCM certificate ARN.
3. If you want to deploy this Elasticsearch and Kibana in other than default tenant, set the  `Tenant` attribute as bellow in the Service Description JSON.  
    ```js
    {
            "Name"      : "DiagnosticsV3",
            "Tenant"    : "<Name_of tenant>"  
    }
    ```  

4. Login to DuploCloud console and navigate to  
     > `Administrator --> System Settings --> Service Descriptions(Tab)`
4. Click on the <span style="color:blue">**Add**</span> button.
5. Paste the above-modified JSON in the input field as shown in the below image.
6. Click on <span style="color:blue">**Update**</span> button.
7. After few minutes, two services will be created in the selected tenant with names **system-svc-es** and **system-svc-kibana**.
8. Wait for services to be <span style="color:green">Running</span> and  <span style="color:green">Healthy</span>.

## Install Grafana, Prometheus and YACE
DuploCloud uses Prometheus for storing time-series data for node, container, and cloud watch metrics. YACE is used to seeding AWS cloudwatch metrics to the Prometheus. Grafana is used for visualizing these metrics. 
1. Download the latest version of the monitoring Service Description `JSON` from [Here](https://github.com/duplocloud/grafana-dashboard-docker/blob/master/settings/service_descriptions/monitoring-svd.json)
2. Replace all the strings `<TO_BE_UPDATED>` with the appropriate value as below.
    1. GRAFANA_DOMAIN --> CUSTOMER_ENV_NAME.duplocloud.net
    2. ADMIN_PASSWORD --> Generate a new random password
    3. CertificateArn --> This should customer DNS suffix domains certificate we created and added to the plan

4. Login to DuploCloud console and navigate to  
     > `Administrator --> System Settings --> Service Descriptions(Tab)`
4. Click on the <span style="color:blue">**Add**</span> button.
5. Paste the above-modified JSON in the input field as shown in the below image.
6. Click on <span style="color:blue">**Update**</span> button.
7. After few minutes, three services will be created in the `default` tenant with names as **system-svc-Prometheus**, **system-svc-grafana**, and **system-svc-yace**.
8. Wait for services to be <span style="color:green">Running</span> and  <span style="color:green">Healthy</span>.
9. Add following inline policy **duploservices-default** role 
    ```js
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "tag:GetResources",
            "cloudwatch:ListTagsForResource",
            "cloudwatch:GetMetricData",
            "cloudwatch:ListMetrics",
            "cloudwatch:GetMetricStatistics"
          ],
          "Resource": "*",
          "Condition": {}
        }
      ]
    }
    ```

## Add PlatformServices
This step is required so that users can enable Logging, monitoring, and metrics for different tenants

1. Download the latest version of platform services `JSON` from [Here](https://github.com/duplocloud/grafana-dashboard-docker/blob/master/settings/PlatformServices.json)
2. Replace all the strings `<TO_BE_UPDATED>` with the appropriate value as below.
    1. DUPLO_AUTH_URL --> https://CUSTOMER_ENV_NAME.duplocloud.net
    

4. Login to DuploCloud console and navigate to  
     > `Administrator --> System Settings --> Platform Services(Tab)`
4. Click on the <span style="color:blue">**Edit Platform Services**</span> button.
5. Paste the above-modified JSON in the input field as shown in the below image.
6. Click on <span style="color:blue">**Update**</span> button.


## Enable monitoring
1. **Add Iframe Configs**
    1. Download the latest version of Ifraem configs `JSON` from [Here](https://github.com/duplocloud/grafana-dashboard-docker/blob/master/settings/IframeConfigs.json)
    2. Login to DuploCloud console and navigate to  
     > `Administrator --> System Settings --> Iframe Configs(Tab)`
    3. Click on the <span style="color:blue">**Edit Iframe Configs**</span> button.
    5. Paste the content of downloaded JSON in the input field as shown in the below image.
    6. Click on <span style="color:blue">**Update**</span> button.
2. **Set Reverse Proxy for the grafana** 
    1. Login to DuploCloud portal and navigate to  
        > `Administrator --> System Settings --> Reverse Proxy(Tab)`
    2. Click on the Add button and set the values as bellow
        - Proxy Path: `/grafanaproxy`
        - Backend Host Url: `https://system-svc-grafana-default.<base_domain_name>`
    3.  Click on the <span style="color:blue">**Update**</span> button. 
    4. Verify if you can visit the `https://<duplo_portal>/proxy/grafanaproxy`
3. **Enable Security Rules**
    Security rules needs to be enabled so that Prometheus can reach to nodes running in the tenant to collect the host and container metrics
    1. Login to DuploCloud console and navigate to `Administrator --> Infrastructure`
    2. Select the infrastructure where you want to enable monetoring and go to `Security Group Rules` tab
    3. Click on <span style="color:blue">**Add**</span> button.  
    4. Set the values as below  
        1. Source Type: Tenant
        2. Tenant: 'default'
        3. Protocol: http
        4. Port Range: 30880-30880
        5. Description: Allow default tenant to talk with cadvisor
    6. Click on <span style="color:blue">**Add**</span> button and wait for successfull message
    7. Repeat above steps for Node collecter with values as below.
        1. Source Type: Tenant
        2. Tenant: 'default'
        3. Protocol: http
        4. Port Range: 9100-9100
        5. Description: Allow default tenant to talk with node-collector
4. **Enable monitoring for tenants**
    1. Navigate to `Administrator --> Tenants`
    2. Search for the tenant for which you want to enable monitoring and click on the **Tenant Name**
    3. Go to **Settings** tab and click on the <span style="color:blue">**Add**</span> button.
    4. Select either `Enable Node Monitoring` or `Enable k8s Node Monitoring` as per container platform enabled for the Infa.
    5. Click on the <span style="color:blue">**Enable**</span> switch button. 
    6. Click on the <span style="color:blue">**Add**</span> button. 
    7. After few minutes, `node-exporter` service will be created which will run on all the hosts.
    8. Repeat aboe steps for `Enable Docker Monitoring` or `Enable k8s docker monitoring` as per container platform enabled for the Infra.


## Enable Logging
DuploCloud uses **`filebeat`** for pushing logs generated by all the running containers in the tenant to the Elasticsearch. To enable logging for the Tenant, follow the steps below.

1. Allow **filebeat** to communicate with **elasticsearch**. 

    1. Login to Duplocloud and navigate to  
        > Administrator --> Tenants
    2. Search for the tenant where Elasticsearch is running and click on **Tenant Name**
    3. Go to **Security** tab and click on <span style="color:blue">**Add**</span> button.
    4. Allow communication for the port range as `443-443` either from the specific tenant or the CIDR range for all the tenants.

2. Enable Logging for the Tenant.
    1. Get the latest Platform Services `JSON` for the filebeat from the DuploCloud team as per the container platform which can be either `Docker Native` or `Kubernetes`
    2. Replace the `<TO_BE_UPDATED_BASE_DOMAIN>` string with the base domain.
    3. Login to DuploCloud portal and navigate to  
        > `Administrator --> System Settings --> Platform Services(Tab)`
    4. Click on <span style="color:blue">**Edit Platform Services**</span> button.
    5. Add the above-modified JSON block to the existing list of platform services.
    6.  Click on <span style="color:blue">**Update**</span> button.
    7. Navigate to `Administrator --> Tenants`
    8. Search for the tenant for which you want to enable logging and click on the **Tenant Name**
    9. Go to **Settings** tab and click on the <span style="color:blue">**Add**</span> button.
    10. Select either `Enable Docker Container Logging` or `Enable Kubernetes Pods Logging` as per container platform enabled for the Infra.
    11. Click on the <span style="color:blue">**Enable**</span> switch button. 
    12. Click on the <span style="color:blue">**Add**</span> button. 
    13. After few minutes, a filebeat service will be created which will run on all the hosts.

2. Set Reverse Proxy for the Kibana  

   To make Kibana accessible to all the DuploCloud Authenticated users, reverse proxy settings have to be configured. Follow the below steps to configure reverse proxy.


    1. Login to DuploCloud portal and navigate to  
        > `Administrator --> System Settings --> Reverse Proxy(Tab)`
    2. Click on the Add button and set the values as bellow
        - Proxy Path: `/kibana`
        - Backend Host Url: `https://<kibana_serivce_dns>`
        - Forwarding Prefix: `/proxy/kibana`
    3.  Click on the <span style="color:blue">**Update**</span> button. 
4.  Set Elasticsearch URL on the Plans
    1. To enable Audit logs for the infra, navigate to
 `Administrator --> Plans`
    2. Search for the plan for which Audit logs has to be enabled and click on plan name.
    3. Navigate to **Config** tab and click on <span style="color:blue">**Add**</span> button. 
    4. Set the below values
        - Config Type: `dashboard_url`
        - Name: `AuditAndLoggerKibanaEndpoint`
        - Value: `/proxy/kibana`
     5. Click on <span style="color:blue">**Submit**</span> button
6. Verify if logging is configured correctly
    1. Login to DuploCloud console and navigate to `Diagnostics --> Logging `
    2. Select service using services dropdown.
    3. Verify if logs are present for the service 

# Setting up the Auditor
Auditor functionality will allow a user to persist and later view all the update operations executed by the user in the DuploCloud console. Follow the below steps to enable Auditor.

1. Create Elatesticsearch Index and Index Mappings

    ```console
        export ES_ENDPOINT="https://system-svc-es-default.<base_domain_name>"

        curl -XPUT "${ES_ENDPOINT}/tenant/"
        curl -XPUT "${ES_ENDPOINT}/auth/"
        curl -XPUT "${ES_ENDPOINT}/auth/_mapping" -H 'Content-Type: application/json' -d'
        {
        "properties": {
            "timestamp": {
            "type": "date",
            "format": "M/d/y h:m:s a"
            }
        }
        }'

        curl -XPUT "${ES_ENDPOINT}/tenant/_mapping" -H 'Content-Type: application/json' -d'
        {
        "properties": {
            "timestamp": {
            "type": "date",
            "format": "M/d/y h:m:s a"
            }
        }
        }'
    ```
2. To enable Audit logs for the infra, navigate to
 `Administrator --> Plans`
3. Search for the plan for which Audit logs has to be enabled and click on plan name.
4. Navigate to **Config** tab and click on <span style="color:blue">**Add**</span> button. 
5. Set the below values
    - Config Type: `dashboard_url`
    - Name: `AuditESEndpoint`
    - Value: `https://es_endpoint/`
6. Click on <span style="color:blue">**Submit**</span> button
        

        



        

