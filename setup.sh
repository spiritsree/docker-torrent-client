#!/bin/bash

IMAGE_TAG='docker-torrent-client'

# Quotes around this won't expand the tilde
LOCAL_DATA_DIR=~/Downloads/uTorrent/data/

SCRIPT_NAME="$( basename "${BASH_SOURCE[0]}" )"
BASEDIR=$(dirname "$0")
RED='\033[31m'        # Red
NC='\033[0m'          # Color Reset
YELLOW_ALT=$(echo -e "\033[1;33m")     # Yellow
GREEN_ALT=$(echo -e "\033[1;32m")      # Green
NC_ALT=$(echo -e "\033[0m")            # Color Reset
ARG_USER=''
ARG_PASS=''
ARG_OS='ubuntu'
ARG_DIR="${LOCAL_DATA_DIR}"
ARG_PROVIDER=''
ARG_LOCAL='false'
ARG_PROTO='UDP'
ARG_IMAGE='spiritsree/docker-torrent-client:latest-ubuntu'
OPENVPN_SERVERS="${BASEDIR}/app/openvpn/vpn_servers.json"

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
    echo '    -u|--user <username>              VPN Username'
    echo '    -p|--pass <password>              VPN Password'
    echo '    -v|--vpn-provider <vpn-provider>  VPN Provider (e.g: HideMe)'
    echo
    echo 'Optional Arguments (O_ARGS):'
    echo '    -h|--help                     Print usage'
    echo '    -o|--os <ubuntu|alpine>       OS type, Default: ubuntu'
    echo "    -d|--data-dir <local-dir>     Local dir to mount for data (This should be added in Docker File Sharing Default: ${LOCAL_DATA_DIR})"
    echo '    -l|--local                    Build docker image locally'
    echo '    -i|--image <docker-image>     Docker Image'
    echo '    --proto <UDP|TCP>             VPN connection proto UDP or TCP'
    echo
    echo 'Examples:'
    echo "    ${SCRIPT_NAME}" -v
    echo "    ${SCRIPT_NAME} -u user -p password -v HideMe -i spiritsree/docker-torrent-client:latest-ubuntu"
    echo "    ${SCRIPT_NAME} -u user -p password -v FastestVPN --proto tcp"
    echo
}

# Get Options
_getOptions() {
    optspec=":hlu:p:o:d:v:i:-:"
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
    local  __resultvar=$1
    local vpn_provider=$2
    local vpn_proto=$3

    raw_serverlist=$(jq -r -c ."${vpn_provider}"."${vpn_proto}" "${OPENVPN_SERVERS}")
    if [[ -z "${raw_serverlist}" ]] || [[ "${raw_serverlist}" == "null" ]]; then
        server=""
        eval "${__resultvar}='$server'"
    else
        # Select VPN server from the list for given provider
        serverlist=$(echo "${raw_serverlist}" | jq -r -c .[])
        count=$(echo "${serverlist}" |wc -l)
        option_list=$(echo "${serverlist}" | grep -n . | sed 's/:/:-->  /g' | column -t -s ':')
        echo -e "${RED}SELECT THE SERVER FROM THE LIST :${NC}"
        echo
        # shellcheck disable=SC2001
        echo "${option_list}" | sed "s/^\(.*-->  \)\(.*\)\$/${YELLOW_ALT}\1${NC_ALT}${GREEN_ALT}\2${NC_ALT}/g"
        # if 1 option select that else prompt
        if [[ ${count} -eq 1 ]]; then
            line=1
        else
            until [[ $line =~ [0-9]+ ]]; do
                echo -e -n "${RED}--> ${NC}"
                read -r line
            done
        fi
        server=$(echo "${serverlist}" | sed -n "${line}p" | awk '{ print $1 }')
        eval "${__resultvar}='$server'"
    fi
}


# Main Function
main() {
    _getOptions "$@"
    local image_os vpn_proto vpn_provider ipv6_enabled vpn_server local_net

    if [[ -z "${ARG_USER}" ]]; then
        _usage "Username required !!!"
        exit 1
    elif [[ -z "${ARG_PASS}" ]]; then
        _usage "Password required !!!"
        exit 1
    elif [[ -z "${ARG_PROVIDER}" ]]; then
        _usage "VPN Provider name required !!!"
        exit 1
    fi

    image_os=$(_lowercase "${ARG_OS}")
    vpn_proto=$(_lowercase "${ARG_PROTO}")

    if ! [[ "${vpn_proto}" == "udp" || "${vpn_proto}" == "tcp" ]]; then
        _usage "--proto only UDP or TCP are valid values !!!"
        exit 1
    fi

    if ! [[ "${image_os}" == "ubuntu" ||  "${image_os}" == "alpine" ]]; then
        _usage "Choose os from ubuntu or alpine"
        exit 1
    fi

    if [[ -z "${ARG_DIR}" ]] || [[ ! -d "${ARG_DIR}" ]]; then
        _usage "Provide a valid dir !!!"
        exit 1
    fi

    if ! command -v jq > /dev/null; then
        echo "Please install jq"
        exit 1
    fi

    vpn_provider=$(_lowercase "${ARG_PROVIDER}")

    _get_server "vpn_server" "${vpn_provider}" "${vpn_proto}"

    if [[ -z "${vpn_server}" ]]; then
        echo "VPN Provider or protocol not supported !!!"
        exit 1
    fi

    # Build the docker image if local
    if [[ "${ARG_LOCAL}" == "true" ]]; then
        docker build --no-cache -t "${IMAGE_TAG}:latest-${image_os}" -f "Dockerfile.${image_os}" app
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

    # OpenVPN Provider
    OPT+="\n\t\t-e OPENVPN_PROVIDER='${ARG_PROVIDER}' \\ "
    OPT+="\n\t\t-e OPENVPN_CONNECTION='${vpn_server}:${vpn_proto}' \\ "

    # OpenVPN username and password
    OPT+="\n\t\t-e OPENVPN_USERNAME='${ARG_USER}' \\ "
    OPT+="\n\t\t-e OPENVPN_PASSWORD='${ARG_PASS}' \\ "

    # Local network
    OPT+="\n\t\t-e LOCAL_NETWORK='${local_net}' \\ "

    # Port
    OPT+="\n\t\t-p 9091:9091 \\ "

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
