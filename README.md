# Docker Torrent Client

Docker torrent client with VPN

## Contents

1. [Requirements](#requirements)
1. [Quick Start](#quick-start)
1. [Accessing the UI](#accessing-the-ui)
1. [Documentation](#documentation)
1. [Reference](#reference)

## Requirements

* [jq](https://stedolan.github.io/jq/)
* [docker](https://www.docker.com/)

## Quick start

```
$ ./setup.sh -h
docker-torrent-client setup

Usage:
    setup.sh M_ARGS [O_ARGS]

Mandatory Arguments (M_ARGS):
    -u|--user <username>              VPN Username
    -p|--pass <password>              VPN Password
    -v|--vpn-provider <vpn-provider>  VPN Provider (e.g: HideMe)

Optional Arguments (O_ARGS):
    -h|--help                     Print usage
    -o|--os <ubuntu|alpine>       OS type, Default: ubuntu
    -d|--data-dir <local-dir>     Local dir to mount for data (This should be added in Docker File Sharing Default: ~/Downloads/uTorrent/data/)
    -l|--local                    Build docker image locally
    --proto <UDP|TCP>             VPN connection proto UDP or TCP

Examples:
    setup.sh -h
    setup.sh -u user -p password -v HideMe
    setup.sh -u user -p password -v FastestVPN --proto tcp
```

## Accessing the UI

Web UI can be accessed using browser extensions

* [Chome](https://chrome.google.com/webstore/detail/transmission-easy-client/cmkphjiphbjkffbcbnjiaidnjhahnned?hl=en)
* [FireFox](https://addons.mozilla.org/en-US/firefox/addon/transmission-easy-client/)
* [Opera](https://addons.opera.com/en/extensions/details/transmission-easy-client/)

**Config Parameters**

| Param        | value from ENV                      |  Default          |
|:------------:|:-----------------------------------:|:-----------------:|
| **Username** | TRANSMISSION_RPC_USERNAME           | username          |
| **Password** | TRANSMISSION_RPC_PASSWORD           | password          |
| **IP**       | Localhost IP                        | 127.0.0.1         |
| **Port**     | TRANSMISSION_RPC_PORT               | 9091              |
| **Path**     | TRANSMISSION_RPC_URL and append rpc | /transmission/rpc |

## Documentation

* [Usage](./doc/usage.md)
* [Environment Variables](./doc/env.md)
* [Docker Options](./doc/docker.md)
* [Debugging](./doc/debug.md)

## Reference

* [dockerize](https://github.com/jwilder/dockerize)
* [dumb-init](https://github.com/Yelp/dumb-init)
* [Firewall](https://help.ubuntu.com/lts/serverguide/firewall.html)
* [openvpn](https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/)
* [transmission](https://github.com/transmission/transmission)
* [transmission config](https://github.com/transmission/transmission/wiki/Editing-Configuration-Files)
