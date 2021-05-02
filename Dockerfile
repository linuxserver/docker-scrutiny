FROM ghcr.io/linuxserver/baseimage-alpine:3.12

# set version label
ARG BUILD_DATE
ARG VERSION
ARG SCRUTINY_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="alex-phillips"

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache \
    smartmontools && \
 apk add --no-cache --virtual=build-dependencies \
    curl \
    gcc \
    go \
    musl-dev \
    nodejs \
    npm && \
 echo "**** install scrutiny ****" && \
 if [ -z ${SCRUTINY_RELEASE+x} ]; then \
    SCRUTINY_RELEASE=$(curl -sX GET https://api.github.com/repos/AnalogJ/scrutiny/commits/master \
    | awk '/sha/{print $4;exit}' FS='[""]'); \
 fi && \
 curl -o \
    /tmp/scrutiny.tar.gz -L \
    "https://github.com/AnalogJ/scrutiny/archive/${SCRUTINY_RELEASE}.tar.gz" && \
 mkdir -p \
    /app/scrutiny && \
 tar xf \
    /tmp/scrutiny.tar.gz -C \
    /app/scrutiny --strip-components=1 && \
 echo "**** building scrutiny ****" && \
 cd /app/scrutiny && \
 go mod vendor && \
 go build -ldflags '-w -extldflags "-static"' -o scrutiny webapp/backend/cmd/scrutiny/scrutiny.go && \
 go build -ldflags '-w -extldflags "-static"' -o scrutiny-collector-selftest collector/cmd/collector-selftest/collector-selftest.go && \
 go build -ldflags '-w -extldflags "-static"' -o scrutiny-collector-metrics collector/cmd/collector-metrics/collector-metrics.go && \
 mv /app/scrutiny/scrutiny /usr/local/bin/ && \
 mv /app/scrutiny/scrutiny-collector-selftest /usr/local/bin/ && \
 mv /app/scrutiny/scrutiny-collector-metrics /usr/local/bin/ && \
 chmod +x /usr/local/bin/scrutiny* && \
 echo "**** build scrutiny frontend ****" && \
 cd /app/scrutiny/webapp/frontend && \
 mkdir -p /app/scrutiny-web && \
 npm install && \
 npx ng build --output-path=/app/scrutiny-web --deploy-url="/web/" --base-href="/web/" --prod && \
 echo "**** cleanup ****" && \
 cd /app && \
 rm -rf /app/scrutiny && \
 apk del --purge \
    build-dependencies && \
 rm -rf \
    /root/.cache \
    /tmp/* \
    /root/go \
    /root/.npm && \
 echo "**** network fixes ****" && \
 printf "hosts: files dns" > /etc/nsswitch.conf

# copy local files
COPY root/ /
