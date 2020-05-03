# Supported VPN Providers

VPN Providers can be selected with `OPENVPN_PROVIDER` variable. The supported VPN providers are as below:

You need to pass `OPENVPN_USERNAME`, `OPENVPN_PASSWORD` for authentication with VPN provider or the auth creds can be added to `ovpn-auth.txt` and mount that dir as volume `/control` while starting the client.

You need to also pass `OPENVPN_HOSTNAME` and `OPENVPN_PROTO` or `OPENVPN_CONNECTION` which is a combination of both in the form `hostname:proto`.

* Fastest VPN
* HideMe
* Hide My Ass
* Nord VPN (Check [Nord API](nordvpn_api.md) for more details on the Nord VPN Public API)
