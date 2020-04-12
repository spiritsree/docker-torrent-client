#!/bin/bash

# export the variables so that this process can access them
# shellcheck disable=SC1091
source /etc/transmission/env.sh

# shellcheck source=functions.sh
# shellcheck disable=SC1091
source /etc/transmission/functions.sh

# This scrip will be passed with multiple arguments
# start.sh <tunnel-device> <tun-mtu> <link-mtu> <tunnel-ip> <net-mask|remote-ip> <init|restart>

# Create a non privileged user if not root
if [[ "${TRANSMISSION_RUNAS_ROOT}" == "false" ]]; then
    TRANSMISSION_USER='jedi'
else
    TRANSMISSION_USER='root'
fi

TRANSMISSION_UID=$(id -u "${TRANSMISSION_USER}")
TRANSMISSION_GID=$(id -g "${TRANSMISSION_USER}")
export TRANSMISSION_USER
export TRANSMISSION_UID
export TRANSMISSION_GID

# Create the directories if not
_create_dir_perm "${TRANSMISSION_HOME}" "${TRANSMISSION_USER}"
_create_dir_perm "${TRANSMISSION_WATCH_DIR}" "${TRANSMISSION_USER}"
_create_dir_perm "${TRANSMISSION_INCOMPLETE_DIR}" "${TRANSMISSION_USER}"
_create_dir_perm "${TRANSMISSION_DOWNLOAD_DIR}" "${TRANSMISSION_USER}"

# Start the transmission client after VPN is ready
echo "[TRANSMISSION] Starting transmission client..."
echo "[TRANSMISSION] Received arguments...$*"

tun_device=$1
tun_ip=$4

if [[ "${tun_device}" = "" ]]; then
   echo "[TRANSMISSION] ERR: Tunnel IP could not be found !!!"
   kill -9 "${PPID}"
   exit 1
fi

echo "[TRANSMISSION] Setting TRANSMISSION_BIND_ADDRESS_IPV4 to ${tun_device} device ip: ${tun_ip}"
export TRANSMISSION_BIND_ADDRESS_IPV4=${tun_ip}

echo "[TRANSMISSION] Generating settings.json from env variables..."
# Settings are from https://github.com/transmission/transmission/wiki/Editing-Configuration-Files
# For details about the settings refer the url
dockerize -template "/etc/transmission/settings.tmpl:${TRANSMISSION_HOME}/settings.json"

_perm_update "${TRANSMISSION_HOME}" "${TRANSMISSION_USER}"

echo "[TRANSMISSION] Transmission will run as \"${TRANSMISSION_USER}\" with UID \"${TRANSMISSION_UID}\" and GID \"${TRANSMISSION_GID}\""
exec su --preserve-environment ${TRANSMISSION_USER} -s /bin/bash -c "/usr/bin/transmission-daemon -g ${TRANSMISSION_HOME} --logfile ${LOG_FILE}" &

