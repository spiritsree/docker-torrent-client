#!/bin/bash

IMAGE_TAG='docker-torrent-client'

# Quotes around this won't expand the tilde
LOCAL_DATA_DIR='/data'

SCRIPT_NAME="$( basename "${BASH_SOURCE[0]}" )"
BASEDIR=$(dirname "$0")
RED='\033[31m'        # Red
NC='\033[0m'          # Color Reset
RED_ALT=$(echo -e "\033[1;31m")        # Yellow
YELLOW_ALT=$(echo -e "\033[1;33m")     # Yellow
GREEN_ALT=$(echo -e "\033[1;32m")      # Green
NC_ALT=$(echo -e "\033[0m")            # Color Reset
ARG_USER=''
ARG_PASS=''
ARG_OS='ubuntu'
ARG_DIR="${LOCAL_DATA_DIR}"
ARG_PROVIDER=''
ARG_LOCAL='false'
ARG_RECOMMEND='true'
ARG_FILTER_COUNTRY='false'
ARG_FILTER_TYPE='false'
ARG_FILTER_PROTO='true'
ARG_TORRENT='true'
ARG_PROXY='false'
ARG_PROTO='UDP'
ARG_AUTH=''
ARG_IMAGE='spiritsree/docker-torrent-client:latest-ubuntu'
OPENVPN_SERVERS="${BASEDIR}/app/tmpls/openvpn/vpn_servers.json"
NORD_API='https://api.nordvpn.com/v1'
declare -a NORD_HEADERS=( "-H" "User-Agent: NordVPN_Client_5.56.780.0" "-H" "Host: api.nordvpn.com" "-H" "Connection: Close" )

# Highlight the message
_highlight_msg() {
    local msg="$*"
    if [[ -n "${msg}" ]]; then
        echo -e "\n${RED}${msg} ${NC}"
        echo
    fi
}

# Usage help
_usage() {
    local msg="$*"
    if [[ -n "${msg}" ]]; then
        length=$((${#msg} + 7 + 5))
        echo
        BORDER="printf '#%.0s' {1..${length}}"
        eval "${BORDER}"
        echo -e "\n# ${RED}ERROR:${NC} ${msg}  #"
        eval "${BORDER}"
        echo
    fi
    echo 'docker-torrent-client setup'
    echo
    echo 'Usage:'
    echo "    ${SCRIPT_NAME} M_ARGS [O_ARGS]"
    echo
    echo 'Mandatory Arguments (M_ARGS):'
    echo '    -v|--vpn-provider <vpn-provider>           VPN Provider (e.g: HideMe)'
    echo
    echo 'Optional Arguments (O_ARGS):'
    echo '    -h|--help                                  Print usage'
    echo '    -u|--user <username>                       VPN Username'
    echo '    -p|--pass <password>                       VPN Password'
    echo '    -o|--os <ubuntu|alpine>                    OS type, Default: ubuntu'
    echo '    -d|--data-dir <local-dir>                  Local dir to mount for data (Default: /data)'
    echo '    -a|--auth-dir <local-dir>                  Auth/Custom dir to mount with VPN credentials'
    echo '    -l|--local                                 Build docker image locally'
    echo '    -i|--image <docker-image>                  Docker Image (Default: spiritsree/docker-torrent-client:latest-ubuntu)'
    echo '    -r|--no-recommend                          Do not recommend best server use filters instead (only for NordVPN)'
    echo '    --proto <UDP|TCP|STRONG-TCP|STRONG-UDP>    VPN connection proto (Default: UDP)'
    echo '    --vpn-country                              Recommend based on country (only for NordVPN if --no-recommend)'
    echo '    --vpn-type                                 Recommend based on Server Type (only for NordVPN if --no-recommend)'
    echo '    --disable-torrent                          Do not enable torrent client'
    echo '    --enable-proxy                             Enable webproxy'
    echo
    echo 'Examples:'
    echo "    ${SCRIPT_NAME} -h"
    echo "    ${SCRIPT_NAME} -v NordVPN"
    echo "    ${SCRIPT_NAME} -u user -p password -v HideMe -i spiritsree/docker-torrent-client:latest-ubuntu"
    echo "    ${SCRIPT_NAME} -u user -p password -v FastestVPN --proto tcp"
    echo
}

# Get Options
_getOptions() {
    optspec=":hrla:u:p:o:d:v:i:-:"
    while getopts "$optspec" opt; do
        case $opt in
            -)
                case "${OPTARG}" in
                    user)
                        ARG_USER="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        [[ ${ARG_USER} =~ ^-.* || "${ARG_USER}" = "" ]] && { _usage "Option --user requires an agument"; exit 1; }
                        ;;
                    pass)
                        ARG_PASS="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        [[ ${ARG_PASS} =~ ^-.* || "${ARG_PASS}" = "" ]] && { _usage "Option --pass requires an agument"; exit 1; }
                        ;;
                    vpn-provider)
                        ARG_PROVIDER="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        [[ ${ARG_PROVIDER} =~ ^-.* || "${ARG_PROVIDER}" = "" ]] && { _usage "Option --vpn-provider requires an agument"; exit 1; }
                        ;;
                    os)
                        ARG_OS="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        [[ ${ARG_OS} =~ ^-.* || "${ARG_OS}" = "" ]] && { _usage "Option --os requires an agument"; exit 1; }
                        ;;
                    data-dir)
                        ARG_DIR="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        [[ ${ARG_DIR} =~ ^-.* || "${ARG_DIR}" = "" ]] && { _usage "Option --data-dir requires an agument"; exit 1; }
                        ;;
                    auth-dir)
                        ARG_AUTH="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        [[ ${ARG_AUTH} =~ ^-.* || "${ARG_AUTH}" = "" ]] && { _usage "Option --auth-dir requires an agument"; exit 1; }
                        ;;
                    vpn-country)
                        ARG_FILTER_COUNTRY="true"
                        ;;
                    vpn-type)
                        ARG_FILTER_TYPE="true"
                        ;;
                    disable-torrent)
                        ARG_TORRENT='false'
                        ;;
                    enable-proxy)
                        ARG_PROXY='true'
                        ;;
                    proto)
                        ARG_PROTO="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        [[ ${ARG_PROTO} =~ ^-.* || "${ARG_PROTO}" = "" ]] && { _usage "Option --proto requires an agument"; exit 1; }
                        ;;
                    image)
                        ARG_IMAGE="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        [[ ${ARG_IMAGE} =~ ^-.* || "${ARG_IMAGE}" = "" ]] && { _usage "Option --image requires an agument"; exit 1; }
                        ;;
                    help)
                        _usage
                        exit 0
                        ;;
                    no-recommend)
                        ARG_RECOMMEND="false"
                        ;;
                    local)
                        ARG_LOCAL="true"
                        ;;
                    *)
                        if [[ "$OPTERR" = 1 ]] && [[ "${optspec:0:1}" != ":" ]]; then
                            _usage "Unknown option --${OPTARG}"
                            exit 1
                        else
                            _usage "Unknown option --${OPTARG}"
                            exit 1
                        fi
                        ;;
                esac;;
            h)
                _usage
                exit 0
                ;;
            r)
                ARG_RECOMMEND="false"
                ;;
            l)
                ARG_LOCAL="true"
                ;;
            u)
                ARG_USER="${OPTARG}"
                ;;
            p)
                ARG_PASS="${OPTARG}"
                ;;
            i)
                ARG_IMAGE="${OPTARG}"
                [[ ${ARG_IMAGE} =~ ^-.* || "${ARG_IMAGE}" = "" ]] && { _usage "Option --image requires an agument"; exit 1; }
                ;;
            o)
                ARG_OS="${OPTARG}"
                ;;
            v)
                ARG_PROVIDER="${OPTARG}"
                ;;
            d)
                ARG_DIR="${OPTARG}"
                ;;
            a)
                ARG_AUTH="${OPTARG}"
                ;;
            \?)
                _usage "Invalid option: -$OPTARG"
                exit 1
                ;;
            :)
                _usage "Option -$OPTARG requires an argument."
                exit 1
                ;;
        esac
    done
}

# Convert to lower case
_lowercase() {
    local in=$1
    local out=''
    out=$(echo "${in}" | tr '[:upper:]' '[:lower:]')
    echo "${out}"
}

# Convert hex netmask to dotted decimal netmask
_hex_to_dec_netmask() {
    local netmask_hex=$1
    local netmask_dec
    netmask_dec=$(echo "${netmask_hex}" | \
        sed 's/0x// ; s/../& /g' | \
        tr '[:lower:]' '[:upper:]' | \
        while read -r B1 B2 B3 B4 ; do
            echo "ibase=16;$B1;$B2;$B3;$B4" | \
            bc | \
            tr '\n' . | \
            sed 's/\.$//'
        done)
    echo "${netmask_dec}"
}

# Get network bits from hex netmask
_hex_to_bits_netmask() {
    local netmask_hex=$1
    local netmask_bits
    netmask_bits=$(echo "${netmask_hex}" | \
        sed 's/0x// ; s/../& /g' | \
        tr '[:lower:]' '[:upper:]' | \
        while read -r B1 B2 B3 B4 ; do
            echo "ibase=16;obase=2;$B1$B2$B3$B4" | \
            bc | \
            tr -d -c 1 | \
            wc -c | \
            awk '{print $1 }'
        done)
    echo "${netmask_bits}"
}

# Get network from IP and netmask in hex
_get_network() {
    local ip_address=$1
    local netmask_hex=$2
    local a b c d addr mask net_bits net_digit net_id
    net_bits=$(_hex_to_bits_netmask "${netmask_hex}")
    { IFS=. read -r a b c d; } <<< "${ip_address}"
    addr=$(((((((a << 8) | b) << 8) | c) << 8) | d))
    mask=$((0xffffffff << (32 -net_bits)))
    net_digit=$((addr & mask))
    for ((n=0; n<4; n++)); do
        net_id=$((net_digit & 0xff))${net_id:+.}$net_id
        net_digit=$((net_digit >> 8))
    done
    echo "${net_id}/${net_bits}"
}

_get_local_network() {
    local ip_string ip netmask network
    ip_string=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*.*)/\2/p')
    ip=$(echo "${ip_string}" | awk '{ print $1 }')
    netmask=$(echo "${ip_string}" | awk '{ print $3 }')
    network=$(_get_network "${ip}" "${netmask}")
    echo "${network}"
}

# Get VPN Server from displayed list
_get_server() {
    local __resultvar=$1
    local vpn_provider=$2
    local vpn_proto=$3

    raw_serverlist=$(jq -r -c ."${vpn_provider}".\""${vpn_proto}"\" "${OPENVPN_SERVERS}")
    if [[ -z "${raw_serverlist}" ]] || [[ "${raw_serverlist}" == "null" ]]; then
        server=""
        eval "${__resultvar}='$server'"
    else
        # Select VPN server from the list for given provider
        serverlist=$(echo "${raw_serverlist}" | jq -r -c .[])
        count=$(echo "${serverlist}" |wc -l)
        option_list=$(echo "${serverlist}" | grep -n . | sed 's/:/:-->  /g' | column -t -s ':')
        echo
        echo -e "${RED}SELECT THE SERVER FROM THE LIST :${NC}"
        echo
        # shellcheck disable=SC2001
        echo "${option_list}" | sed "s/^\(.*-->  \)\(.*\)\$/${YELLOW_ALT}\1${NC_ALT}${GREEN_ALT}\2${NC_ALT}/g"
        # if 1 option select that else prompt
        if [[ ${count} -eq 1 ]]; then
            line=1
        else
            until [[ $line =~ [0-9]+ ]]; do
                echo -e -n "${RED}Select Server --> ${NC}"
                read -r line
            done
        fi
        server=$(echo "${serverlist}" | sed -n "${line}p" | awk '{ print $1 }')
        eval "${__resultvar}='$server'"
    fi
}

# Get recommended server from NordVPN
_get_recommended_host() {
    local __resultvar=$1
    local nord_api=$2
    local nord_filters=$3
    local rec_count=10
    local rec_serverlist r_id selected_host option_list
    local r_id=()
    if [[ -n "${nord_filters}" ]]; then
        rec_serverlist=$(curl -s "${NORD_HEADERS[@]}" "${nord_api}/servers/recommendations?${nord_filters}limit=${rec_count}" | jq -r '.[] | .hostname')
    else
        rec_serverlist=$(curl -s "${NORD_HEADERS[@]}" "${nord_api}/servers/recommendations?limit=${rec_count}" | jq -r '.[] | .hostname')
    fi
    while IFS='' read -r element; do r_id+=( "${element}" ); done < <(seq "${rec_count}")
    if [[ -z "${rec_serverlist}" ]] || [[ "${rec_serverlist}" == "null" ]]; then
        selected_host=""
        eval "${__resultvar}='$selected_host'"
    else
        # Select server from the recommended list
        option_list=$(echo "${rec_serverlist}" | grep -n . | sed 's/:/:-->  /g' | column -t -s ':')
        echo
        echo -e "${RED}SELECT SERVER FROM THE RECOMMENDED LIST :${NC}"
        echo
        # shellcheck disable=SC2001
        echo "${option_list}" | sed "s/^\(.*-->  \)\(.*\)\$/${YELLOW_ALT}\1${NC_ALT}${GREEN_ALT}\2${NC_ALT}/g"
        # if 1 option select that else prompt
        if [[ $(echo "${rec_serverlist}" | wc -l) -eq 1 ]]; then
            line=1
        else
            until [[ " ${r_id[*]} " == *" ${line} "* ]]; do
                read -r -p "${RED_ALT}Select Host --> ${NC_ALT}" line
            done
        fi
        selected_host=$(echo "${rec_serverlist}" | sed -n "${line}p" | awk '{ print $1 }')
        eval "${__resultvar}='$selected_host'"
    fi
}

# Select a VPN country
_select_country() {
    local __resultvar=$1
    local nord_api=$2
    local raw_countrylist s_country option_list
    local c_id=()

    raw_countrylist=$(curl -s "${NORD_HEADERS[@]}" "${nord_api}/servers/countries" | jq -r -c '.[] | (.id|tostring) + "=" + .name' 2> /dev/null)
    while IFS='' read -r element; do
        c_id+=( "${element}" )
    done < <(echo "${raw_countrylist}" | awk -F'=' '{ print $1 }')
    if [[ -z "${raw_countrylist}" ]] || [[ "${raw_countrylist}" == "null" ]]; then
        s_country=""
        eval "${__resultvar}='$s_country'"
    else
        # Select Country from the supported list
        option_list=$(echo "${raw_countrylist}" | sed 's/=/:-->  /g' | column -t -s ':')
        echo
        echo -e "${RED}SELECT THE COUNTRY FROM THE LIST :${NC}"
        echo
        # shellcheck disable=SC2001
        echo "${option_list}" | sed "s/^\(.*-->  \)\(.*\)\$/${YELLOW_ALT}\1${NC_ALT}${GREEN_ALT}\2${NC_ALT}/g"
        # if 1 option select that else prompt
        if [[ $(echo "${raw_countrylist}" | wc -l) -eq 1 ]]; then
            s_country="${c_id[0]}"
        else
            until [[ " ${c_id[*]} " == *" ${s_country} "* ]]; do
                read -r -p "${RED_ALT}Select Country --> ${NC_ALT}" s_country
            done
        fi
        eval "${__resultvar}='$s_country'"
    fi
}

# Select a VPN type
_select_vpn_type() {
    local __resultvar=$1
    local nord_api=$2
    local raw_typelist s_type s_type_id option_list
    local t_id=()

    raw_typelist=$(curl -s "${NORD_HEADERS[@]}" "${nord_api}/servers/groups" | jq -r -c '.[] | (.id|tostring) + "=" + .identifier' 2> /dev/null)
    while IFS='' read -r element; do
        t_id+=( "${element}" )
    done < <(echo "${raw_typelist}" | awk -F'=' '{ print $1 }')
    if [[ -z "${raw_typelist}" ]] || [[ "${raw_typelist}" == "null" ]]; then
        s_type=""
        eval "${__resultvar}='$s_type'"
    else
        # Select Country from the supported list
        option_list=$(echo "${raw_typelist}" | sed 's/=/:-->  /g' | column -t -s ':')
        echo
        echo -e "${RED}SELECT THE VPN TYPE FROM THE LIST :${NC}"
        echo
        # shellcheck disable=SC2001
        echo "${option_list}" | sed "s/^\(.*-->  \)\(.*\)\$/${YELLOW_ALT}\1${NC_ALT}${GREEN_ALT}\2${NC_ALT}/g"
        # if 1 option select that else prompt
        if [[ $(echo "${raw_typelist}" | wc -l) -eq 1 ]]; then
            s_type=$(echo "${raw_typelist}" | awk -F'=' '{ print $2 }')
        else
            until [[ " ${t_id[*]} " == *" ${s_type_id} "* ]]; do
                read -r -p "${RED_ALT}Select Type --> ${NC_ALT}" s_type_id
            done
        fi
        s_type=$(echo "${raw_typelist}" | grep -e "^${s_type_id}=" | awk -F'=' '{ print $2 }')
        eval "${__resultvar}='$s_type'"
    fi
}

# Main Function
main() {
    _getOptions "$@"
    local image_os vpn_proto vpn_provider ipv6_enabled vpn_server local_net
    local selected_country selected_proto selected_type filter

    if [[ -z "${ARG_PROVIDER}" ]]; then
        _usage "VPN Provider name required !!!"
        exit 1
    fi

    if [[ -z "${ARG_USER}" ]] || [[ -z "${ARG_PASS}" ]]; then
        if [[ -z "${ARG_AUTH}" ]]; then
            _usage "Auth dir required !!!"
            exit 1
        elif [[ ! -d "${ARG_AUTH}" ]]; then
            _usage "dir ${ARG_AUTH} doesn't exist"
            exit 1
        fi
    fi

    image_os=$(_lowercase "${ARG_OS}")
    vpn_proto=$(_lowercase "${ARG_PROTO}")
    vpn_provider=$(_lowercase "${ARG_PROVIDER}")

    if [[ "${vpn_provider}" == "pia" ]]; then
        if ! [[ "${vpn_proto}" == "udp" ||
                "${vpn_proto}" == "tcp" ||
                "${vpn_proto}" == "strong-tcp" ||
                "${vpn_proto}" == "strong-udp" ]]; then
            _usage "--proto only UDP, TCP, STRONG-TCP or STRONG-UDP are valid values with PIA !!!"
            exit 1
        fi
    else
        if ! [[ "${vpn_proto}" == "udp" || "${vpn_proto}" == "tcp" ]]; then
            _usage "--proto only UDP or TCP are valid values !!!"
            exit 1
        fi
    fi

    if ! [[ "${image_os}" == "ubuntu" ||  "${image_os}" == "alpine" ]]; then
        _usage "Choose os from ubuntu or alpine"
        exit 1
    fi

    if [[ -z "${ARG_DIR}" ]]; then
        _usage "Provide a valid dir !!!"
        exit 1
    elif [[ ! -d "${ARG_DIR}" ]]; then
        _usage "dir ${ARG_DIR} doesn't exist"
        exit 1
    fi

    if [[ "${vpn_provider}" != "custom" ]]; then
        if ! command -v jq > /dev/null; then
            echo "Please install jq"
            exit 1
        fi

        if [[ "${vpn_provider}" == "nordvpn" ]]; then
            if [[ "${ARG_RECOMMEND}" == "true" ]]; then
                _get_recommended_host "vpn_server" "${NORD_API}"
            elif [[ "${ARG_RECOMMEND}" == "false" ]]; then
                if [[ "${ARG_FILTER_COUNTRY}" == "false" ]] &&
                   [[ "${ARG_FILTER_TYPE}" == "false" ]]; then
                    _usage "Select filter using one or a combination of --vpn-country or --vpn-type"
                    exit 1
                fi
                if [[ "${ARG_FILTER_COUNTRY}" == "true" ]]; then
                    _select_country "selected_country" "${NORD_API}"
                fi
                if [[ "${ARG_FILTER_TYPE}" == "true" ]]; then
                    _select_vpn_type "selected_type" "${NORD_API}"
                fi
                if [[ "${ARG_FILTER_PROTO}" == "true" ]]; then
                    if [[ "${vpn_proto}" == "udp" ]]; then
                        selected_proto="openvpn_udp"
                    elif [[ "${vpn_proto}" == "tcp" ]]; then
                        selected_proto="openvpn_tcp"
                    fi
                fi
                if [[ -n "${selected_country-}" ]]; then
                    filter+="filters\[country_id\]=${selected_country}&"
                fi
                if [[ -n "${selected_type-}" ]]; then
                    filter+="filters\[servers_groups\]\[identifier\]=${selected_type}&"
                fi
                if [[ -n "${selected_proto-}" ]]; then
                    filter+="filters\[servers_technologies\]\[identifier\]=${selected_proto}&"
                fi
                _get_recommended_host "vpn_server" "${NORD_API}" "${filter}"
            fi
        else
            _get_server "vpn_server" "${vpn_provider}" "${vpn_proto}"
        fi

        if [[ -z "${vpn_server}" ]]; then
            echo "Could not get a VPN server !!!"
            exit 1
        fi
    fi

    # Build the docker image if local
    if [[ "${ARG_LOCAL}" == "true" ]]; then
        docker build --no-cache -t "${IMAGE_TAG}:latest-${image_os}" -f "Dockerfile.${image_os}" .
    fi
    # Docker capability
    OPT="-d --cap-add=NET_ADMIN \\ "

    # Check if Docker IPv6 is enabled
    ipv6_enabled=$(docker network ls --filter Driver="bridge"  --format "{{.IPv6}}")

    # Disable IPv6 if Docker doesn't support it
    if [[ "${ipv6_enabled}" == "false" ]]; then
        OPT+="\n\t\t--sysctl net.ipv6.conf.all.disable_ipv6=0 \\ "
    fi

    # Get local network
    local_net=$(_get_local_network)

    # DNS IPs
    OPT+="\n\t\t--dns 8.8.8.8 \\ "
    OPT+="\n\t\t--dns 8.8.4.4 \\ "

    # Volume mount for Data
    OPT+="\n\t\t-v ${ARG_DIR}:/data \\ "

    # OpenVPN username and password
    if [[ -n "${ARG_USER-}" ]] && [[ -n "${ARG_PASS}" ]]; then
        OPT+="\n\t\t-e OPENVPN_USERNAME='${ARG_USER}' \\ "
        OPT+="\n\t\t-e OPENVPN_PASSWORD='${ARG_PASS}' \\ "
    elif [[ "${vpn_provider}" == "custom" ]]; then
        OPT+="\n\t\t-v ${ARG_AUTH}:/custom \\ "
    else
        OPT+="\n\t\t-v ${ARG_AUTH}:/control \\ "
    fi

    # OpenVPN Provider
    OPT+="\n\t\t-e OPENVPN_PROVIDER='${ARG_PROVIDER}' \\ "
    if [[ "${vpn_provider}" != "custom" ]]; then
        OPT+="\n\t\t-e OPENVPN_CONNECTION='${vpn_server}:${vpn_proto}' \\ "
    fi

    # Local network
    OPT+="\n\t\t-e LOCAL_NETWORK='${local_net}' \\ "

    # Diable torrent client
    if [[ "${ARG_TORRENT}" == "false" ]]; then
        OPT+="\n\t\t-e TOR_CLIENT_ENABLED=false \\ "
    fi

    # Enable webproxy
    if [[ "${ARG_PROXY}" == "true" ]]; then
        OPT+="\n\t\t-e WEBPROXY_ENABLED=true \\ "
    fi

    # Port
    OPT+="\n\t\t-p 9091:9091 \\ "
    # Enable proxy port
    if [[ "${ARG_PROXY}" == "true" ]]; then
        OPT+="\n\t\t-p 8888:8888 \\ "
    fi

    # Docker Image to run
    if [[ "${ARG_LOCAL}" == "true" ]]; then
        OPT+="\n\t\t${IMAGE_TAG}:latest-${image_os} \n"
    else
        OPT+="\n\t\t${ARG_IMAGE} \n"
    fi

    # Run this command to start the docker
    _highlight_msg "Execute this to start the docker"
    OPT="$(echo -e "${OPT}" | expand -t 7)"
    echo "docker run ${OPT}" | sed 's/ $//g'
}

main "$@"
