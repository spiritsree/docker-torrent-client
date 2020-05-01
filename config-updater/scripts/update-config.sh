#!/bin/bash

# shellcheck source=functions.sh
# shellcheck disable=SC1091
source /usr/local/scripts/functions.sh

# Global Settings
export HIDE_MY_ASS_URI="https://vpn.hidemyass.com/vpn-config"

# If no vpn provider given exit
if [[ -z "${VPN_PROVIDER-}" ]] || [[ "${VPN_PROVIDER}" == "NONE" ]]; then
    echo "VPN provider empty or not given..."
    echo "NOOP..."
    exit
fi

if [[ "${VPN_PROVIDER,,}" == "hidemyass" ]]; then
    _update_hidemyass_config "${HIDE_MY_ASS_URI}"
fi

rm -rf "${TMP_DIR}"
