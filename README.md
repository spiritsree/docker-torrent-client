# Docker Torrent Client

Docker torrent client with VPN

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

## Reference

* [dumb-init](https://github.com/Yelp/dumb-init)
* [openvpn](https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/)
* [transmission](https://github.com/transmission/transmission)
* [transmission config](https://github.com/transmission/transmission/wiki/Editing-Configuration-Files)
