# Nord VPN API

These are some of the Nord VPN public api which are useful for finding the best servers etc.


* User current IP address

```
$ curl https://api.nordvpn.com/user/address
```

* OpenVPN config download

```
$ curl -L https://api.nordvpn.com/files/zipv2 -o config.zip
```

* Nameserver list

```
$ curl https://api.nordvpn.com/dns/smart
```

* List of NordVPN Servers

```
$ curl https://api.nordvpn.com/servers
```

* NordVPN Server stat

```
$ curl https://api.nordvpn.com/server/stats
$ curl https://api.nordvpn.com/server/stats/<hostname>
```

* NordVPN Country list

```
$ curl https://api.nordvpn.com/v1/servers/countries
```

* NordVPN Server Types

```
$ curl https://api.nordvpn.com/v1/servers/groups
```

* NordVPN Security protocols

```
$ curl https://api.nordvpn.com/v1/technologies
```

* NordVPN Best Recommendation (including filters)

```
$ curl -s https://api.nordvpn.com/v1/servers/recommendations
$ curl -s 'https://api.nordvpn.com/v1/servers/recommendations?limit=1'
$ curl -s 'https://api.nordvpn.com/v1/servers/recommendations?filters\[country_id\]=228&limit=1'
$ curl -s 'https://api.nordvpn.com/v1/servers/recommendations?filters\[country_id\]=228&filters\[servers_groups\]\[identifier\]=legacy_p2p&filters\[servers_technologies\]\[identifier\]=openvpn_tcp&limit=1'
```
