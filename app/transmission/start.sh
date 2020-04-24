#!/bin/bash

# export the variables so that this process can access them
# shellcheck disable=SC1091
source /etc/templates/env.sh

# shellcheck source=../scripts/functions.sh
# shellcheck disable=SC1091
source /usr/local/scripts/functions.sh

# This script will be passed with multiple arguments
# start.sh <tunnel-device> <tun-mtu> <link-mtu> <tunnel-ip> <net-mask|remote-ip> <init|restart>

# Start the transmission client after VPN is ready
echo "[TRANSMISSION] Starting transmission client..."
echo "[TRANSMISSION] Received arguments...$*"

tun_device=$1
tun_ip=$4

# Exit if there is no tunnel device
if [[ "${tun_device}" = "" ]]; then
   echo "[TRANSMISSION] ERR: Tunnel IP could not be found !!!"
   kill -9 "${PPID}"
   exit 1
fi

echo "[TRANSMISSION] Setting TRANSMISSION_BIND_ADDRESS_IPV4 to ${tun_device} device ip: ${tun_ip}"
export TRANSMISSION_BIND_ADDRESS_IPV4=${tun_ip}

# add transmission credentials to transmission-auth.txt file
if [[ "${TRANSMISSION_RPC_AUTHENTICATION_REQUIRED}" == "true" ]]; then
    echo "[TRANSMISSION] Setting Transmission RPC credentials to /control/transmission-auth.txt..." >> "${LOG_FILE}"
    printf '%s\n' "${TRANSMISSION_RPC_USERNAME}" "${TRANSMISSION_RPC_PASSWORD}" > /control/transmission-auth.txt
    chmod 644 /control/transmission-auth.txt
fi

# Transmission custom UI
if [[ "${TRANSMISSION_WEB_UI,,}" == "combustion" ]]; then
    echo "[TRANSMISSION] Using Combustion as the Web UI"
    export TRANSMISSION_WEB_UI="combustion"
    export TRANSMISSION_WEB_HOME="/usr/share/transmission-ui/combustion"
elif [[ "${TRANSMISSION_WEB_UI,,}" == "transmission-web-control" ]]; then
    echo "[TRANSMISSION] Using Transmission Web Control as the Web UI"
    export TRANSMISSION_WEB_UI="transmission-web-control"
    export TRANSMISSION_WEB_HOME="/usr/share/transmission-ui/transmission-web-control"
else
    export TRANSMISSION_WEB_UI="default"
    export TRANSMISSION_WEB_HOME="/usr/share/transmission/web"
fi

echo "[TRANSMISSION] Generating settings.json from env variables..."
# Settings are from https://github.com/transmission/transmission/wiki/Editing-Configuration-Files
# For details about the settings refer the url
dockerize -template "/etc/templates/transmission_settings.tmpl:${TRANSMISSION_HOME}/settings.json"

_perm_update "${TRANSMISSION_HOME}" "${TOR_CLIENT_USER}"

if [[ "${TRANSMISSION_LOG_LEVEL,,}" == "info" ]]; then
    export TRANSMISSION_LOG_OPTS="--log-info"
elif [[ "${TRANSMISSION_LOG_LEVEL,,}" == "debug" ]]; then
    export TRANSMISSION_LOG_OPTS="--log-debug"
fi

if [[ "${ENABLE_FILE_LOGGING}" == "false" ]]; then
    export TRANSMISSION_OPTS="-g ${TRANSMISSION_HOME} ${TRANSMISSION_LOG_OPTS} --foreground"
else
    export TRANSMISSION_OPTS="-g ${TRANSMISSION_HOME} ${TRANSMISSION_LOG_OPTS} --logfile ${LOG_FILE}"
fi

echo "[TRANSMISSION] Transmission will run as \"${TOR_CLIENT_USER}\" with UID \"${TOR_CLIENT_UID}\" and GID \"${TOR_CLIENT_GID}\""
exec su -p "${TOR_CLIENT_USER}" -s /bin/bash -c "/usr/bin/transmission-daemon ${TRANSMISSION_OPTS}" &

echo "[TRANSMISSION] Transmission startup completed..."
