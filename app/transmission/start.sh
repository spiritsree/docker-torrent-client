#!/bin/bash

# export the variables so that this process can access them
source /etc/transmission/env.sh

# This scrip will be passed with multiple arguments
# start.sh <tunnel-device> <tun-mtu> <link-mtu> <tunnel-ip> <net-mask|remote-ip> <init|restart>

# Create a non privileged user if not root
if [[ "${TRANSMISSION_RUNAS_ROOT}" == "false" ]]; then
    TRANSMISSION_USER='jedi'
else
    TRANSMISSION_USER='root'
fi

export TRANSMISSION_USER
TRANSMISSION_UID=$(id -u "${TRANSMISSION_USER}")
TRANSMISSION_GID=$(id -g "${TRANSMISSION_USER}")
export TRANSMISSION_UID
export TRANSMISSION_GID

# Create the directories if not
if [[ ! -d ${TRANSMISSION_HOME} ]]; then
    mkdir -p ${TRANSMISSION_HOME}
fi
if [[ ! -d ${TRANSMISSION_WATCH_DIR} ]]; then
    mkdir -p ${TRANSMISSION_WATCH_DIR}
fi
if [[ ! -d ${TRANSMISSION_INCOMPLETE_DIR} ]]; then
    mkdir -p ${TRANSMISSION_INCOMPLETE_DIR}
fi
if [[ ! -d ${TRANSMISSION_DOWNLOAD_DIR} ]]; then
    mkdir -p ${TRANSMISSION_DOWNLOAD_DIR}
fi

# Changing ownership of directories
echo "Changing ownership of dirs to ${TRANSMISSION_USER} with UID ${TRANSMISSION_UID}"
chown -R ${TRANSMISSION_USER}:${TRANSMISSION_USER} \
                              ${TRANSMISSION_HOME} \
                              ${TRANSMISSION_WATCH_DIR} \
                              ${TRANSMISSION_INCOMPLETE_DIR} \
                              ${TRANSMISSION_DOWNLOAD_DIR}

chmod -R 775 ${TRANSMISSION_HOME} \
             ${TRANSMISSION_WATCH_DIR} \
             ${TRANSMISSION_INCOMPLETE_DIR} \
             ${TRANSMISSION_DOWNLOAD_DIR}

# Start the transmission client after VPN is ready
echo "Starting transmission client..."
echo "Received arguments...$*"

tun_device=$1
tun_ip=$4

if [[ "${tun_device}" = "" ]]; then
   echo "ERR: Tunnel IP could not be found !!!"
   kill -9 "${PPID}"
   exit 1
fi

echo "Setting TRANSMISSION_BIND_ADDRESS_IPV4 to ${tun_device} device ip: ${tun_ip}"
export TRANSMISSION_BIND_ADDRESS_IPV4=${tun_ip}

echo "Generating settings.json from env variables..."
# Settings are from https://github.com/transmission/transmission/wiki/Editing-Configuration-Files
# For details about the settings refer the url
dockerize -template /etc/transmission/settings.tmpl:${TRANSMISSION_HOME}/settings.json

echo "Transmission will run as \"${TRANSMISSION_USER}\" with UID \"${TRANSMISSION_UID}\" and GID \"${TRANSMISSION_GID}\""
exec su --preserve-environment ${TRANSMISSION_USER} -s /bin/bash -c "/usr/bin/transmission-daemon -g ${TRANSMISSION_HOME} --logfile ${LOG_FILE}" &

