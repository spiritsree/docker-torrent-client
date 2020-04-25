#!/bin/bash

# export the variables so that this process can access them
# shellcheck disable=SC1091
source /etc/templates/env.sh

# Stop the deluge client
echo "[DELUGE] Stopping deluge client..."
/usr/bin/deluge-console -U "${DELUGE_AUTH_USERNAME}" -P "${DELUGE_AUTH_PASSWORD}" exit > /dev/null
sleep 10

pkill deluge-web
pkill deluged

deluged_pid=$(pidof deluged)
deluge_web_pid=$(pidof deluge-web)
if [[ -n "${deluged_pid}" ]]; then
    kill "${deluged_pid}"
fi
if [[ -n "${deluge_web_pid}" ]]; then
    kill "${deluge_web_pid}"
fi

echo "[DELUGE] Deluge shutdown completed..."
