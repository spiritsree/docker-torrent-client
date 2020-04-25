#!/bin/bash

# export the variables so that this process can access them
# shellcheck disable=SC1091
source /etc/templates/env.sh

# Stop the transmission client
echo "[TRANSMISSION] Stopping transmission client..."
if [[ "${TRANSMISSION_RPC_AUTHENTICATION_REQUIRED}" == "true" ]]; then
    /usr/bin/transmission-remote -n "${TRANSMISSION_RPC_USERNAME}:${TRANSMISSION_RPC_PASSWORD}" --exit > /dev/null
else
    /usr/bin/transmission-remote --exit > /dev/null
fi

sleep 10
pkill transmission-daemon

transmission_pid=$(pidof transmission-daemon)
if [[ -n "${transmission_pid}" ]]; then
    kill "${transmission_pid}"
fi

echo "[TRANSMISSION] Transmission shutdown completed..."
