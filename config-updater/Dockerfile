FROM ubuntu:20.04

# Enable the non-interactive mode while installing apps
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update > /dev/null \
    && apt-get -y install --no-install-recommends apt-utils software-properties-common > /dev/null 2>&1 \
    && apt-get -y install --no-install-recommends curl wget jq unzip > /dev/null 2>&1

ENV VPN_PROVIDER="NONE"
ENV DEBUG="false"

VOLUME /repo
ADD ./scripts /usr/local/scripts
ADD ./config /config

CMD ["bash", "/usr/local/scripts/update-config.sh"]
