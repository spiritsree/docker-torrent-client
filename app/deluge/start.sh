#!/bin/bash

# export the variables so that this process can access them
# shellcheck disable=SC1091
source /etc/templates/env.sh

# shellcheck source=../scripts/functions.sh
# shellcheck disable=SC1091
source /usr/local/scripts/functions.sh

# This script will be passed with multiple arguments
# start.sh <tunnel-device> <tun-mtu> <link-mtu> <tunnel-ip> <net-mask|remote-ip> <init|restart>

# Start the deluge client after VPN is ready
echo "[DELUGE] Starting deluge client..."
echo "[DELUGE] Received arguments...$*"

tun_device=$1
tun_ip=$4

# Exit if there is no tunnel device
if [[ "${tun_device}" = "" ]]; then
   echo "[DELUGE] ERR: Tunnel IP could not be found !!!"
   kill -9 "${PPID}"
   exit 1
fi

echo "[DELUGE] Setting DELUGE_LISTEN_INTERFACE to ${tun_device} device ip: ${tun_ip}"
export DELUGE_LISTEN_INTERFACE=${tun_ip}
export DELUGE_OUTGOING_INTERFACE=${tun_ip}

# add deluge web credentials to deluge-auth.txt file
echo "[DELUGE] Setting Transmission RPC credentials to /control/transmission-auth.txt..." >> "${LOG_FILE}"
printf '%s\n' "${DELUGE_AUTH_USERNAME}" "${DELUGE_AUTH_PASSWORD}" > /control/deluge-auth.txt
chmod 644 /control/deluge-auth.txt

DELUGE_PWD_SHA1=$(echo -n "${DELUGE_PWD_SALT}${DELUGE_AUTH_PASSWORD}" | sha1sum | awk '{ print $1 }')
export DELUGE_PWD_SHA1

echo "${DELUGE_AUTH_USERNAME}:${DELUGE_AUTH_PASSWORD}:10" > "${DELUGE_HOME}/auth"

echo "[DELUGE] Generating deluge configs from env..."
dockerize -template "/etc/templates/deluge_core.tmpl:${DELUGE_HOME}/core.conf"
dockerize -template "/etc/templates/deluge_web.tmpl:${DELUGE_HOME}/web.conf"
dockerize -template "/etc/templates/deluge_hostlist.tmpl:${DELUGE_HOME}/hostlist.conf"

_perm_update "${DELUGE_HOME}" "${TOR_CLIENT_USER}"

if [[ "${ENABLE_FILE_LOGGING}" == "false" ]]; then
    export DELUGE_OPTS="-c ${DELUGE_HOME} -L ${DELUGE_LOG_LEVEL}"
else
    export DELUGE_OPTS="-c ${DELUGE_HOME} -L ${DELUGE_LOG_LEVEL} -l ${LOG_FILE}"
fi

echo "[DELUGE] Deluge will run as \"${TOR_CLIENT_USER}\" with UID \"${TOR_CLIENT_UID}\" and GID \"${TOR_CLIENT_GID}\""
echo "[DELUGE] Starting deluge daemon..."
exec su -p "${TOR_CLIENT_USER}" -s /bin/bash -c "/usr/bin/deluged ${DELUGE_OPTS}" &
echo "[DELUGE] Starting deluge web..."
while [[ $(netstat -lnt | grep "[L]ISTEN" | grep -c ":${DELUGE_DAEMON_PORT}") -eq 0 ]]; do
    sleep 0.1
done
exec su -p "${TOR_CLIENT_USER}" -s /bin/bash -c "/usr/bin/deluge-web ${DELUGE_OPTS}" &

echo "[DELUGE] Deluge startup completed..."
