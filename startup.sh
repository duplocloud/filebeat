#! /bin/bash
sed -i 's/<HOSTS>/'$HOSTS'/' /opt/filebeat-5.4.3-linux-x86_64/filebeat.yml
/bin/tini -- /bin/executor.sh

