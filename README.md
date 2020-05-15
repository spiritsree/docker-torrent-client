# Docker Torrent Client

[![CircleCI](https://circleci.com/gh/spiritsree/docker-torrent-client.svg?style=svg&circle-token=6909ce52d267d42d26f552de73de7aa2768fb6d4)](https://app.circleci.com/pipelines/github/spiritsree/docker-torrent-client)
[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/spiritsree/docker-torrent-client)](https://hub.docker.com/r/spiritsree/docker-torrent-client)
[![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/spiritsree/docker-torrent-client)](https://hub.docker.com/r/spiritsree/docker-torrent-client)
[![Docker Pulls](https://img.shields.io/docker/pulls/spiritsree/docker-torrent-client)](https://hub.docker.com/r/spiritsree/docker-torrent-client)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/spiritsree/docker-torrent-client?sort=semver)](https://hub.docker.com/r/spiritsree/docker-torrent-client/tags)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/spiritsree/docker-torrent-client/blob/master/LICENSE.md)


Docker torrent client with VPN

## Contents

1. [Requirements](#requirements)
1. [Quick Start](#quick-start)
1. [Accessing the UI](#accessing-the-ui)
1. [Documentation](#documentation)
1. [Reference](#reference)

## Requirements

If you are building this locally you need these tools.

* [jq](https://stedolan.github.io/jq/)
* [docker](https://www.docker.com/)

## Quick start

For local build checkout this git repo and run the below command.

```
$ ./setup.sh -h
docker-torrent-client setup

Usage:
    setup.sh M_ARGS [O_ARGS]

Mandatory Arguments (M_ARGS):
    -v|--vpn-provider <vpn-provider>           VPN Provider (e.g: HideMe)

Optional Arguments (O_ARGS):
    -h|--help                                  Print usage
    -u|--user <username>                       VPN Username
    -p|--pass <password>                       VPN Password
    -o|--os <ubuntu|alpine>                    OS type, Default: ubuntu
    -d|--data-dir <local-dir>                  Local dir to mount for data (Default: /data)
    -a|--auth-dir <local-dir>                  Auth/Custom dir to mount with VPN credentials
    -l|--local                                 Build docker image locally
    -i|--image <docker-image>                  Docker Image (Default: spiritsree/docker-torrent-client:latest-ubuntu)
    -r|--no-recommend                          Do not recommend best server use filters instead (only for NordVPN)
    --proto <UDP|TCP|STRONG-TCP|STRONG-UDP>    VPN connection proto (Default: UDP)
    --vpn-country                              Recommend based on country (only for NordVPN if --no-recommend)
    --vpn-type                                 Recommend based on Server Type (only for NordVPN if --no-recommend)

Examples:
    setup.sh -h
    setup.sh -v NordVPN
    setup.sh -u user -p password -v HideMe -i spiritsree/docker-torrent-client:latest-ubuntu
    setup.sh -u user -p password -v FastestVPN --proto tcp

```

Using docker pull use the following command.

```
docker run -d --cap-add=NET_ADMIN \
        --sysctl net.ipv6.conf.all.disable_ipv6=0 \
        --dns 8.8.8.8 --dns 8.8.4.4 \
        -v <local-dir>:/data \
        -e OPENVPN_PROVIDER='<VPN Provider>' \
        -e OPENVPN_CONNECTION='<VPN Provider Hostname>:<proto>' \
        -e OPENVPN_USERNAME='<VPN Provider Username>' \
        -e OPENVPN_PASSWORD='<VPN Provider Password>' \
        -p 9091:9091 \
        spiritsree/docker-torrent-client:latest-alpine
```

If you want to use deluge client use the following.

```
docker run -d --cap-add=NET_ADMIN \
        --sysctl net.ipv6.conf.all.disable_ipv6=0 \
        --dns 8.8.8.8 --dns 8.8.4.4 \
        -v <local-dir>:/data \
        -e OPENVPN_PROVIDER='<VPN Provider>' \
        -e OPENVPN_CONNECTION='<VPN Provider Hostname>:<proto>' \
        -e OPENVPN_USERNAME='<VPN Provider Username>' \
        -e OPENVPN_PASSWORD='<VPN Provider Password>' \
        -e TOR_CLIENT=deluge \
        -p 9091:9091 \
        spiritsree/docker-torrent-client:latest-alpine
```

## Accessing the UI

Just put this in browser `http://<local-ip>:9091/`.

For more details visit [Accessing the UI](./doc/web-ui.md).

## Documentation

* [Usage](./doc/usage.md)
* [Supported Environment Variables](./doc/env.md)
* [Supported VPN Providers](./doc/supported_vpn.md)
* [Accessing the UI](./doc/web-ui.md)
* [Docker Options](./doc/docker.md)
* [Debugging](./doc/debug.md)
* [Container Networking](./doc/networking.md)
* [References](./doc/references.md)

## License

MIT
