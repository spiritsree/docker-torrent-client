#!/bin/bash

# https://openvpn.net/community-resources/reference-manual-for-openvpn-2-0/

VPN_PROVIDER="hideme"
VPN_CONFIG="/etc/openvpn/${VPN_PROVIDER}"
export VPN_CONFIG

if [[ "${CREATE_TUN_DEVICE:-false}" == "true" ]]; then
  echo "Creating a tunnel device /dev/net/tun ..."
  mkdir -p /dev/net
  mknod --mode=0666 /dev/net/tun c 10 200
fi

if [[ ! -d "${VPN_CONFIG}" ]]; then
  echo "Config doesn't exist for provider: ${VPN_PROVIDER}"
  exit 1
fi

# add OpenVPN user/pass
if [[ "${OPENVPN_USERNAME}" == "" ]] || [[ "${OPENVPN_PASSWORD}" == "" ]] ; then
  if [[ ! -f /control/ovpn-auth.txt ]] ; then
    echo "OpenVPN username and password empty..."
    exit 1
  fi
  echo "OPENVPN credentials found in /control/ovpn-auth.txt ..."
else
  echo "Setting OPENVPN credentials..."
  mkdir -p /control
  echo "${OPENVPN_USERNAME}" > /control/ovpn-auth.txt
  echo "${OPENVPN_PASSWORD}" >> /control/ovpn-auth.txt
  chmod 600 /control/ovpn-auth.txt
fi

TRANSMISSION_CONTROL_OPTS="--script-security 2 --up-delay --up /etc/openvpn/startTorrent.sh --down /etc/openvpn/stopTorrent.sh"

exec openvpn ${TRANSMISSION_CONTROL_OPTS} --config "${VPN_CONFIG}/default.ovpn"
