#!/bin/bash

# https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/

# https://www.tldp.org/LDP/abs/html/abs-guide.html#CASEMODPARAMSUB
VPN_PROVIDER="${OPENVPN_PROVIDER,,}"

VPN_CONFIG="/etc/openvpn/${VPN_PROVIDER}"
export VPN_CONFIG

if [[ "${ENABLE_FILE_LOGGING}" == "false" ]]; then
    export LOG_FILE="/proc/self/fd/1"
fi

if [[ "${CREATE_TUN_DEVICE:-false}" == "true" ]]; then
  echo "Creating tunnel device /dev/net/tun ..." >> ${LOG_FILE}
  mkdir -p /dev/net
  mknod -m 0666 /dev/net/tun c 10 200
fi

# Exit if OpenVPN Provider or Config doesn't exist
if [[ "${OPENVPN_PROVIDER}" == "None" ]] || [[ -z "${OPENVPN_PROVIDER-}" ]]; then
  echo "OPENVPN_PROVIDER not set. Exiting." >> ${LOG_FILE}
  exit 1
elif [[ ! -d "${VPN_CONFIG}" ]]; then
  echo "Config doesn't exist for provider: ${OPENVPN_PROVIDER}" >> ${LOG_FILE}
  exit 1
fi

echo "Using OpenVPN provider ${OPENVPN_PROVIDER}" >> ${LOG_FILE}

# add OpenVPN user/pass to the auth-user-pass file
if [[ "${OPENVPN_USERNAME}" == "NONE" ]] || [[ "${OPENVPN_PASSWORD}" == "NONE" ]] ; then
  if [[ ! -f /control/ovpn-auth.txt ]] ; then
    echo "OpenVPN username and password empty..." >> ${LOG_FILE}
    exit 1
  fi
  echo "OPENVPN credentials found in /control/ovpn-auth.txt ..." >> ${LOG_FILE}
else
  echo "Setting OPENVPN credentials..." >> ${LOG_FILE}
  mkdir -p /control
  printf '%s\n' "${OPENVPN_USERNAME}" "${OPENVPN_PASSWORD}" > /control/ovpn-auth.txt
  chmod 600 /control/ovpn-auth.txt
fi

if [[ "${OPENVPN_HOSTNAME}" == "None" ]] || [[ -z "${OPENVPN_HOSTNAME}" ]]; then
  echo "OPENVPN_PROVIDER not set. Exiting." >> ${LOG_FILE}
  exit 1
fi

# Expand the OpenVPN Config
dockerize -template ${VPN_CONFIG}/default.ovpn.tmpl:${VPN_CONFIG}/default.ovpn

# Transmission control options
TRANSMISSION_CONTROL_OPTS="--script-security 2 --up-delay --up /etc/openvpn/startTorrent.sh --down /etc/openvpn/stopTorrent.sh"

# Allow Local network
if [[ -n "${LOCAL_NETWORK-}" ]]; then
  if [[ "${TRANSMISSION_RPC_WHITELIST_ENABLED}" == "true" ]]; then
    local_ip=$(echo ${LOCAL_NETWORK} | awk -F'/' '{ print $1 }')
    local_gateway=$(ip route show default | awk '{ print $3 }')
    echo "Adding local IP ${local_ip}, ${local_gateway} to TRANSMISSION_RPC_WHITELIST" >> ${LOG_FILE}
    TRANSMISSION_RPC_WHITELIST="${TRANSMISSION_RPC_WHITELIST},${local_ip},${local_gateway}"
    export TRANSMISSION_RPC_WHITELIST
  fi
fi

# Transmission will be opened as a new process. Need to export the variables, so that
# transmission start script can access them.
dockerize -template /etc/transmission/env.tmpl:/etc/transmission/env.sh
env | grep 'TRANSMISSION' | sed 's/^/export /g' >> /etc/transmission/env.sh

# start openvpn
exec openvpn ${TRANSMISSION_CONTROL_OPTS} ${OPENVPN_OPTS} --config "${VPN_CONFIG}/default.ovpn" --suppress-timestamps --log-append ${LOG_FILE}
