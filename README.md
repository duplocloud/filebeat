# filebeat
Filebeat that takes ES as a env variable. Will ship any logs that are in the container's /logs folder to ES. Mount the desired folder from the host, from where logs are to be collected, to container folder /logs . See example usage below

Example usage:
docker run -d --env HOSTS="'10.102.1.5:9200'" -v /var/log:/logs duplocloud/anyservice:filebeat_v2

