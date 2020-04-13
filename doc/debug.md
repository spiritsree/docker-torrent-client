# Debugging the container issues

For any issues within the docker container, you can connect to the running container and do the troubleshooting.

* Find the running container

```
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND                  CREATED              STATUS                                 PORTS                    NAMES
c29ee56a1560        docker-torrent-client-ubuntu:latest   "dumb-init /etc/open…"   About a minute ago   Up About a minute (health: starting)   0.0.0.0:9091->9091/tcp   affectionate_banach
```
* Exec into the container with command bash (You will get a bash shell of the container)

```
$ docker exec -ti c29ee56a1560 bash
```

* You can do the troubleshooting here

## Tools for troubleshooting

* netstat - Need to install package `net-tools`
* dig - Need to install `dnsutils` (for Ubuntu) or `bind-tools` (for alpine)
* drill - Alternative tool for dig. Need to install `drill`
* nc - Need to install package `netcat` (for ubuntu) or `netcat-openbsd` (for alpine)
* telnet - Need to install package `telnet` (for ubuntu) or `busybox-extras` (for alpine)

## Some example commands

* How to get public IP (should be VPN ip if connected to VPN)

```
$ dig +short myip.opendns.com @resolver1.opendns.com
$ curl http://wtfismyip.com/text
```

or if you need more details

```
$ curl ipinfo.io 2> /dev/null | jq .
```
