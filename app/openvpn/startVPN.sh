#!/bin/bash

# shellcheck source=functions.sh
# shellcheck disable=SC1091
source /etc/openvpn/functions.sh

# https://www.tldp.org/LDP/abs/html/abs-guide.html#CASEMODPARAMSUB
VPN_PROVIDER="${OPENVPN_PROVIDER,,}"

VPN_CONFIG="/etc/openvpn/${VPN_PROVIDER}"
export VPN_CONFIG

if [[ "${ENABLE_FILE_LOGGING}" == "false" ]]; then
    export LOG_FILE="/proc/self/fd/1"
else
    touch "${LOG_FILE}"
    chmod 666 "${LOG_FILE}"
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

# add transmission credentials to transmission-auth.txt file
if [[ "${TRANSMISSION_RPC_AUTHENTICATION_REQUIRED}" == "true" ]]; then
    echo "Setting Transmission RPC credentials..." >> ${LOG_FILE}
    printf '%s\n' "${TRANSMISSION_RPC_USERNAME}" "${TRANSMISSION_RPC_PASSWORD}" > /control/transmission-auth.txt
    chmod 644 /control/transmission-auth.txt
fi

if [[ "${OPENVPN_HOSTNAME}" == "None" ]] || [[ -z "${OPENVPN_HOSTNAME}" ]]; then
    echo "OPENVPN_PROVIDER not set. Exiting." >> ${LOG_FILE}
    exit 1
fi

# Expand the OpenVPN Config
dockerize -template "${VPN_CONFIG}/default.ovpn.tmpl:${VPN_CONFIG}/default.ovpn"

# Transmission control options
TRANSMISSION_CONTROL_OPTS="--script-security 2 --up-delay --up /etc/openvpn/startTorrent.sh --down /etc/openvpn/stopTorrent.sh"

if [[ "${TRANSMISSION_PEER_PORT_RANDOM_ON_START,,}" == "true" ]]; then
    TRANSMISSION_ALLOW_PORT="${TRANSMISSION_PEER_PORT_RANDOM_LOW}:${TRANSMISSION_PEER_PORT_RANDOM_HIGH}"
else
    TRANSMISSION_ALLOW_PORT="${TRANSMISSION_PEER_PORT}"
fi
export TRANSMISSION_ALLOW_PORT

if [[ "${FIREWALL_ENABLED,,}" == "true" ]]; then
    echo "Enabling firewall..." >> ${LOG_FILE}
    sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw
    ufw enable

    _firewall_allow_port "${TRANSMISSION_ALLOW_PORT}"
fi

# Get default gateway
_get_default_gw

# Allow Local network
if [[ -n "${LOCAL_NETWORK-}" ]]; then
    if [[ "${TRANSMISSION_RPC_WHITELIST_ENABLED}" == "true" ]] && [[ -n "${def_gateway-}" ]]; then
        echo "Adding default gateway IP ${def_gateway} to TRANSMISSION_RPC_WHITELIST" >> ${LOG_FILE}
        TRANSMISSION_RPC_WHITELIST="${TRANSMISSION_RPC_WHITELIST},${def_gateway}"
        export TRANSMISSION_RPC_WHITELIST
    fi

    if [[ -n "${def_gateway-}" ]] && [[ -n "${def_interface-}" ]]; then
        for host_network in ${LOCAL_NETWORK//,/ }; do
            echo "Adding route to host network ${host_network} via ${def_gateway} dev ${def_interface}" >> ${LOG_FILE}
            ip route add "${host_network}" via "${def_gateway}" dev "${def_interface}"
            if [[ "${FIREWALL_ENABLED,,}" == "true" ]]; then
                _firewall_allow_port "${TRANSMISSION_RPC_PORT}" "${host_network}" >> ${LOG_FILE}
            fi
        done
    fi
fi

# Transmission will be opened as a new process. Need to export the variables, so that
# transmission start script can access them.
dockerize -template /etc/transmission/env.tmpl:/etc/transmission/env.sh
env | grep 'TRANSMISSION' | sed 's/^/export /g' >> /etc/transmission/env.sh

# start openvpn
# https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/
# shellcheck disable=SC2086
exec openvpn ${TRANSMISSION_CONTROL_OPTS} ${OPENVPN_OPTS} --config "${VPN_CONFIG}/default.ovpn" --suppress-timestamps --log-append ${LOG_FILE}
