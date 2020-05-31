#!/bin/bash

# export the variables so that this process can access them
# shellcheck disable=SC1091
source /etc/templates/env.sh

# This script will be passed with multiple arguments
# start.sh <tunnel-device> <tun-mtu> <link-mtu> <tunnel-ip> <net-mask|remote-ip> <init|restart>

# Start the tinyproxy client
echo "[TINYPROXY] Starting tinyproxy..."
echo "[TINYPROXY] Received arguments...$*"
proxy_bind_device=$1
proxy_bind_ip=$4

# Exit if there is no tunnel device
if [[ "${proxy_bind_device}" = "" ]]; then
   echo "[TINYPROXY] ERR: Tunnel IP could not be found !!!"
   kill -9 "${PPID}"
   exit 1
fi

echo "[TINYPROXY] Setting WEBPROXY_BIND_IP to ${proxy_bind_device} device ip: ${proxy_bind_ip}"
export WEBPROXY_BIND_IP=${proxy_bind_ip}

# Set WEBPROXY_AUTH_ENABLED based on user and pass provided
if [[ -n "${WEBPROXY_USER-}" ]] && [[ -n "${WEBPROXY_PASSWORD-}" ]]; then
    export WEBPROXY_AUTH_ENABLED="true"
else
    export WEBPROXY_AUTH_ENABLED="false"
fi

# Expanding tinyproxy config template
if [[ -f "/etc/init.d/tinyproxy" ]]; then
    TINYPROXY_CONFIG=$(grep '^CONFIG=' /etc/init.d/tinyproxy | tr -d ' ' | awk -F'=' '{ print $2 }')
else
    TINYPROXY_CONFIG="/etc/tinyproxy/tinyproxy.conf"
fi
if [[ -f "${TINYPROXY_CONFIG}" ]]; then
    unlink "${TINYPROXY_CONFIG}"
fi
echo "[TINYPROXY] Generating tinyproxy.conf from env variables..."
dockerize -template "/etc/templates/tinyproxy.tmpl:${TINYPROXY_CONFIG}"

tinyproxy_bin=$(command -v tinyproxy)
if [[ ! -f "/etc/init.d/tinyproxy" ]]; then
    if [[ -z "${tinyproxy_bin}" ]]; then
        echo "[TINYPROXY] tinyproxy not found..."
        exit 1
    fi
    ${tinyproxy_bin} -d -c "${TINYPROXY_CONFIG}" &
else
    /etc/init.d/tinyproxy start
fi

echo "[TINYPROXY] Starting tinyproxy completed..."
