#!/bin/bash

echo "[TINYPROXY] Stopping tinyproxy..."

if [[ ! -f "/etc/init.d/tinyproxy" ]]; then
    killall tinyproxy > /dev/null
else
    /etc/init.d/tinyproxy stop
fi

echo "[TINYPROXY] Stopping tinyproxy completed..."
