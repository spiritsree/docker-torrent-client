FROM ubuntu:20.04

ADD ./scripts /usr/local/scripts

# Enable the non-interactive mode while installing apps
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update > /dev/null \
    && apt-get -y install --no-install-recommends apt-utils software-properties-common > /dev/null 2>&1 \
    && apt-get -y install --no-install-recommends wget jq > /dev/null 2>&1

ENV VPN_PROVIDER="NONE"

VOLUME /config

CMD ["bash", "/usr/local/scripts/update-config.sh"]
