1. One time setup
docker run -d docker.elastic.co/beats/metricbeat-oss:7.1.1 setup -E setup.kibana.host=vpc-duploservices-tools-metric-3oumeg5h2njqccvbu3pge34b6y.us-west-2.es.amazonaws.com:443/_plugin/kibana -E setup.kibana.protocol="https"  -E output.elasticsearch.hosts=["vpc-duploservices-tools-metric-3oumeg5h2njqccvbu3pge34b6y.us-west-2.es.amazonaws.com:443"] -E output.elasticsearch.protocol="https" -E setup.ilm.enabled=false

2. To deploy in Duplo
- Image: duplocloud/anyservice:metricbeat-oss_7.1.1_v1
- VolumeMapping "/proc:/hostfs/proc:ro","/sys/fs/cgroup:/hostfs/sys/fs/cgroup:ro", "/:/hostfs:ro"
- Other dockerconfig {"Cmd":[
                "-e",
                "-system.hostfs=/hostfs",
		"-E",
                "output.elasticsearch.hosts=[vpc-duploservices-tools-metric-3oumeg5h2njqccvbu3pge34b6y.us-west-2.es.amazonaws.com:443]",
                "-E",
                "output.elasticsearch.protocol=https",
                "-E",
                "setup.ilm.enabled=false"
            ]}

- HostNetwork
