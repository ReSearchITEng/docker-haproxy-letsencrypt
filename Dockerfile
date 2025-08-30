FROM debian:trixie
#FROM debian:bookworm
#MAINTAINER bringnow team <wecare@bringnow.com> # researchiteng

ARG DEBIAN_VERSION=trixie
ARG DEBIAN_FRONTEND=noninteractive
#ARG ACME_PLUGIN_VERSION=0.1.1
ARG HAPROXY_VERSION=3.2

#&& curl -sSL https://github.com/janeczku/haproxy-acme-validation-plugin/archive/${ACME_PLUGIN_VERSION}.tar.gz -o acme-plugin.tar.gz \ # aug 2025
RUN buildDeps='curl ca-certificates' runtimeDeps='inotify-tools lua-sec rsyslog' \
        && apt-get update && apt-get upgrade -y && apt-get install -y $buildDeps $runtimeDeps --no-install-recommends \
        && curl https://haproxy.debian.net/haproxy-archive-keyring.gpg --create-dirs --output /etc/apt/keyrings/haproxy-archive-keyring.gpg \
        && echo "deb [signed-by=/etc/apt/keyrings/haproxy-archive-keyring.gpg] https://haproxy.debian.net ${DEBIAN_VERSION}-backports-${HAPROXY_VERSION} main" > /etc/apt/sources.list.d/haproxy.list \
        && apt-get update && apt-get upgrade -y && apt-get install -y haproxy=${HAPROXY_VERSION}.* \
        && curl -sSL https://github.com/APSL/haproxy-acme-validation-plugin/archive/refs/heads/master.tar.gz -o acme-plugin.tar.gz \
	&& tar -C /etc/haproxy/ -xf acme-plugin.tar.gz --strip-components=1 --no-anchored acme-http01-webroot.lua \
	&& rm *.tar.gz \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& rm -rf /var/lib/apt/lists/*

EXPOSE 80 443

COPY entrypoint.sh /

VOLUME /etc/letsencrypt
VOLUME /var/acme-webroot

ENTRYPOINT ["/entrypoint.sh"]
