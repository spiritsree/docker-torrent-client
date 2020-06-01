# Webproxy Support

Webproxy can be enabled with `WEBPROXY_ENABLED` env variable which will start tinyproxy. If basic authentication is required you can pass the username and password with the below variables.

```
WEBPROXY_ENABLED=true
WEBPROXY_USER=username
WEBPROXY_PASSWORD=password
```

By default the proxy will listen on port `8888` and expose the port outside of docker.

You can use the localIP and the port to configure webproxy and optional authentication with username and password.

Given below an example docker run command to start the docker with VPN and tinyproxy and not torrent client.

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
        -e TOR_CLIENT_ENABLED=false \
        -e WEBPROXY_ENABLED=true \
        -p 9091:9091 \
        -p 8888:8888 \
        spiritsree/docker-torrent-client:latest-ubuntu
```

or with authentication details.

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
        -e TOR_CLIENT_ENABLED=false \
        -e WEBPROXY_ENABLED=true \
        -e WEBPROXY_USER=username \
        -e WEBPROXY_PASSWORD=password \
        -p 9091:9091 \
        -p 8888:8888 \
        spiritsree/docker-torrent-client:latest-ubuntu
```
