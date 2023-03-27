#!/bin/sh
revision=$1
echo $revision
baseImage="duplocloud/filebeat-oss:7.11.1-${revision}"
echo "Build Docker native filebeat images. Base: ${baseImage}"
# AMD64
echo "Build amd image"
docker buildx build --push -t "${baseImage}-amd64" .


echo "Build arm image"
docker buildx build --push -t "${baseImage}-arm64" --platform linux/arm64 --build-arg BASE_IMAGE=duplocloud/filebeat-oss:7.11.1-alpine-3.13.2-arm-r1  .

docker manifest create \
"${baseImage}"  \
--amend "${baseImage}-arm64" \
--amend "${baseImage}-amd64"   
docker manifest push "${baseImage}"


baseImage="duplocloud/filebeat-oss:7.11.1-${revision}-k8s"
echo "Build Docker native filebeat images"
# AMD64
echo "Build amd image"
docker buildx build --push -t "${baseImage}-amd64" -f Dockerfile.k8s .


echo "Build arm image"
docker buildx build --push -t "${baseImage}-arm64" -f Dockerfile.k8s --platform linux/arm64 --build-arg BASE_IMAGE=duplocloud/filebeat-oss:7.11.1-alpine-3.13.2-arm-r1  .

docker manifest create \
"${baseImage}"  \
--amend "${baseImage}-arm64" \
--amend "${baseImage}-amd64"   
docker manifest push "${baseImage}"