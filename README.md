# Docker Torrent Client

Docker torrent client with VPN

## Contents

1. [Requirements](#requirements)
1. [Usage](#usage)
1. [Accessing the UI](#accessing-the-ui)
1. [Reference](#reference)

## Requirements

* [jq](https://stedolan.github.io/jq/)
* [docker](https://www.docker.com/)

## Usage

```
$ ./setup.sh -h
docker-torrent-client setup

Usage:
    setup.sh [-h|--help] <-u|--user username> <-p|--pass password> [-o|--os <ubuntu|alpine>] [-d|--data-dir <local-dir>]

Mandatory Arguments:
    -u|--user <username>          VPN Username
    -p|--pass <password>          VPN Password

Optional Arguments:
    -h|--help                     Print usage
    -o|--os <ubuntu|alpine>       OS type, Default: ubuntu
    -d|--data-dir <local-dir>     Local dir to mount for data (This should be added in Docker File Sharing Default: ~/Downloads/uTorrent/data/

Examples:
    setup.sh
    setup.sh -u user -p password
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

## Reference

* [dockerize](https://github.com/jwilder/dockerize)
* [dumb-init](https://github.com/Yelp/dumb-init)
* [openvpn](https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/)
* [transmission](https://github.com/transmission/transmission)
* [transmission config](https://github.com/transmission/transmission/wiki/Editing-Configuration-Files)
