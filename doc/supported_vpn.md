# Supported VPN Providers

VPN Providers can be selected with `OPENVPN_PROVIDER` variable. The supported VPN providers are as below:

You need to pass `OPENVPN_USERNAME`, `OPENVPN_PASSWORD` for authentication with VPN provider or the auth creds can be added to `ovpn-auth.txt` and mount that dir as volume `/control` while starting the client.

You need to also pass `OPENVPN_HOSTNAME` and `OPENVPN_PROTO` or `OPENVPN_CONNECTION` (which is a combination of both in the form `hostname:proto`).

* BTGuard
* FastestVPN
* HideMe
* HideMyAss
* IPVanish
* IVPN
* NordVPN (Check [Nord API](nordvpn_api.md) for more details on the Nord VPN Public API)
* PIA
* PrivateVPN
* PureVPN
* SurfShark
* TunnelBear
* VyprVPN


## Custom VPN

If a VPN is not supported here you can pass the custom ovpn config as a mount to the docker. Mount the directory containing the file `default.ovpn` to `/custom` and set the env as `OPENVPN_PROVIDER=CUSTOM`

```
-v /ovpn-config:/custom \
-e OPENVPN_PROVIDER=custom
```

**VPN Auth Credentials**

The `auth-user-pass` config in ovpn config need to be updated with either of the following

* `/control/ovpn-auth.txt` (`OPENVPN_USERNAME` and `OPENVPN_PASSWORD` needed or mount /control with `ovpn-auth.txt`)
* `/custom/ovpn-auth.txt` (`OPENVPN_USERNAME` and `OPENVPN_PASSWORD` not needed)

