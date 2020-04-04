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
OPENVPN_SERVERS="${BASEDIR}/app/openvpn/vpn_servers.json"

# Highlight the message
_highlight_msg() {
    local msg="$*"
    if [[ -n "${msg}" ]]; then
        echo -e "\n ${RED} ${msg} ${NC}"
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
    echo "    -d|--data-dir <local-dir>     Local dir to mount for data (This should be added in Docker File Sharing Default: ${LOCAL_DATA_DIR}"
    echo
    echo 'Examples:'
    echo "    ${SCRIPT_NAME}"
    echo "    ${SCRIPT_NAME} -u user -p password"
    echo
}

# Get Options
_getOptions() {
    optspec=":hu:p:o:d:v:-:"
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
                    help)
                        _usage
                        exit 0
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
            u)
                ARG_USER="${OPTARG}"
                ;;
            p)
                ARG_PASS="${OPTARG}"
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


# Main Function
main() {
    _getOptions "$@"

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

    local image_os
    image_os=$(_lowercase "${ARG_OS}")

    if ! [[ "${image_os}" == "ubuntu" ||  "${image_os}" == "alpine" ]]; then
        _usage "Choose os from ubuntu or alpine"
        exit 1
    fi

    if [[ -z "${ARG_DIR}" ]] || [[ ! -d "${ARG_DIR}" ]]; then
        _usage "Provide a valid dir !!!"
        exit 1
    fi

    local vpn_provider
    vpn_provider=$(_lowercase "${ARG_PROVIDER}")

    raw_serverlist=$(jq -r -c ."${vpn_provider}" "${OPENVPN_SERVERS}")
    if [[ -z "${raw_serverlist}" ]] || [[ "${raw_serverlist}" == "null" ]]; then
        echo "VPN Provider not supported !!!"
        exit 1
    fi
    # Select VPN server from the list for given provider
    serverlist=$(echo "${raw_serverlist}" | jq -r -c .[])
    count=$(echo "${serverlist}" |wc -l)
    option_list=$(echo "${serverlist}" | grep -n . | sed 's/:/:-->  /g' | column -t -s ':')
    echo -e "${RED}SELECT THE SERVER FROM THE LIST :${NC}"
    echo
    echo "${option_list}" | sed "s/^\(.*-->  \)\(.*\)\$/${YELLOW_ALT}\1${NC_ALT}${GREEN_ALT}\2${NC_ALT}/g"
    # if 1 option select that else prompt
    if [[ ${count} -eq 1 ]]; then
        line=1
    else
        until [[ $line =~ [0-9]+ ]]; do
            echo -e -n "${RED}--> ${NC}"
            read line
        done
    fi
    vpn_server=$(echo "${serverlist}" | sed -n "${line}p" | awk '{ print $1 }')

    # Build the docker image
    docker build --no-cache -t "${IMAGE_TAG}-${image_os}" -f "Dockerfile.${image_os}" app

    # Docker capability
    OPT='-d --cap-add=NET_ADMIN \\'

    # Check if Docker IPv6 is enabled
    local ipv6_enabled
    ipv6_enabled=$(docker network ls --filter Driver="bridge"  --format "{{.IPv6}}")

    # Disable IPv6 if Docker doesn't support it
    if [[ "${ipv6_enabled}" == "false" ]]; then
        OPT+='\n\t\t--sysctl net.ipv6.conf.all.disable_ipv6=0 \\'
    fi

    # Get local IP
    local local_ip
    local_ip=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

    # DNS IPs
    OPT+='\n\t\t--dns 8.8.8.8 \\'
    OPT+='\n\t\t--dns 8.8.4.4 \\'

    # Volume mount for Data
    OPT+='\n\t\t-v '${ARG_DIR}':/data \\'

    # OpenVPN Provider
    OPT+='\n\t\t-e OPENVPN_PROVIDER='\'${ARG_PROVIDER}\'' \\'
    OPT+='\n\t\t-e OPENVPN_HOSTNAME='\'${vpn_server}\'' \\'

    # OpenVPN username and password
    OPT+='\n\t\t-e OPENVPN_USERNAME='\'${ARG_USER}\'' \\'
    OPT+='\n\t\t-e OPENVPN_PASSWORD='\'${ARG_PASS}\'' \\'

    # Local network
    OPT+='\n\t\t-e LOCAL_NETWORK='\'${local_ip}/32\'' \\'

    # Port
    OPT+='\n\t\t-p 9091:9091 \\'

    # Docker Image to run
    OPT+='\n\t\t'${IMAGE_TAG}'-'${image_os}':latest \n'

    # Run this command to start the docker
    _highlight_msg "Execute this to start the docker"
    echo -e "docker run ${OPT}"
}

main "$@"
