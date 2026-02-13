FROM alpine:3.20

ARG FILEBEAT_VERSION=7.12.1
ARG TARGETARCH

ENV PATH=$PATH:/usr/share/filebeat

RUN apk add --no-cache bash su-exec libc6-compat curl &&\
    apk add --no-cache -t .build-deps ca-certificates gnupg openssl &&\
    set -ex &&\
    if [ "$TARGETARCH" = "amd64" ]; then ARCH="x86_64"; else ARCH="$TARGETARCH"; fi &&\
    wget -O /tmp/filebeat.tar.gz "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-oss-${FILEBEAT_VERSION}-linux-${ARCH}.tar.gz" &&\
    mkdir -p /usr/share/filebeat &&\
    tar -xzf /tmp/filebeat.tar.gz --strip-components=1 -C /usr/share/filebeat &&\
    mkdir -p /usr/share/filebeat/logs /usr/share/filebeat/data &&\
    adduser -DH -s /sbin/nologin filebeat &&\
    chown -R filebeat:filebeat /usr/share/filebeat &&\
    apk del --purge .build-deps &&\
    rm -rf /tmp/* /var/cache/apk/*

RUN apk update && apk upgrade && rm -rf /var/cache/apk/*

COPY ./diagnostics/opensearch/filebeat/conf/filebeat.yml /usr/share/filebeat/filebeat.yml
COPY ./diagnostics/opensearch/filebeat/filebeat-entrypoint.sh /filebeat-entrypoint.sh
RUN chmod +x /filebeat-entrypoint.sh
RUN chmod go-w /usr/share/filebeat/filebeat.yml

WORKDIR /usr/share/filebeat
ENTRYPOINT ["/filebeat-entrypoint.sh"]
CMD ["-e", "-c", "/usr/share/filebeat/filebeat.yml"]
USER filebeat
