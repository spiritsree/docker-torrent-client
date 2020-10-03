#!/bin/bash

# shellcheck source=functions.sh
# shellcheck disable=SC1091
source /usr/local/scripts/functions.sh

if [[ "${DEBUG}" = "true" ]]; then
    set -x
fi

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
elif [[ "${VPN_PROVIDER,,}" == "purevpn" ]]; then
    _update_purevpn_config "${VPN_PROVIDER,,}" "${PROVIDER_URL}"
elif [[ "${VPN_PROVIDER,,}" == "pia" ]]; then
    _update_pia_config "${VPN_PROVIDER,,}" "${PROVIDER_URL}"
elif [[ "${VPN_PROVIDER,,}" == "vyprvpn" ]]; then
    _update_vyprvpn_config "${VPN_PROVIDER,,}" "${PROVIDER_URL}" "256"
elif [[ "${VPN_PROVIDER,,}" == "surfshark" ]]; then
    _update_surfshark_config "${VPN_PROVIDER,,}" "${PROVIDER_URL}"
elif [[ "${VPN_PROVIDER,,}" == "ipvanish" ]]; then
    _update_ipvanish_config "${VPN_PROVIDER,,}" "${PROVIDER_URL}"
elif [[ "${VPN_PROVIDER,,}" == "tunnelbear" ]]; then
    _update_tunnelbear_config "${VPN_PROVIDER,,}" "${PROVIDER_URL}"
elif [[ "${VPN_PROVIDER,,}" == "ivpn" ]]; then
    _update_ipvn_config "${VPN_PROVIDER,,}" "${PROVIDER_URL}"
elif [[ "${VPN_PROVIDER,,}" == "privatevpn" ]]; then
    _update_privatevpn_config "${VPN_PROVIDER,,}" "${PROVIDER_URL}"
elif [[ "${VPN_PROVIDER,,}" == "btguard" ]]; then
    _update_btguard_config "${VPN_PROVIDER,,}" "${PROVIDER_URL}"
fi

