#!/bin/bash

# This script will help construct the vpn_servers.json
# This require a file path as input with servers in each line

SERVER_FILE=$1
VPN_PROVIDER=$2
PROTO=${3:-UDP}
SCRIPT_NAME="$( basename "${BASH_SOURCE[0]}" )"
BASEDIR=$(dirname "$0")
VPN_SERVER_FILE="${BASEDIR}/../tmpls/openvpn/vpn_servers.json"
TMP_FILE="./tmp.json"
RED='\033[31m'        # Red
NC='\033[0m'          # Color Reset

# Usage
_usage() {
    echo
    echo 'Usage:'
    echo "    ${SCRIPT_NAME} <SERVER_LIST_FILE> <VPN_PROVIDER> <UDP|TCP>"
    echo
}

# Convert to lower case
_lowercase() {
    local in=$1
    local out=''
    out=$(echo "${in}" | tr '[:upper:]' '[:lower:]')
    echo "${out}"
}

if ! [[ -f "${SERVER_FILE}" ]]; then
    echo -e "${RED}File ${SERVER_FILE} does not exist !!!${NC}"
    _usage
    exit 1
fi

if [[ -z "${VPN_PROVIDER}" ]]; then
    echo -e "${RED}VPN Provider missing !!!${NC}"
    _usage
    exit 1
fi

if ! command -v jq > /dev/null; then
    echo -e "${RED}Please install jq !!!${NC}"
    exit 1
fi

json_key_name=$(_lowercase "${VPN_PROVIDER}")

if [[ -z "${PROTO-}" ]]; then
    jq -c --argjson servers "$(jq -r -c --slurp --raw-input 'split("\n")[:-1]' "${SERVER_FILE}")" ".${json_key_name} = \$servers" "${VPN_SERVER_FILE}" > "${TMP_FILE}"
else
    vpn_proto=$(_lowercase "${PROTO}")
    jq -c --argjson servers "$(jq -r -c --slurp --raw-input 'split("\n")[:-1]' "${SERVER_FILE}")" ".${json_key_name}.${vpn_proto} = \$servers" "${VPN_SERVER_FILE}" > "${TMP_FILE}"
fi

mv "${TMP_FILE}" "${VPN_SERVER_FILE}"
