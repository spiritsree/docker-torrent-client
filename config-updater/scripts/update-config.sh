#!/bin/bash

# shellcheck source=functions.sh
# shellcheck disable=SC1091
source /usr/local/scripts/functions.sh

# Global Settings
export URL_CONFIG="/config/url.json"

# If no vpn provider given exit
if [[ -z "${VPN_PROVIDER-}" ]] || [[ "${VPN_PROVIDER}" == "NONE" ]]; then
    echo "VPN provider empty or not given..."
    echo "NO OP..."
    exit
elif [[ ! -f "${URL_CONFIG}" ]]; then
    echo "URL config file not found..."
    exit
fi

PROVIDER_URL=$(jq -r ."${VPN_PROVIDER,,}" "${URL_CONFIG}")

if [[ -z "${PROVIDER_URL-}" ]]; then
    echo "Provider url empty..."
    exit
fi

if [[ "${VPN_PROVIDER,,}" == "hidemyass" ]]; then
    _update_hidemyass_config "${VPN_PROVIDER,,}" "${PROVIDER_URL}"
elif [[ "${VPN_PROVIDER,,}" == "nordvpn" ]]; then
    _update_nordvpn_config "${VPN_PROVIDER,,}" "${PROVIDER_URL}"
fi

rm -rf "${TMP_DIR}"
