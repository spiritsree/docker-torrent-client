#!/bin/bash

# shellcheck source=../scripts/functions.sh
# shellcheck disable=SC1091
source /usr/local/scripts/functions.sh

# https://www.tldp.org/LDP/abs/html/abs-guide.html#CASEMODPARAMSUB
VPN_PROVIDER="${OPENVPN_PROVIDER,,}"

export OPENVPN_CONFIG="/etc/openvpn"
export OPENVPN_TEMPLATE="/etc/templates/openvpn/${VPN_PROVIDER}"
export OPENVPN_AUTH_FILE="/control/ovpn-auth.txt"

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

# CheckConfig: exit if OpenVPN Provider or Config doesn't exist
if [[ "${OPENVPN_PROVIDER}" == "NONE" ]] || [[ -z "${OPENVPN_PROVIDER-}" ]]; then
    echo "[OPENVPN] OPENVPN_PROVIDER not set..." >> ${LOG_FILE}
    echo "[OPENVPN] Exiting..." >> ${LOG_FILE}
    exit 1
elif [[ "${VPN_PROVIDER}" == "custom" ]]; then
    if [[ ! -f "/custom/default.ovpn" ]]; then
        echo "[OPENVPN] Config /custom/default.ovpn not found..." >> ${LOG_FILE}
        echo "[OPENVPN] Exiting..." >> ${LOG_FILE}
        exit 1
    else
        OPENVPN_CONFIG="/custom"
    fi
elif [[ ! -d "${OPENVPN_TEMPLATE}" ]]; then
    echo "[OPENVPN] Config doesn't exist for provider: ${OPENVPN_PROVIDER}" >> ${LOG_FILE}
    echo "[OPENVPN] Exiting..." >> ${LOG_FILE}
    exit 1
fi

echo "[OPENVPN] Using OpenVPN provider ${OPENVPN_PROVIDER}..." >> ${LOG_FILE}
echo "[OPENVPN] Using OpenVPN config ${OPENVPN_CONFIG}/default.ovpn..." >> ${LOG_FILE}

# CheckAuth: add OpenVPN user/pass verification and update auth-user-pass file
if [[ "${OPENVPN_USERNAME}" == "NONE" ]] || [[ "${OPENVPN_PASSWORD}" == "NONE" ]] ; then
    if [[ -f "${OPENVPN_AUTH_FILE}" ]] ; then
        echo "[OPENVPN] Credentials file found at ${OPENVPN_AUTH_FILE} ..." >> ${LOG_FILE}
    elif [[ "${VPN_PROVIDER}" == "custom" ]] ; then
        if [[ -f "${OPENVPN_CONFIG}/ovpn-auth.txt" ]] ; then
            echo "[OPENVPN] Credentials file found at ${OPENVPN_CONFIG}/ovpn-auth.txt ..." >> ${LOG_FILE}
            export OPENVPN_AUTH_FILE="${OPENVPN_CONFIG}/ovpn-auth.txt"
        else
            echo "[OPENVPN] Credentials file not found at ${OPENVPN_CONFIG}/ovpn-auth.txt..." >> ${LOG_FILE}
            echo "[OPENVPN] Exiting..." >> ${LOG_FILE}
            exit 1
        fi
    else
        {
        echo "[OPENVPN] Credentials file not found at ${OPENVPN_AUTH_FILE}..."
        echo "[OPENVPN] username and password not provided..."
        echo "[OPENVPN] Exiting..."
        } >> ${LOG_FILE}
        exit 1
    fi
else
    echo "[OPENVPN] Setting credentials in ${OPENVPN_AUTH_FILE}..." >> ${LOG_FILE}
    mkdir -p /control
    printf '%s\n' "${OPENVPN_USERNAME}" "${OPENVPN_PASSWORD}" > "${OPENVPN_AUTH_FILE}"
fi

# Authfile permission user access
chmod 600 "${OPENVPN_AUTH_FILE}"

# Check if custom config auth file exist
if [[ "${VPN_PROVIDER}" == "custom" ]] ; then
    custom_auth_file=$(grep 'auth-user-pass' "${OPENVPN_CONFIG}/default.ovpn" | awk '{ print $2 }')
    if [[ -z "${custom_auth_file}" ]]; then
        echo "[OPENVPN] Custom config doesn't have auth config..." >> ${LOG_FILE}
        exit 1
    elif [[ ! -f "${custom_auth_file}" ]]; then
        echo "[OPENVPN] Custom config auth file doesn't exist..." >> ${LOG_FILE}
        exit 1
    fi
fi

# CheckHostname: validating OPENVPN_HOSTNAME
if [[ "${OPENVPN_HOSTNAME}" == "NONE" ]] || [[ -z "${OPENVPN_HOSTNAME}" ]]; then
    # Getting OPENVPN_CONNECTION from OPENVPN_CONNECTION
    if [[ "${OPENVPN_CONNECTION}" == "NONE" ]] || [[ -z "${OPENVPN_CONNECTION}" ]]; then
        # Ignore OPENVPN_CONNECTION and OPENVPN_HOSTNAME if provider is custom
        if [[ "${VPN_PROVIDER}" == "custom" ]] ; then
            echo "[OPENVPN] Provider is ${VPN_PROVIDER}, not using OPENVPN_HOSTNAME and OPENVPN_CONNECTION..." >> ${LOG_FILE}
        else
            {
            echo "[OPENVPN] Both OPENVPN_HOSTNAME and OPENVPN_CONNECTION not set..."
            echo "[OPENVPN] Either one of the setting is required..."
            echo "[OPENVPN] Exiting..."
            } >> ${LOG_FILE}
            exit 1
        fi
    else
        OPENVPN_HOSTNAME="${OPENVPN_CONNECTION%%:*}"
        OPENVPN_PROTO=$(_lowercase "${OPENVPN_CONNECTION##*:}")
        # Get IP if Hostname is not IP
        # grep -E -o "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        if ! echo "${OPENVPN_HOSTNAME// /}" | grep -E -o '^[0-9][0-9\.]+[0-9]$' > /dev/null; then
            OPENVPN_HOSTNAME_IP=$(dig +short "${OPENVPN_HOSTNAME}" | grep -v '\.$' | tail -1)
            OPENVPN_HOSTNAME_PREFIX=$(echo "${OPENVPN_HOSTNAME}" | awk -F'.' '{ print $1 }')
            export OPENVPN_HOSTNAME_PREFIX
        else
            OPENVPN_HOSTNAME_IP="${OPENVPN_HOSTNAME}"
        fi
        export OPENVPN_HOSTNAME_IP
    fi
fi

# Use IP if NordVPN
if [[ "${VPN_PROVIDER}" == "nordvpn" ]] ; then
    OPENVPN_HOSTNAME="${OPENVPN_HOSTNAME_IP}"
fi

# Expand the OpenVPN Config if not custom provider
if [[ "${VPN_PROVIDER}" != "custom" ]] ; then
    ovpn_template="${OPENVPN_TEMPLATE}/${OPENVPN_PROTO}/default.ovpn.tmpl"

    if [[ -f "${ovpn_template}" ]]; then
        echo "[OPENVPN] Expanding template ${ovpn_template}..." >> ${LOG_FILE}
        dockerize -template "${ovpn_template}:${OPENVPN_CONFIG}/default.ovpn"
    else
        echo "[OPENVPN] Template ${ovpn_template} not found..." >> ${LOG_FILE}
        echo "[OPENVPN] Protocol may not be supported..." >> ${LOG_FILE}
        exit 1
    fi
fi

# Get default gateway
_get_default_gw

# Reset the env variables from client config
if [[ "${TOR_CLIENT,,}" == "transmission" ]] && [[ "${TOR_CLIENT_ENABLED,,}" == "true" ]]; then
    echo "[CLIENT] Selected torrent client is transmission..." >> ${LOG_FILE}
    if [[ -f "${TRANSMISSION_HOME}/settings.json" ]] && [[ "${TOR_CLIENT_SETTING_DEFAULT,,}" == "false" ]]; then
        echo "[TRANSMISSION] Transmission will preserve the config..." >> ${LOG_FILE}
        _get_settings "transmission" "${TRANSMISSION_HOME}/settings.json"
    else
        echo "[TRANSMISSION] Transmission will use default config..." >> ${LOG_FILE}
        dockerize -template "/etc/templates/transmission_settings.tmpl:/tmp/settings.json"
        _get_settings "transmission" "/tmp/settings.json"
    fi

    if [[ "${TRANSMISSION_PEER_PORT_RANDOM_ON_START,,}" == "true" ]]; then
        export TOR_PEER_PORT="${TRANSMISSION_PEER_PORT_RANDOM_LOW}:${TRANSMISSION_PEER_PORT_RANDOM_HIGH}"
    else
        export TOR_PEER_PORT="${TRANSMISSION_PEER_PORT}"
    fi

    if [[ -n "${LOCAL_NETWORK-}" ]] && [[ -n "${DEF_GW-}" ]]; then
        if [[ "${TRANSMISSION_RPC_WHITELIST_ENABLED}" == "true" ]]; then
            echo "[ROUTE] Adding default gateway IP ${DEF_GW} to Transmission RPC whitelist" >> ${LOG_FILE}
            export TRANSMISSION_RPC_WHITELIST="${TRANSMISSION_RPC_WHITELIST},${DEF_GW}"
        fi
    fi
elif [[ "${TOR_CLIENT,,}" == "deluge" ]] && [[ "${TOR_CLIENT_ENABLED,,}" == "true" ]]; then
    echo "[CLIENT] Selected torrent client is deluge..." >> ${LOG_FILE}
    if [[ -f "${DELUGE_HOME}/core.conf" ]] && [[ "${TOR_CLIENT_SETTING_DEFAULT,,}" == "false" ]]; then
        echo "[DELUGE] Deluge will preserve the config..." >> ${LOG_FILE}
        _get_settings "deluge" "${DELUGE_HOME}/core.conf"
        _get_settings "deluge" "${DELUGE_HOME}/web.conf"
    else
        echo "[DELUGE] Deluge will use default config..." >> ${LOG_FILE}
        dockerize -template "/etc/templates/deluge_core.tmpl:/tmp/core.conf"
        dockerize -template "/etc/templates/deluge_web.tmpl:/tmp/web.conf"
        _get_settings "deluge" "/tmp/core.conf"
        _get_settings "deluge" "/tmp/web.conf"
    fi

    if [[ "${DELUGE_RANDOM_PORT,,}" == "true" ]]; then
        export DELUGE_PEER_LISTEN_PORTS="${DELUGE_PEER_PORT_RANDOM_LOW},${DELUGE_PEER_PORT_RANDOM_HIGH}"
        export TOR_PEER_PORT="${DELUGE_PEER_PORT_RANDOM_LOW}:${DELUGE_PEER_PORT_RANDOM_HIGH}"
        # DELUGE_RANDOM_PEER_PORT=$(python3 -S -c "import random; print(random.randrange(${DELUGE_PEER_PORT_RANDOM_LOW},${DELUGE_PEER_PORT_RANDOM_HIGH}))"
        DELUGE_RANDOM_PEER_PORT=$(shuf -i "${DELUGE_PEER_PORT_RANDOM_LOW}-${DELUGE_PEER_PORT_RANDOM_HIGH}" -n 1)
        export DELUGE_RANDOM_PEER_PORT
    else
        export DELUGE_PEER_LISTEN_PORTS="${DELUGE_PEER_PORT},${DELUGE_PEER_PORT}"
        export TOR_PEER_PORT="${DELUGE_PEER_PORT}"
    fi

    if [[ "${DELUGE_RANDOM_OUTGOING_PORTS,,}" == "true" ]]; then
        export DELUGE_PEER_OUTGOING_PORTS="${DELUGE_PEER_PORT_RANDOM_LOW},${DELUGE_PEER_PORT_RANDOM_HIGH}"
    else
        export DELUGE_PEER_OUTGOING_PORTS="${DELUGE_PEER_PORT_OUT},${DELUGE_PEER_PORT_OUT}"
    fi

    if [[ "${DELUGE_ALLOW_REMOTE,,}" == "true" ]]; then
        if [[ -n "${FIREWALL_PORTS_TO_ALLOW-}" ]]; then
            export FIREWALL_PORTS_TO_ALLOW="${FIREWALL_PORTS_TO_ALLOW},${DELUGE_DAEMON_PORT}"
        else
            export FIREWALL_PORTS_TO_ALLOW="${DELUGE_DAEMON_PORT}"
        fi
    fi
fi

# Enable firewall
if [[ "${FIREWALL_ENABLED,,}" == "true" ]]; then
    echo "[FIREWALL] Enabling firewall..." >> ${LOG_FILE}
    sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw
    ufw enable > /dev/null

    # Allow client peer port
    echo "[FIREWALL] Allowing torrent peer port ${TOR_PEER_PORT}..." >> ${LOG_FILE}
    _firewall_allow_port "${TOR_PEER_PORT}" >> ${LOG_FILE}

    # Allow webproxy port if enabled
    if [[ "${WEBPROXY_ENABLED,,}" == "true" ]]; then
        echo "[FIREWALL] Allowing webproxy port ${WEBPROXY_PORT}..." >> ${LOG_FILE}
        _firewall_allow_port "${WEBPROXY_PORT}" >> ${LOG_FILE}
    fi

    # Allow client RPC port from gateway
    if [[ -n "${TOR_RPC_PORT-}" ]]; then
        if [[ "${FIREWALL_ALLOW_GW_CIDR,,}" == "true" ]]; then
            [[ -n "${DEF_GW_CIDR-}" ]] && _firewall_allow_port "${TOR_RPC_PORT}" "${DEF_GW_CIDR}" >> ${LOG_FILE}
        else
            [[ -n "${DEF_GW-}" ]] && _firewall_allow_port "${TOR_RPC_PORT}" "${DEF_GW}" >> ${LOG_FILE}
        fi
    fi

    # Allow ports from FIREWALL_PORTS_TO_ALLOW and any additional port from clients
    if [[ -n "${FIREWALL_PORTS_TO_ALLOW-}" ]]; then
        for each_port in ${FIREWALL_PORTS_TO_ALLOW//,/ }; do
            if [[ "${FIREWALL_ALLOW_GW_CIDR,,}" == "true" ]]; then
                _firewall_allow_port "${each_port}" "${DEF_GW_CIDR}" >> ${LOG_FILE}
            else
                _firewall_allow_port "${each_port}" "${DEF_GW}" >> ${LOG_FILE}
            fi
        done
    fi
fi

# Allow Local network
if [[ -n "${LOCAL_NETWORK-}" ]]; then
    if [[ -n "${DEF_GW-}" ]] && [[ -n "${DEF_INT-}" ]]; then
        for host_network in ${LOCAL_NETWORK//,/ }; do
            echo "[ROUTE] Adding route to host network ${host_network} via ${DEF_GW} dev ${DEF_INT}" >> ${LOG_FILE}
            ip route add "${host_network}" via "${DEF_GW}" dev "${DEF_INT}"
            if [[ "${FIREWALL_ENABLED,,}" == "true" ]]; then
                if [[ -n "${TOR_RPC_PORT-}" ]]; then
                    _firewall_allow_port "${TOR_RPC_PORT}" "${host_network}" >> ${LOG_FILE}
                fi
                if [[ -n "${FIREWALL_PORTS_TO_ALLOW-}" ]]; then
                    for each_port in ${FIREWALL_PORTS_TO_ALLOW//,/ }; do
                        _firewall_allow_port "${each_port}" "${host_network}" >> ${LOG_FILE}
                    done
                fi
            fi
        done
    fi
fi

# Create a non privileged user if not root
if [[ "${TOR_CLIENT_RUNAS_ROOT,,}" == "false" ]]; then
    export TOR_CLIENT_USER='jedi'
else
    export TOR_CLIENT_USER='root'
fi

TOR_CLIENT_UID=$(id -u "${TOR_CLIENT_USER}")
TOR_CLIENT_GID=$(id -g "${TOR_CLIENT_USER}")
export TOR_CLIENT_UID
export TOR_CLIENT_GID

# Torrent Client will be opened as a new process. Need to export the variables,
# so that the process start script can access them.
dockerize -template /etc/templates/env.tmpl:/etc/templates/env.sh
if [[ "${TOR_CLIENT_ENABLED,,}" == "true" ]]; then
    if [[ "${TOR_CLIENT,,}" == "transmission" ]]; then
        export TOR_CLIENT_HOME="${TRANSMISSION_HOME}"
        env | grep 'TRANSMISSION' | sed 's/^/export /g' >> /etc/templates/env.sh
    elif [[ "${TOR_CLIENT,,}" == "deluge" ]]; then
        export TOR_CLIENT_HOME="${DELUGE_HOME}"
        env | grep 'DELUGE' | sed 's/^/export /g' >> /etc/templates/env.sh
    fi

    # Create the directories if not
    {
    _create_dir_perm "${TOR_CLIENT_HOME}" "${TOR_CLIENT_USER}";
    _create_dir_perm "${TOR_WATCH_DIR}" "${TOR_CLIENT_USER}";
    _create_dir_perm "${TOR_INCOMPLETE_DIR}" "${TOR_CLIENT_USER}";
    _create_dir_perm "${TOR_DOWNLOAD_DIR}" "${TOR_CLIENT_USER}";
    } >> ${LOG_FILE}
fi

# Options to OpenVPN for starting and stopping torrent client
TOR_CONTROL_OPTS="--script-security 2 --up-delay --up /etc/openvpn/startTorrent.sh --down /etc/openvpn/stopTorrent.sh"

# start openvpn
# https://openvpn.net/community-resources/reference-manual-for-openvpn-2-4/
# shellcheck disable=SC2086
exec openvpn ${TOR_CONTROL_OPTS} ${OPENVPN_OPTS} --config "${OPENVPN_CONFIG}/default.ovpn" --log-append ${LOG_FILE}
