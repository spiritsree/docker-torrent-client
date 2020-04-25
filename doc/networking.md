# Container Networking

You can use container networking to interconnect multiple docker containers. This is useful if you want another container traffic to pass through the torrent client container.

## How To

If you run a container with a specific name, the second container can be started with `--net=container:<first-container-name>` option so that it will use the first containers network.

```
docker run --rm -d --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 \
        --name=docker_torrent_client --dns 8.8.8.8 --dns 8.8.4.4 \
        -v <local-dir>:/data -e OPENVPN_PROVIDER='<VPN Provider>' \
        -e OPENVPN_CONNECTION='<VPN Hostname>:<proto>' \
        -e OPENVPN_USERNAME='<VPN Username>' -e OPENVPN_PASSWORD='<VPN Password>' \
        -e TOR_CLIENT_ENABLED=false -p 9091:9091 \
        spiritsree/docker-torrent-client:latest-ubuntu
```

Now start second container using the first containers networking.

```
docker run --rm -d --name=network_test \
              --net=container:docker_torrent_client \
              bash bash -c "while true; do sleep 2; done"
```

This container will use the first container network. Now for testing exec into the container.

```
$ docker exec -ti network_test bash
bash-5.0# apk add curl

bash-5.0# traceroute 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 46 byte packets
 1  10.129.154.1 (10.129.154.1)  251.095 ms  248.898 ms  248.132 ms
 2  37.120.205.145 (37.120.205.145)  322.536 ms  306.896 ms  307.300 ms
 ~~~ truncated ~~~~

bash-5.0# curl ipecho.net/plain
37.120.205.165
```

From the above we can verify that the connection is going via VPN which is in the first container.

What if the first container dies? In case if first container dies, the second container will wait for first connection to be re-established. The traffic will fail from the second till the first one comes back alive.

```
bash-5.0# curl ipecho.net/plain
curl: (6) Could not resolve host: ipecho.net

bash-5.0# traceroute 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 30 hops max, 46 byte packets
 1traceroute: sendto: Network unreachable
```

## Docker Compose way

Provided a sample `docker-compose-network.yml` which can be modified and use for this purpose. This is mostly useful if you want to run torrent client on a separate container or some other app which need to route via VPN etc.

```yml
# supported docker-compose version 1.25.5
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
      OPENVPN_PROVIDER: 'HideMe'
      OPENVPN_CONNECTION: 'free-ca.hide.me:udp'
      OPENVPN_USERNAME:
      OPENVPN_PASSWORD:
      TOR_CLIENT_ENABLED: 'false'
      LOCAL_NETWORK: 192.168.1.0/24
    restart: on-failure
    # Below are only for swarm deploy. Ignored for docker-compose up
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

    app_container:
    container_name: generic_container
    image: bash
    sysctls:
      - net.ipv6.conf.all.disable_ipv6=0
    network_mode: "service:torrent-client"
    depends_on:
      - torrent-client
    command: bash -c "while true; do sleep 2; done"
```

Once the docker-compose file is ready. just run the `docker-compose up` to start the services.

```
$ docker-compose -f docker-compose-network.yml up -d
```


