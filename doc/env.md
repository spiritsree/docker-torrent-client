# Environment Variable Used

There are many environment variable which can be passed to the docker to customize the config and other parameters.

## General

Variable | Description | Default |
:--------|:------------|:--------|
`CREATE_TUN_DEVICE` | Controls whether to create tunnel device (true) or use an externally mounted one (false) | `true` |
`LOG_FILE` | The log file path | `/data/application.log` |
`ENABLE_FILE_LOGGING` | `true` enables logging to file, `false` will use docker logs | `true` |
`HEALTH_CHECK_HOST` | Docker health check host | `www.google.com` |
`LOCAL_NETWORK` | Local network if you need access from local (comma separated list) | |
`TOR_CLIENT_ENABLED` | Enable torrent client run | `true` |
`TOR_CLIENT` | Torrent client to use (`transmission`, `deluge`) | `transmission` |
`TOR_CLIENT_RUNAS_ROOT` | Run torrent client as root user | `false` |
`TOR_CLIENT_SETTING_DEFAULT` | Use the default config | `false` |
`TOR_WATCH_DIR` | Directory to watch for torrent files and add them to torrent client | `/data/watch` |
`TOR_DOWNLOAD_DIR` | Directory for completed torrents | `/data/completed` |
`TOR_INCOMPLETE_DIR` | Directory for ongoing torrents | `/data/incomplete` |
`TOR_RPC_PORT` | Torrent client web port | `9091` |

## OpenVPN

Variable | Description | Default |
:--------|:------------|:--------|
`OPENVPN_PROVIDER` | VPN provider to use | |
`OPENVPN_USERNAME` | VPN Provider username | |
`OPENVPN_PASSWORD` | VPN Provider password | |
`OPENVPN_HOSTNAME` | VPN Provider server to connect | |
`OPENVPN_CONNECTION` | VPN Provider server and protocol combination | |
`OPENVPN_PROTO` | VPN Provider Protocol | `udp` |
`OPENVPN_OPTS` | Custom options to pass to openvpn client | |

`OPENVPN_OPTS` can be used to pass any custom options to the openvpn client. For OpenVPN client options you can refer [here](https://openvpn.net/community-resources/reference-manual-for-openvpn/)

Default options passed to OpenVPN are:

* `--script-security 2` - Allow calling of built-in executables and user-defined scripts.
* `--up-delay` - Delay TUN/TAP open and possible –up script execution until after TCP/UDP connection establishment with peer.

With `OPENVPN_HOSTNAME` as an option you need to pass `OPENVPN_PROTO` as well if the conenction is not UDP. Otherwise `OPENVPN_CONNECTION` will replace previous both envs.

`OPENVPN_CONNECTION` will have the format of `<server-name>:<proto>`.

if `OPENVPN_PROVIDER` is `custom` then you don't need to provider any of `OPENVPN_CONNECTION` or `OPENVPN_HOSTNAME` and the config will be taken from `/custom/default.ovpn`.

For PIA (PrivateInternetAccess) VPN you can use `STRONG-UDP` or `STRONG-TCP` for better encryption, in addition to `UDP` and `TCP` protocol.

## Transmission

You can refer [transmission config](https://github.com/transmission/transmission/wiki/Editing-Configuration-Files) for details.

All these are set in the config directly with default during the intial run. If you set these ENV during the docker run, those settings will have the precedence. If not set, the value will get constructed from the config file (if previous config exists).

**Bandwidth**

Variable | Description | Default |
:--------|:------------|:--------|
`TRANSMISSION_ALT_SPEED_ENABLED` | Turtle Mode for GUI | `false` |
`TRANSMISSION_ALT_SPEED_UP` | Up speed in KB/s | `50` |
`TRANSMISSION_ALT_SPEED_DOWN` | Down speed in KB/s | `50` |
`TRANSMISSION_SPEED_LIMIT_DOWN` | Down speed limit in KB/s | `100` |
`TRANSMISSION_SPEED_LIMIT_DOWN_ENABLED` | Enable down speed limit | `false` |
`TRANSMISSION_SPEED_LIMIT_UP` | Up speed limit in KB/s | `100` |
`TRANSMISSION_SPEED_LIMIT_UP_ENABLED` | Enable up speed limit | `false` |
`TRANSMISSION_UPLOAD_SLOTS_PER_TORRENT` | Number of upload slots (peers connection) per torrent | `14` |

**Blocklists**

Variable | Description | Default |
:--------|:------------|:--------|
`TRANSMISSION_BLOCKLIST_URL` | Blocklist url | `http://www.example.com/blocklist` |
`TRANSMISSION_BLOCKLIST_ENABLED` | Enable blocklist | `false` |

**Files and Locations**

Variable | Description | Default |
:--------|:------------|:--------|
`TRANSMISSION_INCOMPLETE_DIR_ENABLED` | Enable incomplete directory use | `true` |
`TRANSMISSION_PREALLOCATION` | 0 = Off, 1 = Fast, 2 = Full (slower but reduces disk fragmentation) | `1` |
`TRANSMISSION_RENAME_PARTIAL_FILES` | Postfix partially downloaded files with ".part" | `true` |
`TRANSMISSION_START_ADDED_TORRENTS` | Start torrents as soon as they are added | `true` |
`TRANSMISSION_TRASH_ORIGINAL_TORRENT_FILES` | Delete torrents added from the watch directory | `false` |
`TRANSMISSION_UMASK` | Sets transmission's file mode creation mask | `2` |
`TRANSMISSION_WATCH_DIR_ENABLED` | Enable watch directory | `true` |

**Misc**

Variable | Description | Default |
:--------|:------------|:--------|
`TRANSMISSION_CACHE_SIZE_MB` | Transmission's memory cache in MB | `4` |
`TRANSMISSION_DHT_ENABLED` | Enable distribution hash table | `true` |
`TRANSMISSION_ENCRYPTION` | 0 = Prefer unencrypted connections, 1 = Prefer encrypted connections, 2 = Require encrypted connections; default = 1 | `1` |
`TRANSMISSION_LAZY_BITFIELD_ENABLED` | To help get around some ISP filtering | `true` |
`TRANSMISSION_LPD_ENABLED` | Enable local peer discovery | `false` |
`TRANSMISSION_MESSAGE_LEVEL` | Verbosity (0 = None, 1 = Error, 2 = Info, 3 = Debug) | `2` |
`TRANSMISSION_PEX_ENABLED` | Enable peer exchange | `true` |
`TRANSMISSION_PREFETCH_ENABLED` | When enabled, Transmission will hint to the OS which piece data it's about to read from disk in order to satisfy requests from peers | `true` |
`TRANSMISSION_SCRAPE_PAUSED_TORRENTS_ENABLED` |  | `true` |
`TRANSMISSION_SCRIPT_TORRENT_DONE_ENABLED` | Run a script at torrent completion | `false` |
`TRANSMISSION_SCRIPT_TORRENT_DONE_FILENAME` | Path to script | |
`TRANSMISSION_UTP_ENABLED` | Enable micro transport protocol | `true` |

**Peers**

Variable | Description | Default |
:--------|:------------|:--------|
`TRANSMISSION_BIND_ADDRESS_IPV4` | Where to listen for peer connections (Will be updated with tunnel IP to avoid connection leak) | `0.0.0.0` |
`TRANSMISSION_BIND_ADDRESS_IPV6` | Where to listen for peer connections | `::` |
`TRANSMISSION_PEER_CONGESTION_ALGORITHM` | Peer congestion algorithm to use | |
`TRANSMISSION_PEER_ID_TTL_HOURS` | Recycle the peer id used for public torrents after N hours of use | `6` |
`TRANSMISSION_PEER_LIMIT_GLOBAL` | Global peer limit | `240` |
`TRANSMISSION_PEER_LIMIT_PER_TORRENT` | Per torrent peer limit | `60` |
`TRANSMISSION_PEER_SOCKET_TOS` | Set type of service parameter for outgoing TCP packets | `default` |

**Peer Port**

Variable | Description | Default |
:--------|:------------|:--------|
`TRANSMISSION_PEER_PORT` | Peer port | `51413` |
`TRANSMISSION_PEER_PORT_RANDOM_HIGH` | Higher limit if `TRANSMISSION_PEER_PORT_RANDOM_ON_START` enabled | `65535` |
`TRANSMISSION_PEER_PORT_RANDOM_LOW` | Lower limit if `TRANSMISSION_PEER_PORT_RANDOM_ON_START` enabled | `45535` |
`TRANSMISSION_PEER_PORT_RANDOM_ON_START` | Select a rando peer port if `true` | `false` |
`TRANSMISSION_PORT_FORWARDING_ENABLED` | Enable UPnP or NAT-PMP | `false` |

**Queuing**

Variable | Description | Default |
:--------|:------------|:--------|
`TRANSMISSION_DOWNLOAD_QUEUE_ENABLED` | When true, Transmission will only download download-queue-size non-stalled torrents at once | `true` |
`TRANSMISSION_DOWNLOAD_QUEUE_SIZE` | Download queue size | `6` |
`TRANSMISSION_QUEUE_STALLED_ENABLED` | When true, torrents that have not shared data for queue-stalled-minutes are treated as 'stalled' and are not counted against the queue-download-size and seed-queue-size limits | `true` |
`TRANSMISSION_QUEUE_STALLED_MINUTES` | Queue stalled in minutes | `30` |
`TRANSMISSION_SEED_QUEUE_ENABLED` | When true. Transmission will only seed seed-queue-size non-stalled torrents at once | `false` |
`TRANSMISSION_SEED_QUEUE_SIZE` | Seed queue size | `10` |

**RPC**

Variable | Description | Default |
:--------|:------------|:--------|
`TRANSMISSION_RPC_AUTHENTICATION_REQUIRED` | Is RPC authentication required | `true` |
`TRANSMISSION_RPC_BIND_ADDRESS` | Where to listen for RPC connections | `0.0.0.0` |
`TRANSMISSION_RPC_ENABLED` | Enable RPC | `true` |
`TRANSMISSION_RPC_HOST_WHITELIST` | Host whitelist domains or IPs | |
`TRANSMISSION_RPC_HOST_WHITELIST_ENABLED` | Enable host whitelisting | `true` |
`TRANSMISSION_RPC_PASSWORD` | RPC password | `password` |
`TRANSMISSION_RPC_URL` | RPC url | `/transmission/` |
`TRANSMISSION_RPC_USERNAME` | RPC username | `username` |
`TRANSMISSION_RPC_WHITELIST` | RPC whitelist IPs (comma-separated) | `127.0.0.1` |
`TRANSMISSION_RPC_WHITELIST_ENABLED` | Enable RPC whitelist | `true` |

**Scheduling**

Variable | Description | Default |
:--------|:------------|:--------|
`TRANSMISSION_ALT_SPEED_TIME_ENABLED` | When enabled, this will toggle the `TRANSMISSION_ALT_SPEED_ENABLED` setting | `false` |
`TRANSMISSION_ALT_SPEED_TIME_BEGIN` | Alt speed begin time, in minutes from midnight (as per default, 9am) | `540` |
`TRANSMISSION_ALT_SPEED_TIME_END` | Alt speed end time, in minutes from midnight (as per default, 5pm) | `1020` |
`TRANSMISSION_ALT_SPEED_TIME_DAY` | When you want scheduler enabled (default is all days) | `127` |
`TRANSMISSION_IDLE_SEEDING_LIMIT` | Stop seeding after being idle for N minutes | `30` |
`TRANSMISSION_IDLE_SEEDING_LIMIT_ENABLED` | Enable idle seeding limit | `false` |
`TRANSMISSION_RATIO_LIMIT` | Ratio limit default 2.0 | `2` |
`TRANSMISSION_RATIO_LIMIT_ENABLED` | Enable ratio limit | `false` |
`TRANSMISSION_HOME` | Home dir for transmission to store the state | `/data/transmission-home` |
`TRANSMISSION_WEB_UI` | Custom web UI (`combustion` or `transmission-web-control`) | |
`TRANSMISSION_LOG_LEVEL` | Transmission client log level (`info` or `debug`) | `info` |

## Deluge

All these are set in the config directly with default during the intial run. The ENV passed during docker run will have the precedence. If not set, the value will get constructed from the config file (if previous config exists).

**General**

Variable | Description | Default |
:--------|:------------|:--------|
`DELUGE_HOME` | Home dir for deluge to store the state | `/data/deluge-home` |
`DELUGE_GEOIP_DB_LOCATION` | Geo IP DB location  | `/usr/share/GeoIP/GeoIP.dat` |
`DELUGE_AUTH_USERNAME` | Deluge client auth user | `username` |
`DELUGE_AUTH_PASSWORD` | Deluge client auth password | `password` |
`DELUGE_LOG_LEVEL` | Deluge log level (`none`, `critical`, `error`, `warning`, `info`, `debug`) | `info` |

**Downloads**

The download paths will be controlled by `TOR_CLIENT_` vars.

Variable | Description | Default |
:--------|:------------|:--------|
`DELUGE_MOVE_COMPLETED` | Enable move completed torrents to completed dir | `true` |
`DELUGE_COPY_TORRENT_FILE` | Enable copying of .torrent files to watch folder | `true` |
`DELUGE_DEL_COPY_TORRENT_FILE` | Delete torrent file after copying | `false` |
`DELUGE_PRIORITIZE_FIRST_LAST_PIECES` | Enable prioritizing first and last pieces of torrent | `false` |
`DELUGE_SEQUENTIAL_DOWNLOAD` | Enable sequential download | `false` |
`DELUGE_ADD_PAUSED` | Enable adding torrents in Paused state | `false` |
`DELUGE_PRE_ALLOCATE_STORAGE` | Enable pre-allocation of disk space | `false` |

**Network**

Variable | Description | Default |
:--------|:------------|:--------|
`DELUGE_LISTEN_INTERFACE` | Deluge daemon listen on | `0.0.0.0` |
`DELUGE_RANDOM_PORT` | Use random ports for incoming | `false` |
`DELUGE_PEER_PORT_RANDOM_HIGH` | Upper limit of port to choose from if `DELUGE_RANDOM_PORT` is  `true` | `65535` |
`DELUGE_PEER_PORT_RANDOM_LOW` | Lower limit of port to choose from if `DELUGE_RANDOM_PORT` is  `true` | `45535` |
`DELUGE_PEER_PORT` | Port to listen to if `DELUGE_RANDOM_PORT` is `false` | `53242` |
`DELUGE_LISTEN_REUSE_PORT` | Reuse port | `true` |
`DELUGE_LISTEN_USE_SYS_PORT` | Use system port | `false` |
`DELUGE_OUTGOING_INTERFACE` | Network interface name or IP address for outgoing BitTorrent connections | `0.0.0.0` |
`DELUGE_RANDOM_OUTGOING_PORTS` | Use random ports for outgoing | `true` |
`DELUGE_PEER_PORT_OUT` | Outgoing port if `DELUGE_RANDOM_OUTGOING_PORTS` is `false` | `55242` |
`DELUGE_UPNP` | Enable UPnP | `true` |
`DELUGE_NATPMP` | Enable NAT-PMP | `true` |
`DELUGE_UTPEX` | Enable Peer Exchange | `true` |
`DELUGE_LSD` | Enable LSD | `true` |
`DELUGE_DHT` | Enable DHT | `true` |
`DELUGE_PEER_TOS` | Peer TOS (Type Of Service) byte (Masks: Normal Service 0x00, Minimize Cost 0x02, Maximize Reliability 0x04, Maximize Throughput 0x08, Minimize-delay 0x10) | `0x00` |

**Encryption**

Variable | Description | Default |
:--------|:------------|:--------|
`DELUGE_ENC_IN_POLICY` | Enable inbound encryption (0 - forced, 1 - enables, 2 - disabled) | `1` |
`DELUGE_ENC_OUT_POLICY` | Enable outbound encryption (0 - forced, 1 - enables, 2 - disabled) | `1` |
`DELUGE_ENC_LEVEL` |  Encrypt entire stream (0 - Handshake, 1 - Full Stream, 2 - Either) | `2` |

**Bandwidth**

Variable | Description | Default |
:--------|:------------|:--------|
`DELUGE_MAX_CONNECTIONS_GLOBAL` | Maximum connections | `200` |
`DELUGE_MAX_UPLOAD_SLOTS_GLOBAL` | Maximum upload slot | `4` |
`DELUGE_MAX_DOWNLOAD_SPEED` | Maximum download speed (KiB/s) | `-1.0` |
`DELUGE_MAX_UPLOAD_SPEED` | Maximum upload speed (KiB/s) | `-1` |
`DELUGE_MAX_HALF_OPEN_CONNECTIONS` | Maximum half open connections | `50` |
`DELUGE_MAX_CONNECTIONS_PER_SECOND` | Maximum connection attempts per second | `20` |
`DELUGE_IGNORE_LIMITS_ON_LOCAL_NETWORK` | Ignore limits on local network | `true` |
`DELUGE_RATE_LIMIT_IP_OVERHEAD` | Rate limit IP overhead | `true` |
`DELUGE_MAX_CONNECTIONS_PER_TORRENT` | Maximum connections per torrent | `-1` |
`DELUGE_MAX_UPLOAD_SLOTS_PER_TORRENT` | Maximum upload slot per torrent | `-1` |
`DELUGE_MAX_DOWNLOAD_SPEED_PER_TORRENT` | Maximum download speed (KiB/s) per torrent | `-1` |
`DELUGE_MAX_UPLOAD_SPEED_PER_TORRENT` | Maximum upload speed (KiB/s) per torrent | `-1` |

**Interface (Web UI)**

Variable | Description | Default |
:--------|:------------|:--------|
`DELUGE_SHOW_SESSION_SPEED` | Show session speed in titlebar | `false` |
`DELUGE_SIDEBAR_SHOW_ZERO` | Show filters with zero torrents | `false` |
`DELUGE_SIDEBAR_MULTIPLE_FILTERS` | ALlow the use of multiple filters at once | `true` |
`DELUGE_SHOW_SIDEBAR` | Display sidebar in UI | `true` |
`DELUGE_LANGUAGE` | UI language | `System Default` |
`DELUGE_SESSION_TIMEOUT` | Web session timeout | `3600` |
`DELUGE_INTERFACE` | Where to listen for web connections | `0.0.0.0` |
`DELUGE_HTTPS` | Enable ssl | `false` |
`DELUGE_THEME` | Deluge web theme | `gray` |
`DELUGE_PWD_SALT` | Salt string for password encoding | `2ce1a410bcdcc53064129b6d950f2e9fee4edc1e` |

**Daemon**

Variable | Description | Default |
:--------|:------------|:--------|
`DELUGE_DAEMON_PORT` | Daemon port | `58846` |
`DELUGE_ALLOW_REMOTE` | Allow remote connections | `false` |

**Queue**

Variable | Description | Default |
:--------|:------------|:--------|
`DELUGE_QUEUE_NEW_TO_TOP` | Queue new torrents to top  | `false` |
`DELUGE_MAX_ACTIVE_LIMIT` | Total active torrents limit | `10` |
`DELUGE_MAX_ACTIVE_DOWNLOADING` | Total active torrents downloading | `5` |
`DELUGE_MAX_ACTIVE_SEEDING` | Total active torrents seeding | `7` |
`DELUGE_DONT_COUNT_SLOW_TORRENTS` | Ignore slow torrents  | `false` |
`DELUGE_AUTO_MANAGE_PREFER_SEEDS` | Prefer seeding torrents | `false` |
`DELUGE_SHARE_RATIO_LIMIT` | Share ratio limit (for seeding rotation) | `2.0` |
`DELUGE_SEED_TIME_RATIO_LIMIT` | Speed time ratio (for seeding rotation) | `7.0` |
`DELUGE_SEED_TIME_LIMIT` | Speed time limit (m) (for seeding rotation) | `180` |
`DELUGE_STOP_SEED_AT_RATIO` | Enable share ratio reached when reaches `DELUGE_STOP_SEED_RATIO`. if enabled `true` default action is to `pause torrent` unless `DELUGE_REMOVE_SEED_AT_RATIO` is `true` | `false` |
`DELUGE_STOP_SEED_RATIO` | Share ratio limit | `2.0` |
`DELUGE_REMOVE_SEED_AT_RATIO` | Remove torrent when share ratio reches `DELUGE_STOP_SEED_RATIO` | `false` |
`DELUGE_AUTO_MANAGED` | Torrents will obey queue settings | `true` |
`DELUGE_SUPER_SEEDING` | Enable super seeding | `false` |

**Proxy**

Variable | Description | Default |
:--------|:------------|:--------|
`DELUGE_PROXY_ANONYMOUS_MODE` | Proxy anonymous mode | `false` |
`DELUGE_PROXY_FORCE_PROXY` | Force proxy connection | `false` |
`DELUGE_PROXY_HOSTNAME` | Proxy hostname to user | |
`DELUGE_PROXY_PORT` | Proxy port | `8080` |
`DELUGE_PROXY_USERNAME` | Proxy username | |
`DELUGE_PROXY_PASSWORD` | Proxy password | |
`DELUGE_PROXY_PROXY_HOSTNAMES` | Proxying proxy hostnames | `true` |
`DELUGE_PROXY_PROXY_PEER_CONNECTIONS` | Proxying peer connections | `true` |
`DELUGE_PROXY_PROXY_TRACKER_CONNECTIONS` | Proxying tracker conenctions | `true` |
`DELUGE_PROXY_TYPE` | Proxy type | `0` |

**Cache**

Variable | Description | Default |
:--------|:------------|:--------|
`DELUGE_CACHE_SIZE` | Cache size (in 16 KiB blocks) | `512` |
`DELUGE_CACHE_EXPIRY` | Cache expiry in seconds | `60` |

**Plugins**

Variable | Description | Default |
:--------|:------------|:--------|
`DELUGE_ENABLED_PLUGINS` | Comma separated list on enabled plugins | |

## Firewall

Environment variables used for firewall config.

Variable | Description | Default |
:--------|:------------|:--------|
`FIREWALL_ENABLED` | Enables firewall | `false` |
`FIREWALL_ALLOW_GW_CIDR` | Add rules for Gateway network CIDR | `false` |
`FIREWALL_PORTS_TO_ALLOW` | Ports to allow in firewall (comma separated) | |
