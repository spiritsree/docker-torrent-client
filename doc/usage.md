# Usage

The docker image can be run with the following command. You need to provide the openvpn details before running the command.

## Docker Run

```
docker run -d --cap-add=NET_ADMIN \
        --sysctl net.ipv6.conf.all.disable_ipv6=0 \
        --dns 8.8.8.8 \
        --dns 8.8.4.4 \
        -v <local-dir>:/data \
        -e OPENVPN_PROVIDER='<VPN Provider>' \
        -e OPENVPN_CONNECTION='<VPN Provider Hostname>:<proto>' \
        -e OPENVPN_USERNAME='<VPN Provider Username>' \
        -e OPENVPN_PASSWORD='<VPN Provider Password>' \
        -p 9091:9091 \
        spiritsree/docker-torrent-client:latest-ubuntu
```

OR

```
docker run -d --cap-add=NET_ADMIN \
        --sysctl net.ipv6.conf.all.disable_ipv6=0 \
        --dns 8.8.8.8 \
        --dns 8.8.4.4 \
        -v <local-dir>:/data \
        -e OPENVPN_PROVIDER='<VPN Provider>' \
        -e OPENVPN_HOSTNAME='<VPN Provider Hostname>' \
        -e OPENVPN_PROTO='<VPN Proto>' \
        -e OPENVPN_USERNAME='<VPN Provider Username>' \
        -e OPENVPN_PASSWORD='<VPN Provider Password>' \
        -p 9091:9091 \
        spiritsree/docker-torrent-client:latest-ubuntu
```

## Helper Script

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
    -i|--image <docker-image>     Docker Image (Default: spiritsree/docker-torrent-client:latest-ubuntu)
    --proto <UDP|TCP>             VPN connection proto UDP or TCP

Examples:
    setup.sh -h
    setup.sh -u user -p password -v HideMe -i spiritsree/docker-torrent-client:latest-ubuntu
    setup.sh -u user -p password -v FastestVPN --proto tcp
```

## Docker Compose

Also there is a sample `docker-compose.yml` given with the details as below.

```yml
version: "3.8"
services:
  torrent-client:
    container_name: docker_torrent_client
    image: spiritsree/docker-torrent-client:latest-alpine
    cap_add:
      - NET_ADMIN
    ports:
      - "9091:9091"
    dns:
      - 8.8.8.8
      - 1.1.1.1
    sysctls:
      - net.ipv6.conf.all.disable_ipv6=0
    volumes:
      - /local/data:/data
    environment:
      OPENVPN_PROVIDER: HideMe
      OPENVPN_CONNECTION: 'free-ca.hide.me:udp'
      OPENVPN_USERNAME:
      OPENVPN_PASSWORD:
      LOCAL_NETWORK: 192.168.1.0/24
    restart: on-failure
```

Keep in mind that `OPENVPN_USERNAME` and `OPENVPN_PASSWORD` are kept empty in the docker-compose.yml file. During the `docker-compose up`, these environment variables will be picked up from the host's environment variable.

You can run using [docker-compose up](https://docs.docker.com/compose/reference/up/) command as show below.

```
$ export OPENVPN_PASSWORD='<username>'
$ export OPENVPN_USERNAME='<password>'
$ docker-compose -d up
```

Environment variables can also be passed in as a file. This will have precedence over the ones provided in `environment:` option.

```
  env_file: .env
```

Compose expects each line in an env file to be in VAR=VAL format. Lines beginning with # are treated as comments and are ignored. Blank lines are also ignored.
