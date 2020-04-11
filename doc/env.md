# Environment Variable Used

There are many environment variable which can be passed to the docker to customize the config and other parameters.

## General

Variable | Description | Default |
:--------|:------------|:--------|
`CREATE_TUN_DEVICE` | Controls whether to create tunnel device (true) or use an externally mounted one (false) | `true` |
`LOG_FILE` | The log file path | `/data/application.log` |
`ENABLE_FILE_LOGGING` | `true` enables logging to file, `false` will use docker logs | `true` |
`HEALTH_CHECK_HOST` | Docker health check host | `www.google.com` |
`LOCAL_NETWORK` | Local network if you need access from local | |

## OpenVPN

Variable | Description | Default |
:--------|:------------|:--------|
`OPENVPN_PROVIDER` | VPN provider to use | |
`OPENVPN_USERNAME` | VPN Provider username | |
`OPENVPN_PASSWORD` | VPN Provider password | |
`OPENVPN_HOSTNAME` | VPN Provider server to connect | |
`OPENVPN_OPTS` | Custom options to pass to openvpn client | |

`OPENVPN_OPTS` can be used to pass any custom options to the openvpn client. For OpenVPN client options you can refer [here](https://openvpn.net/community-resources/reference-manual-for-openvpn/)

Default options passed to OpenVPN are:

* `--script-security 2` - Allow calling of built-in executables and user-defined scripts.
* `--up-delay` - Delay TUN/TAP open and possible –up script execution until after TCP/UDP connection establishment with peer.

## Transmission

You can refer [transmission config](https://github.com/transmission/transmission/wiki/Editing-Configuration-Files) for details.

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
`TRANSMISSION_BLOCKLIST_URL` | Blocklist url | `http://www.example.com/blocklist` |
`TRANSMISSION_BLOCKLIST_ENABLED` | Enable blocklist | `false` |
`TRANSMISSION_DOWNLOAD_DIR` | Directory for completed torrents | `/data/completed` |
`TRANSMISSION_INCOMPLETE_DIR` | Directory for ongoing torrents | `/data/incomplete` |
`TRANSMISSION_INCOMPLETE_DIR_ENABLED` | Enable incomplete directory use | `true` |
`TRANSMISSION_PREALLOCATION` | 0 = Off, 1 = Fast, 2 = Full (slower but reduces disk fragmentation) | `1` |
`TRANSMISSION_RENAME_PARTIAL_FILES` | Postfix partially downloaded files with ".part" | `true` |
`TRANSMISSION_START_ADDED_TORRENTS` | Start torrents as soon as they are added | `true` |
`TRANSMISSION_TRASH_ORIGINAL_TORRENT_FILES` | Delete torrents added from the watch directory | `false` |
`TRANSMISSION_UMASK` | Sets transmission's file mode creation mask | `2` |
`TRANSMISSION_WATCH_DIR` | Directory to watch for torrent files and add them to transmission | `/data/watch` |
`TRANSMISSION_WATCH_DIR_ENABLED` | Enable watch directory | `true` |
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
`TRANSMISSION_SCRIPT_TORRENT_DONE_FILENAME` | Path to script | `` |
`TRANSMISSION_UTP_ENABLED` | Enable micro transport protocol | `true` |
`TRANSMISSION_BIND_ADDRESS_IPV4` | Where to listen for peer connections (Will be updated with tunnel IP to avoid connection leak) | `0.0.0.0` |
`TRANSMISSION_BIND_ADDRESS_IPV6` | Where to listen for peer connections | `::` |
`TRANSMISSION_PEER_CONGESTION_ALGORITHM` | Peer congestion algorithm to use | `` |
`TRANSMISSION_PEER_ID_TTL_HOURS` | Recycle the peer id used for public torrents after N hours of use | `6` |
`TRANSMISSION_PEER_LIMIT_GLOBAL` | Global peer limit | `240` |
`TRANSMISSION_PEER_LIMIT_PER_TORRENT` | Per torrent peer limit | `60` |
`TRANSMISSION_PEER_SOCKET_TOS` | Set type of service parameter for outgoing TCP packets | `default` |
`TRANSMISSION_PEER_PORT` | Peer port | `51413` |
`TRANSMISSION_PEER_PORT_RANDOM_HIGH` | Higher limit if `TRANSMISSION_PEER_PORT_RANDOM_ON_START` enabled | `65535` |
`TRANSMISSION_PEER_PORT_RANDOM_LOW` | Lower limit if `TRANSMISSION_PEER_PORT_RANDOM_ON_START` enabled | `45535` |
`TRANSMISSION_PEER_PORT_RANDOM_ON_START` | Select a rando peer port if `true` | `false` |
`TRANSMISSION_PORT_FORWARDING_ENABLED` | Enable UPnP or NAT-PMP | `false` |
`TRANSMISSION_DOWNLOAD_QUEUE_ENABLED` | When true, Transmission will only download download-queue-size non-stalled torrents at once | `true` |
`TRANSMISSION_DOWNLOAD_QUEUE_SIZE` | Download queue size | `5` |
`TRANSMISSION_QUEUE_STALLED_ENABLED` | When true, torrents that have not shared data for queue-stalled-minutes are treated as 'stalled' and are not counted against the queue-download-size and seed-queue-size limits | `true` |
`TRANSMISSION_QUEUE_STALLED_MINUTES` | Queue stalled in minutes | `30` |
`TRANSMISSION_SEED_QUEUE_ENABLED` | When true. Transmission will only seed seed-queue-size non-stalled torrents at once | `false` |
`TRANSMISSION_SEED_QUEUE_SIZE` | Seed queue size | `10` |
`TRANSMISSION_RPC_AUTHENTICATION_REQUIRED` | Is RPC authentication required | `true` |
`TRANSMISSION_RPC_BIND_ADDRESS` | Where to listen for RPC connections | `0.0.0.0` |
`TRANSMISSION_RPC_ENABLED` | Enable RPC | `true` |
`TRANSMISSION_RPC_HOST_WHITELIST` | Host whitelist domains or IPs | `` |
`TRANSMISSION_RPC_HOST_WHITELIST_ENABLED` | Enable host whitelisting | `true` |
`TRANSMISSION_RPC_PASSWORD` | RPC password | `password` |
`TRANSMISSION_RPC_PORT` | RPC port | `9091` |
`TRANSMISSION_RPC_URL` | RPC url | `/transmission/` |
`TRANSMISSION_RPC_USERNAME` | RPC username | `username` |
`TRANSMISSION_RPC_WHITELIST` | RPC whitelist IPs (comma-separated) | `127.0.0.1` |
`TRANSMISSION_RPC_WHITELIST_ENABLED` | Enable RPC whitelist | `true` |
`TRANSMISSION_ALT_SPEED_TIME_ENABLED` | When enabled, this will toggle the `TRANSMISSION_ALT_SPEED_ENABLED` setting | `false` |
`TRANSMISSION_ALT_SPEED_TIME_BEGIN` | Alt speed begin time, in minutes from midnight (as per default, 9am) | `540` |
`TRANSMISSION_ALT_SPEED_TIME_END` | Alt speed end time, in minutes from midnight (as per default, 5pm) | `1020` |
`TRANSMISSION_ALT_SPEED_TIME_DAY` | When you want scheduler enabled (default is all days) | `127` |
`TRANSMISSION_IDLE_SEEDING_LIMIT` | Stop seeding after being idle for N minutes | `30` |
`TRANSMISSION_IDLE_SEEDING_LIMIT_ENABLED` | Enable idle seeding limit | `false` |
`TRANSMISSION_RATIO_LIMIT` | Ratio limit default 2.0 | `2` |
`TRANSMISSION_RATIO_LIMIT_ENABLED` | Enable ratio limit | `false` |
`TRANSMISSION_HOME` | Home dir for transmission to store the state | `/data/transmission-home` |
`TRANSMISSION_RUNAS_ROOT` | Run transmission as root user | `false` |

