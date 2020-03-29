#!/bin/bash

IMAGE_TAG='docker-torrent-client'

# Quotes around this won't expand the tilde
LOCAL_DATA_DIR=~/Downloads/uTorrent/data/

SCRIPT_NAME="$( basename "${BASH_SOURCE[0]}" )"
RED='\033[31m'        # Red
NC='\033[0m'          # Color Reset
ARG_USER=''
ARG_PASS=''
ARG_OS='ubuntu'
ARG_DIR="${LOCAL_DATA_DIR}"

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
    echo "    ${SCRIPT_NAME} [-h|--help] <-u|--user username> <-p|--pass password> [-o|--os <ubuntu|alpine>] [-d|--data-dir <local-dir>]"
    echo
    echo 'Mandatory Arguments:'
    echo '    -u|--user <username>          VPN Username'
    echo '    -p|--pass <password>          VPN Password'
    echo
    echo 'Optional Arguments:'
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
    optspec=":hu:p:o:d:-:"
    while getopts "$optspec" opt; do
        case $opt in
            -)
                case "${OPTARG}" in
                    user)
                        ARG_USER="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        if [[ -z "${ARG_USER}" ]]; then
                            _usage "Please provide a username"
                            exit 1
                        fi
                        ;;
                    pass)
                        ARG_PASS="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        if [[ -z "${ARG_PASS}" ]]; then
                            _usage "Please provide a password"
                            exit 1
                        fi
                        ;;
                    os)
                        ARG_OS="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
                        ;;
                    data-dir)
                        ARG_DIR="${!OPTIND}"; OPTIND=$(( OPTIND + 1 ))
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
    fi

    local image_os=$(_lowercase "${ARG_OS}")

    if ! [[ "${image_os}" == "ubuntu" ||  "${image_os}" == "alpine" ]]; then
        _usage "Choose os from ubuntu or alpine"
        exit 1
    fi

    if [[ -z "${ARG_DIR}" ]] || [[ ! -d "${ARG_DIR}" ]]; then
        _usage "Provide a valid dir !!!"
        exit 1
    fi

    # Build the docker image
    docker build --no-cache -t "${IMAGE_TAG}-${image_os}" -f Dockerfile.${image_os} app

    OPT='--cap-add=NET_ADMIN -d \\'
    # Check if Docker IPv6 is enabled
    local ipv6_enabled=$(docker network ls --filter Driver="bridge"  --format "{{.IPv6}}")

    # Disable IPv6 if Docker doesn't support it
    if [[ "${ipv6_enabled}" == "false" ]]; then
        OPT+='\n\t\t--sysctl net.ipv6.conf.all.disable_ipv6=0 \\'
    fi

    # DNS IPs
    OPT+='\n\t\t--dns 8.8.8.8 \\'
    OPT+='\n\t\t--dns 8.8.4.4 \\'

    # Volume mount for Data
    OPT+='\n\t\t-v '${ARG_DIR}':/data \\'

    # OpenVPN username and password
    OPT+='\n\t\t-e OPENVPN_USERNAME='\'${ARG_USER}\'' \\'
    OPT+='\n\t\t-e OPENVPN_PASSWORD='\'${ARG_PASS}\'' \\'

    # Docker Image to run
    OPT+='\n\t\t'${IMAGE_TAG}'-'${image_os}':latest \n'

    # Run this command to start the docker
    echo 'Execute this to start the docker '
    printf "docker run ${OPT}"
}

main "$@"
