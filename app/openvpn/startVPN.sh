#!/bin/bash

# shellcheck source=functions.sh
# shellcheck disable=SC1091
source /etc/openvpn/functions.sh

# https://www.tldp.org/LDP/abs/html/abs-guide.html#CASEMODPARAMSUB
VPN_PROVIDER="${OPENVPN_PROVIDER,,}"

export VPN_CONFIG="/etc/openvpn/${VPN_PROVIDER}"

if [[ "${ENABLE_FILE_LOGGING}" == "false" ]]; then
    export LOG_FILE="/proc/self/fd/1"
else
    touch "${LOG_FILE}"
    chmod 666 "${LOG_FILE}"
fi

if [[ "${CREATE_TUN_DEVICE:-false}" == "true" ]]; then
    echo "[OPENVPN] Creating tunnel device /dev/net/tun ..." >> ${LOG_FILE}
    mkdir -p /dev/net
    mknod -m 0666 /dev/net/tun c 10 200
fi

# Exit if OpenVPN Provider or Config doesn't exist
if [[ "${OPENVPN_PROVIDER}" == "None" ]] || [[ -z "${OPENVPN_PROVIDER-}" ]]; then
    echo "[OPENVPN} OPENVPN_PROVIDER not set. Exiting." >> ${LOG_FILE}
    exit 1
elif [[ ! -d "${VPN_CONFIG}" ]]; then
    echo "[OPENVPN] Config doesn't exist for provider: ${OPENVPN_PROVIDER}" >> ${LOG_FILE}
    exit 1
fi

echo "[OPENVPN] Using OpenVPN provider ${OPENVPN_PROVIDER}" >> ${LOG_FILE}

# add OpenVPN user/pass to the auth-user-pass file
if [[ "${OPENVPN_USERNAME}" == "NONE" ]] || [[ "${OPENVPN_PASSWORD}" == "NONE" ]] ; then
    if [[ ! -f /control/ovpn-auth.txt ]] ; then
        echo "[OPENVPN] OpenVPN username and password empty..." >> ${LOG_FILE}
        exit 1
    fi
    echo "[OPENVPN] OPENVPN credentials found in /control/ovpn-auth.txt ..." >> ${LOG_FILE}
else
    echo "[OPENVPN] Setting OPENVPN credentials..." >> ${LOG_FILE}
    mkdir -p /control
    printf '%s\n' "${OPENVPN_USERNAME}" "${OPENVPN_PASSWORD}" > /control/ovpn-auth.txt
    chmod 600 /control/ovpn-auth.txt
fi

# Reset the env variables from settings.json
if [[ -f "${TRANSMISSION_HOME}/settings.json" ]] && [[ "${TRANSMISSION_SETTING_DEFAULT}" == "false" ]]; then
    echo "[TRANSMISSION] Transmission will use previous config..." >> ${LOG_FILE}
    _get_settings "${TRANSMISSION_HOME}/settings.json"
else
    echo "[TRANSMISSION] Transmission will use default config..." >> ${LOG_FILE}
    dockerize -template "/etc/transmission/settings.tmpl:/tmp/settings.json"
    _get_settings "/tmp/settings.json"
fi

# add transmission credentials to transmission-auth.txt file
if [[ "${TRANSMISSION_RPC_AUTHENTICATION_REQUIRED}" == "true" ]]; then
    echo "[OPENVPN] Setting Transmission RPC credentials..." >> ${LOG_FILE}
    printf '%s\n' "${TRANSMISSION_RPC_USERNAME}" "${TRANSMISSION_RPC_PASSWORD}" > /control/transmission-auth.txt
    chmod 644 /control/transmission-auth.txt
fi

if [[ "${OPENVPN_HOSTNAME}" == "None" ]] || [[ -z "${OPENVPN_HOSTNAME}" ]]; then
    echo "[OPENVPN] OPENVPN_HOSTNAME not set. Using OPENVPN_CONNECTION instead..." >> ${LOG_FILE}
    if [[ "${OPENVPN_CONNECTION}" == "None" ]] || [[ -z "${OPENVPN_CONNECTION}" ]]; then
        echo "[OPENVPN] OPENVPN_PROVIDER not set. Exiting." >> ${LOG_FILE}
        exit 1
    else
        OPENVPN_HOSTNAME="${OPENVPN_CONNECTION%%:*}"
        OPENVPN_PROTO=$(_lowercase "${OPENVPN_CONNECTION##*:}")
    fi
fi

vpn_config_template="${VPN_CONFIG}/${OPENVPN_PROTO}/default.ovpn.tmpl"

# Expand the OpenVPN Config
if [[ -f "${vpn_config_template}" ]]; then
    echo "[OPENVPN] Expanding template ${vpn_config_template}..." >> ${LOG_FILE}
    dockerize -template "${vpn_config_template}:${VPN_CONFIG}/default.ovpn"
else
    echo "[OPENVPN] Template ${vpn_config_template} not found..." >> ${LOG_FILE}
    echo "[OPENVPN] Protocol may not be supported..." >> ${LOG_FILE}
    exit 1
fi

# Transmission control options
TRANSMISSION_CONTROL_OPTS="--script-security 2 --up-delay --up /etc/openvpn/startTorrent.sh --down /etc/openvpn/stopTorrent.sh"

if [[ "${TRANSMISSION_PEER_PORT_RANDOM_ON_START,,}" == "true" ]]; then
    export TRANSMISSION_ALLOW_PORT="${TRANSMISSION_PEER_PORT_RANDOM_LOW}:${TRANSMISSION_PEER_PORT_RANDOM_HIGH}"
else
    export TRANSMISSION_ALLOW_PORT="${TRANSMISSION_PEER_PORT}"
fi

# Get default gateway
_get_default_gw

if [[ "${FIREWALL_ENABLED,,}" == "true" ]]; then
    echo "[FIREWALL] Enabling firewall..." >> ${LOG_FILE}
    sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw
    ufw enable > /dev/null

    # Allow transmission peer port
    echo "[FIREWALL] Allowing transmission peer port ${TRANSMISSION_ALLOW_PORT}..." >> ${LOG_FILE}
    _firewall_allow_port "${TRANSMISSION_ALLOW_PORT}" >> ${LOG_FILE}

    # Allow transmission RPC port from gateway
    if [[ -n "${def_gateway-}" ]] && [[ "${TRANSMISSION_RPC_ENABLED}" == "true" ]]; then
        _firewall_allow_port "${TRANSMISSION_RPC_PORT}" "${def_gateway}" >> ${LOG_FILE}
    fi
fi

# Allow Local network
if [[ -n "${LOCAL_NETWORK-}" ]]; then
    if [[ "${TRANSMISSION_RPC_WHITELIST_ENABLED}" == "true" ]] && [[ -n "${def_gateway-}" ]]; then
        echo "[ROUTE] Adding default gateway IP ${def_gateway} to TRANSMISSION_RPC_WHITELIST" >> ${LOG_FILE}
        export TRANSMISSION_RPC_WHITELIST="${TRANSMISSION_RPC_WHITELIST},${def_gateway}"
    fi

    if [[ -n "${def_gateway-}" ]] && [[ -n "${def_interface-}" ]]; then
        for host_network in ${LOCAL_NETWORK//,/ }; do
            echo "[ROUTE] Adding route to host network ${host_network} via ${def_gateway} dev ${def_interface}" >> ${LOG_FILE}
            ip route add "${host_network}" via "${def_gateway}" dev "${def_interface}"
            if [[ "${FIREWALL_ENABLED,,}" == "true" ]]; then
                if [[ "${TRANSMISSION_RPC_ENABLED}" == "true" ]]; then
                    _firewall_allow_port "${TRANSMISSION_RPC_PORT}" "${host_network}" >> ${LOG_FILE}
                fi
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
