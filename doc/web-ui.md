# Accessing the UI

## Transmission

### Original UI

You can access the default UI or any custom UI with the following url from you local host. Just make sure that the exposed port is 9091.

```
http://<local-ip>:9091/
```

### Using browser extensions

Web UI can be accessed using browser extensions with transmission built-in RPC url. For this to work `TRANSMISSION_RPC_ENABLED` should be set to `true`.

* [Chome](https://chrome.google.com/webstore/detail/transmission-easy-client/cmkphjiphbjkffbcbnjiaidnjhahnned?hl=en)
* [FireFox](https://addons.mozilla.org/en-US/firefox/addon/transmission-easy-client/)
* [Opera](https://addons.opera.com/en/extensions/details/transmission-easy-client/)

**Config Parameters**

| Param        | value from ENV                      |  Default          |
|:------------:|:-----------------------------------:|:-----------------:|
| **Username** | TRANSMISSION_RPC_USERNAME           | username          |
| **Password** | TRANSMISSION_RPC_PASSWORD           | password          |
| **IP**       | Localhost IP                        | 127.0.0.1         |
| **Port**     | TOR_RPC_PORT                        | 9091              |
| **Path**     | TRANSMISSION_RPC_URL and append rpc | /transmission/rpc |

### Alternate UIs

The setup provides some additional UIs which if enabled can be accessed using the below url from local host.

```
http://<local-ip>:9091/
```

This is considering the port exposed is `9091` which is the default.

#### Combustion

Combustion is a sleek, modern web interface for transmission. Check the reference for more details.

You need to pass `-e TRANSMISSION_WEB_UI=combustion` to the docker run command for enabling this UI.

#### Transmission Web Control

Another customer web UI. For details visit [here](https://github.com/ronggang/transmission-web-control/wiki).

You need to pass `-e TRANSMISSION_WEB_UI=transmission-web-control` to the docker run command for enabling this UI.

Transmission Web Control UI also gives an option to switch to the original Transmission UI.

## Deluge

### Deluge UI

You can access the default UI with the following url from you localhost. Just make sure that the exposed port is 9091.

```
http://<local-ip>:9091/
```
