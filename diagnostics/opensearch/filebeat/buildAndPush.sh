#!/bin/sh
revision=$1
echo $revision

docker buildx build --push --platform linux/arm64,linux/amd64 --tag duplocloud/filebeat-oss:7.11.1-${revision} .

docker buildx build --push --platform linux/arm64,linux/amd64 --tag duplocloud/filebeat-oss:7.11.1-${revision}-k8 --file Dockerfile-k8s .

docker buildx build --push --platform linux/arm64,linux/amd64 --tag duplocloud/filebeat-oss:7.11.1-${revision}-custom --file Dockerfile-custom .