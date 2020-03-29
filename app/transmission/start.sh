#!/bin/bash

# This scrip will be passed with multiple arguments
# start.sh <tunnel-device> <tun-mtu> <link-mtu> <tunnel-ip> <net-mask|remote-ip> <init|restart>

# Start the transmission client after VPN is ready
echo "Starting transmission client..."
echo "Received arguments...$*"

tun_device=$1
tun_ip=$4

if [[ "${tun_device}" = "" ]]; then
   echo "ERR: Tunnel IP could not be found !!!"
   kill -9 "${PPID}"
   exit 1
fi

echo "Setting TRANSMISSION_BIND_ADDRESS_IPV4 to ${tun_device} device ip"
export TRANSMISSION_BIND_ADDRESS_IPV4=${tun_ip}

exec /usr/bin/transmission-daemon --bind-address-ipv4 ${TRANSMISSION_BIND_ADDRESS_IPV4} --download-dir "/data/completed" --incomplete-dir "/data/incomplete" --watch-dir "/data/watch" --logfile "/data/transmission.log" &
