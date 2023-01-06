# VPN Config Updater

This is a helper container to update the vpn config.

## Usage

**Build**

```
docker build -t config-updater -f Dockerfile .
```

**Run**

```
docker run --rm -d \
            -e VPN_PROVIDER=<vpn-provider> \
            -v <repo-dir>:/repo \
            config-updater:latest
```

```
docker run --rm \
            -e DEBUG=true \
            -e VPN_PROVIDER=<vpn-provider> \
            -v <repo-dir>:/repo \
            config-updater:latest
```
