#!/bin/bash

# Stop the transmission client
echo "Stopping transmission client..."
transmission_pid=$(pidof transmission-daemon)
if [[ -n "${transmission_pid}" ]]; then
    kill ${transmission_pid}
fi
