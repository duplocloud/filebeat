# Setting up the Centralized Logging
## Install Elasticsearch and Kibana
DuploCloud uses Elasticsearch for storing and Kibana for visualizing logs. Following are the steps to install Elasticsearch and Kibana using the DuploCloud **Service Description** feature.
1. Get the latest version of the Diagnostics Service Description `JSON` from the DuploCloud Team. 
2. Replace all the strings `<TO_BE_UPDATED>` with the appropriate AWS SCM certificate ARN.
3. If you want to deploy this Elasticsearch and Kibana in other than default tenant, set `Tenant` attribute as bellow in the Service Description JSON.  
    ``` json
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
9. Enable

## Enable Logging
DuploCloud uses **`filebeat`** for pushing logs of all the running containers in the tenant to the Elasticsearch. To enable logging for the Tenant, follow the steps as below.

1. Allow **filebeat** to communicate with **elasticsearch**. 

    1. Login to Duplocloud and navigate to  
        > Administrator --> Tenants
    2. Search for the tenant where elasticsearch is running and click on **Tenant Name**
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
    10. Select either `Enable Docker Container Logging` or `Enable Kubernetes Pods Logging` as container platform enabled for the tenant.
    11. Click on the <span style="color:blue">**Enable**</span> switch button. 
    12. Click on the <span style="color:blue">**Add**</span> button. 
    13. After few minutes, filebeat service will be created as Daemon Set which will run on all the hosts.

2. Set Reverse Proxy for the Kibana  

   To make Kibana accessible to all the DuploCloud Authenticated user, reverse proxy settings have to be configured. Follow the below steps to configure reverse proxy.


    1. Login to DuploCloud portal and navigate to  
        > `Administrator --> System Settings --> Reverse Proxy(Tab)`
    2. Click on the Add button and set the values as bellow
        - Proxy Path: `/kibana`
        - Backend Host Url: `https://<kibana_serivce_dns>`
        - Forwarding Prefix: `/proxy/kibana`
    3.  Click on the <span style="color:blue">**Update**</span> button. 
    4. To verify the logs getting pushed and availbale in Kibana, navigate to   

        > `Diagnostics --> Logging `

# Setting up the Auditor
Auditor functionality will alow user to persist and later view all the update operations executed by the user in DuploCloud consol. 

1. Create Elatesticsearch Index and Index Mappings

    ```
        export ES_ENDPOINT="https://es_endpoint"

        curl -XPUT "http://${ES_ENDPOINT}/tenant/"
        curl -XPUT "http://${ES_ENDPOINT}/auth/"
        curl -XPUT "http://${ES_ENDPOINT}/tenant/_mapping" -H 'Content-Type: application/json' -d'
        {
        "properties": {
            "timestamp": {
            "type": "date",
            "format": "M/d/y h:m:s a"
            }
        }
        }'

        curl -XPUT "http://${ES_ENDPOINT}/tenant/_mapping" -H 'Content-Type: application/json' -d'
        {
        "properties": {
            "timestamp": {
            "type": "date",
            "format": "M/d/y h:m:s a"
            }
        }
        }'
        ```
2. To enable Audit loggin for the infra, navigate to
 `Administrator --> Plans`
3. Search for the plan for which audtor has to be enabled and click on plan name.
4. Navigate to **Config** tab and click on <span style="color:blue">**Add**</span> button. 
5. Set the below values
    - Proxy Path: `/kibana`
    - Backend Host Url: `https://<kibana_serivce_dns>`
    - Forwarding Prefix: `/proxy/kibana`
6. Click on <span style="color:blue">**Submit**</span> button
        


        



        

