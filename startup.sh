#! /bin/bash
cat /opt/filebeat-5.4.3-linux-x86_64/filebeat.yml
sed -i 's/<HOSTNAME>/'$HOSTNAME'/' /opt/filebeat-5.4.3-linux-x86_64/filebeat.yml
sed -i 's/<HOSTS>/'$HOSTS'/' /opt/filebeat-5.4.3-linux-x86_64/filebeat.yml
cat /opt/filebeat-5.4.3-linux-x86_64/filebeat.yml
/bin/tini -- /bin/executor.sh

