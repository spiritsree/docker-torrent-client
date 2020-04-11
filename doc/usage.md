# Usage

The docker image can be run with the following command. You need to provide the openvpn details before running the command.

```
docker run -d --cap-add=NET_ADMIN \
        --sysctl net.ipv6.conf.all.disable_ipv6=0 \
        --dns 8.8.8.8 \
        --dns 8.8.4.4 \
        -v <local-dir>:/data \
        -e OPENVPN_PROVIDER='<VPN Provider>' \
        -e OPENVPN_HOSTNAME='<VPN Provider Hostname>' \
        -e OPENVPN_USERNAME='<VPN Provider Username>' \
        -e OPENVPN_PASSWORD='<VPN Provider Password>' \
        -p 9091:9091 \
        docker-torrent-client-ubuntu:latest
```

Or there is a helper script to construct the docker command. Use the following, which will generate the docker command to execute. There is an option to generate the docker image locally or provider the image name from a repository.

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

Examples:
    setup.sh
    setup.sh -u user -p password -v HideMe
```
