#!/bin/bash

# export the variables so that this process can access them
# shellcheck disable=SC1091
source /etc/templates/env.sh

if [[ "${TOR_CLIENT_ENABLED}" == "true" ]]; then
    if [[ "${TOR_CLIENT}" == "transmission" ]]; then
        /etc/transmission/start.sh "$@"
    elif [[ "${TOR_CLIENT}" == "deluge" ]]; then
        /etc/deluge/start.sh "$@"
    fi
fi
