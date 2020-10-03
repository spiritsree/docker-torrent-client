# shellcheck shell=bash

# Convert to lower case
_lowercase() {
    local in=$1
    local out=''
    out=$(echo "${in}" | tr '[:upper:]' '[:lower:]')
    echo "${out}"
}

# Get mounted template path
_get_template_path() {
    local mount_dir="/repo"
    local config_files openvpn_dir
    config_files=$(find "${mount_dir}" -type f -name "vpn_servers.json")
    openvpn_dir=$(dirname "${config_files}")
    echo "${openvpn_dir}"
}

# Update the server json file
_update_server_json() {
    local server_file=$1
    local vpn_provider=$2
    local proto=$3
    local main_json_file="${4}/vpn_servers.json"
    local tmp_file json_key_name
    tmp_file=$(mktemp /tmp/vpn_servers.XXXXXXXX)
    json_key_name=$(_lowercase "${vpn_provider}")
    if [[ -z "${proto-}" ]]; then
        jq -c --argjson servers "$(jq -r -c --slurp --raw-input 'split("\n")[:-1]' "${server_file}")" ".${json_key_name} = \$servers" "${main_json_file}" > "${tmp_file}"
    else
        vpn_proto=$(_lowercase "${proto}")
        jq -c --argjson servers "$(jq -r -c --slurp --raw-input 'split("\n")[:-1]' "${server_file}")" ".${json_key_name}.\"${vpn_proto}\" = \$servers" "${main_json_file}" > "${tmp_file}"
    fi
    mv "${tmp_file}" "${main_json_file}"
}

# Make config template
_update_config() {
    local config_dir=$1
    local vpn_provider=$2
    local proto=$3
    local json_update=${4-true}
    local status="success"
    local tmp_host_file parent_config_path
    tmp_host_file=$(mktemp /tmp/hosts.XXXXXXXX)
    parent_config_path=$(_get_template_path)
    vpn_provider=$(_lowercase "${vpn_provider}")
    proto=$(_lowercase "${proto}")
    if [[ -z "${parent_config_path-}" ]]; then
        echo "Config file not found. Please check mount dir..."
        exit
    fi
    pushd "${config_dir}" > /dev/null || exit
    grep -h 'remote ' -- *.ovpn | awk '{ print $2 }' | sort -u > "${tmp_host_file}"
    if [[ "${json_update}" == "true" ]]; then
        _update_server_json "${tmp_host_file}" "${vpn_provider}" "${proto}" "${parent_config_path}"
    fi
    sed -i 's/\r$//g' -- *.ovpn
    sed -i 's/^auth-user-pass$/auth-user-pass \/control\/ovpn-auth.txt/' -- *.ovpn
    sed -i -rE 's/^remote .+ ([[:digit:]]+)$/remote {{ .Env.OPENVPN_HOSTNAME }} \1/' -- *.ovpn
    sed -i -rE 's/^remote .+ ([[:digit:]]+) (udp|tcp-client)$/remote {{ .Env.OPENVPN_HOSTNAME }} \1 \2/' -- *.ovpn
    sed -i -rE 's/^verify-x509-name .+ name$/verify-x509-name {{ .Env.OPENVPN_HOSTNAME }} name/' -- *.ovpn
    sed -i -rE 's/^verify-x509-name .+ name-prefix$/verify-x509-name {{ .Env.OPENVPN_HOSTNAME_PREFIX }} name-prefix/' -- *.ovpn
    sed -i '/<\/tls-crypt>/{:a;N;/<\/tls-crypt>/!ba};/<\/tls-crypt>/{ s/.*/<\/tls-crypt>/; t; d}' -- *.ovpn
    if [[ ! -d "${parent_config_path}/${vpn_provider}/${proto}" ]]; then
        mkdir -p "${parent_config_path}/${vpn_provider}/${proto}"
    fi
    files_to_process=$(find . -type f -regextype egrep -iregex '.*?\.ovpn' -printf '%P\n')
    for file in ${files_to_process}; do
        if [[ ! -f "default.ovpn.tmpl" ]]; then
            cp "${file}" default.ovpn.tmpl
        fi
        if ! diff -q -B -b -Z <(grep -vE '^\s*(#|$)' default.ovpn.tmpl) <(grep -vE '^\s*(#|$)' "${file}") > /dev/null; then
            status="fail"
        fi
    done
    if [[ "${status}" == "success" ]]; then
        if [[ "${vpn_provider}" == "nordvpn" ]]; then
            sed -i 's/ping 15/inactive 3600\nping 10/g' default.ovpn.tmpl
            sed -i 's/ping-restart 0/ping-exit 60/g' default.ovpn.tmpl
            sed -i 's/ping-timer-rem//g' default.ovpn.tmpl
        fi
        ca_conf=$(grep -E '^ca .*' default.ovpn.tmpl)
        if [[ -n "${ca_conf}" ]]; then
            ca_file=$(echo "${ca_conf}" | awk '{ print $2 }')
            mv "${ca_file}" "${parent_config_path}/${vpn_provider}/${proto}/${ca_file}"
            sed -i -rE "s/^ca .*?$/ca \/etc\/templates\/openvpn\/${vpn_provider}\/${proto}\/${ca_file}/" -- default.ovpn.tmpl
        fi
        cert_conf=$(grep -E '^cert .*' default.ovpn.tmpl)
        if [[ -n "${cert_conf}" ]]; then
            cert_file=$(echo "${cert_conf}" | awk '{ print $2 }')
            mv "${cert_file}" "${parent_config_path}/${vpn_provider}/${proto}/${cert_file}"
            sed -i -rE "s/^cert .*?$/cert \/etc\/templates\/openvpn\/${vpn_provider}\/${proto}\/${cert_file}/" -- default.ovpn.tmpl
        fi
        key_conf=$(grep -E '^key .*' default.ovpn.tmpl)
        if [[ -n "${key_conf}" ]]; then
            key_file=$(echo "${key_conf}" | awk '{ print $2 }')
            mv "${key_file}" "${parent_config_path}/${vpn_provider}/${proto}/${key_file}"
            sed -i -rE "s/^key .*?$/key \/etc\/templates\/openvpn\/${vpn_provider}\/${proto}\/${key_file}/" -- default.ovpn.tmpl
        fi
        mv default.ovpn.tmpl "${parent_config_path}/${vpn_provider}/${proto}/default.ovpn.tmpl"
    fi
    popd > /dev/null || exit
}

# preparing for config update
_pre_config_update() {
    local vpn_provider=$1
    local target_dir=$2
    local target_protocol=$3
    local json_update=$4

    pushd "${target_dir}" > /dev/null || exit
    if [[ -z "${target_protocol-}" ]]; then
        pushd tcp > /dev/null || exit
        _update_config "$(pwd)" "${vpn_provider}" 'tcp'
        popd > /dev/null || exit
        pushd udp > /dev/null || exit
        _update_config "$(pwd)" "${vpn_provider}" 'udp'
        popd > /dev/null || exit
    else
        pushd "${target_protocol}" > /dev/null || exit
        if [[ -z "${json_update-}" ]]; then
            _update_config "$(pwd)" "${vpn_provider}" "${target_protocol}"
        else
            _update_config "$(pwd)" "${vpn_provider}" "${target_protocol}" "${json_update}"
        fi
        popd > /dev/null || exit
    fi
    popd > /dev/null || exit
}

# Get HideMyAss Config and update
_update_hidemyass_config() {
    local vpn_provider=$1
    local config_url=$2
    local tmp_dir ovpn_files target_dir config_domain file_name proto_dir
    echo "Getting HideMyAss configs ${config_url}..."
    config_domain=$(echo "${config_url}" | awk -F'/' '{ print $3 }')
    tmp_dir=$(mktemp -d /tmp/vpn.XXXXXXXX)
    target_dir=$(mktemp -d /tmp/target.XXXXXXXX)
    mkdir "${target_dir}"/{tcp,udp}
    if [[ -z "${config_domain-}" ]]; then
        echo "Cannot find config damain..."
        exit
    fi
    wget -q \
        --recursive \
        --no-clobber \
        --page-requisites \
        --html-extension \
        --directory-prefix="${tmp_dir}" \
        --domains vpn.hidemyass.com \
        --no-parent \
        --no-host-directories \
        "${config_url}"
    pushd "${tmp_dir}" > /dev/null || exit
    ovpn_files=$(find . -type f -regextype egrep -iregex '.*?openvpn.*?\.ovpn' -printf '%P\n')
    for each_conf in ${ovpn_files}; do
        file_name=$(basename "${each_conf}")
        proto_dir=$(basename "$(dirname "${each_conf}")" | tr '[:upper:]' '[:lower:]')
        if [[ "${proto_dir-}" == 'tcp' ]] || [[ "${proto_dir-}" == 'udp' ]]; then
            cp "${each_conf}" "${target_dir}/${proto_dir}/${file_name}"
        else
            cp "${each_conf}" "${target_dir}/${file_name}"
        fi
    done
    popd > /dev/null || pass
    _pre_config_update "${vpn_provider}" "${target_dir}"
}

# Get NordVPN Config and update
_update_nordvpn_config() {
    local vpn_provider=$1
    local config_url=$2
    local tmp_dir target_dir
    echo "Getting NordVPN configs using ${config_url}..."
    tmp_dir=$(mktemp -d /tmp/vpn.XXXXXXXX)
    target_dir=$(mktemp -d /tmp/target.XXXXXXXX)
    mkdir "${target_dir}"/{tcp,udp}
    pushd "${tmp_dir}" > /dev/null || exit
    curl -4 -sSL "${config_url}" -o nordvpn.zip || exit
    unzip -q nordvpn.zip || exit
    find . -name "*udp*.ovpn" -exec mv {} "${target_dir}/udp/" \;
    find . -name "*tcp*.ovpn" -exec mv {} "${target_dir}/tcp/" \;
    popd > /dev/null || exit
    _pre_config_update "${vpn_provider}" "${target_dir}"
}

# Get PureVPN Config and update
_update_purevpn_config() {
    local vpn_provider=$1
    local config_url=$2
    local tmp_dir target_dir
    echo "Getting PureVPN configs using ${config_url}..."
    tmp_dir=$(mktemp -d /tmp/vpn.XXXXXXXX)
    target_dir=$(mktemp -d /tmp/target.XXXXXXXX)
    mkdir "${target_dir}"/{tcp,udp}
    pushd "${tmp_dir}" > /dev/null || exit
    curl -4 -sSL "${config_url}" -o purevpn.zip || exit
    unzip -q purevpn.zip || exit
    find . -name "*udp*.ovpn" -exec mv {} "${target_dir}/udp/" \;
    find . -name "*tcp*.ovpn" -exec mv {} "${target_dir}/tcp/" \;
    popd > /dev/null || exit
    _pre_config_update "${vpn_provider}" "${target_dir}"
}

# Get PIA (PrivateInternetAccess) Config and update
_update_pia_config() {
    local vpn_provider=$1
    local config_url=$2
    local tmp_dir target_dir
    local files=( "openvpn.zip" "openvpn-ip.zip" "openvpn-strong.zip" "openvpn-tcp.zip" "openvpn-strong-tcp.zip" )
    echo "Getting PIA configs using ${config_url}..."
    tmp_dir=$(mktemp -d /tmp/vpn.XXXXXXXX)
    target_dir=$(mktemp -d /tmp/target.XXXXXXXX)
    mkdir "${target_dir}"/{tcp,udp,ip-udp,strong-udp,strong-tcp}
    pushd "${tmp_dir}" > /dev/null || exit
    for each_file in "${files[@]}"; do
        rm -f -- *
        curl -4 -sSL "${config_url}/${each_file}" -o "${each_file}" || exit
        unzip -o -q "${each_file}" || exit
        if [[ "${each_file}" == "openvpn.zip" ]]; then
             find . -name "*.ovpn*" -exec bash -c 'mv "${1}" "${0}/${1// /_}"' "${target_dir}/udp" {} \;
            _pre_config_update "${vpn_provider}" "${target_dir}" "udp"
        elif [[ "${each_file}" == "openvpn-ip.zip" ]]; then
            find . -name "*.ovpn*" -exec bash -c 'mv "${1}" "${0}/${1// /_}"' "${target_dir}/ip-udp" {} \;
            _pre_config_update "${vpn_provider}" "${target_dir}" "ip-udp"
        elif [[ "${each_file}" == "openvpn-strong.zip" ]]; then
            find . -name "*.ovpn*" -exec bash -c 'mv "${1}" "${0}/${1// /_}"' "${target_dir}/strong-udp" {} \;
            _pre_config_update "${vpn_provider}" "${target_dir}" "strong-udp"
        elif [[ "${each_file}" == "openvpn-tcp.zip" ]]; then
            find . -name "*.ovpn*" -exec bash -c 'mv "${1}" "${0}/${1// /_}"' "${target_dir}/tcp" {} \;
            _pre_config_update "${vpn_provider}" "${target_dir}" "tcp"
        elif [[ "${each_file}" == "openvpn-strong-tcp.zip" ]]; then
            find . -name "*.ovpn*" -exec bash -c 'mv "${1}" "${0}/${1// /_}"' "${target_dir}/strong-tcp" {} \;
            _pre_config_update "${vpn_provider}" "${target_dir}" "strong-tcp"
        fi
    done
    popd > /dev/null || exit
}

# Get VyprVPN configs and update
_update_vyprvpn_config() {
    local vpn_provider=$1
    local config_url=$2
    local extra_pattern=$3
    local tmp_dir target_dir
    echo "Getting VyprVPN configs using ${config_url}..."
    tmp_dir=$(mktemp -d /tmp/vpn.XXXXXXXX)
    target_dir=$(mktemp -d /tmp/target.XXXXXXXX)
    mkdir "${target_dir}"/{tcp,udp}
    pushd "${tmp_dir}" > /dev/null || exit
    curl -4 -sSL "${config_url}" -o vyprvpn.zip || exit
    unzip -q vyprvpn.zip || exit
    find . -name "*.ovpn" -regex ".*${extra_pattern}.*" -exec bash -c 'mv "${1}" "${0}/$(basename ${1// /_})"' "${target_dir}/udp" {} \;
    popd > /dev/null || exit
    _pre_config_update "${vpn_provider}" "${target_dir}" "udp"
}

# Get SurfShark configs and update
_update_surfshark_config() {
    local vpn_provider=$1
    local config_url=$2
    local tmp_dir target_dir
    echo "Getting SurfShark configs using ${config_url}..."
    tmp_dir=$(mktemp -d /tmp/vpn.XXXXXXXX)
    target_dir=$(mktemp -d /tmp/target.XXXXXXXX)
    mkdir "${target_dir}"/{tcp,udp}
    pushd "${tmp_dir}" > /dev/null || exit
    curl -4 -sSL "${config_url}" -o surfshark.zip || exit
    unzip -q surfshark.zip || exit
    find . -name "*udp*.ovpn" -exec mv {} "${target_dir}/udp/" \;
    find . -name "*tcp*.ovpn" -exec mv {} "${target_dir}/tcp/" \;
    popd > /dev/null || exit
    _pre_config_update "${vpn_provider}" "${target_dir}"
}

# Get IPVanish configs and update
_update_ipvanish_config() {
    local vpn_provider=$1
    local config_url=$2
    local tmp_dir target_dir
    echo "Getting IPVanish configs using ${config_url}..."
    tmp_dir=$(mktemp -d /tmp/vpn.XXXXXXXX)
    target_dir=$(mktemp -d /tmp/target.XXXXXXXX)
    mkdir "${target_dir}"/{tcp,udp}
    pushd "${tmp_dir}" > /dev/null || exit
    curl -4 -sSL "${config_url}" -o ipvanish.zip || exit
    unzip -q ipvanish.zip || exit
    find . \( -name "*.ovpn" -o -name "*.crt" \) -exec mv {} "${target_dir}/udp/" \;
    popd > /dev/null || exit
    _pre_config_update "${vpn_provider}" "${target_dir}" "udp"
}

# Get TunnelBear configs and update
_update_tunnelbear_config() {
    local vpn_provider=$1
    local config_url=$2
    local tmp_dir target_dir
    echo "Getting TunnelBear configs using ${config_url}..."
    tmp_dir=$(mktemp -d /tmp/vpn.XXXXXXXX)
    target_dir=$(mktemp -d /tmp/target.XXXXXXXX)
    mkdir "${target_dir}"/{tcp,udp}
    pushd "${tmp_dir}" > /dev/null || exit
    curl -4 -sSL "${config_url}" -o tunnelbear.zip || exit
    unzip -q tunnelbear.zip || exit
    if [[ -d "openvpn" ]]; then
        cd openvpn || exit
    fi
    find . \( -name "*.ovpn" -o -name "*.crt" -o -name "*.key" \) -exec bash -c 'mv "${1}" "${0}/$(basename ${1// /_})"' "${target_dir}/udp" {} \;
    popd > /dev/null || exit
    _pre_config_update "${vpn_provider}" "${target_dir}" "udp"
}

# Get ivpn configs and update
_update_ipvn_config() {
    local vpn_provider=$1
    local config_url=$2
    local tmp_dir target_dir
    echo "Getting IVPN configs using ${config_url}..."
    tmp_dir=$(mktemp -d /tmp/vpn.XXXXXXXX)
    target_dir=$(mktemp -d /tmp/target.XXXXXXXX)
    mkdir "${target_dir}"/{tcp,udp}
    pushd "${tmp_dir}" > /dev/null || exit
    curl -4 -sSL "${config_url}" -o ivpn.zip || exit
    unzip -q ivpn.zip || exit
    find . -name "*udp*.ovpn" -exec mv {} "${target_dir}/udp/" \;
    find . -name "*tcp*.ovpn" -exec mv {} "${target_dir}/tcp/" \;
    find . -name "*.ovpn" -exec mv {} "${target_dir}/udp/" \;
    popd > /dev/null || exit
    _pre_config_update "${vpn_provider}" "${target_dir}" "udp"
}

# Get PrivateVPN configs and update
_update_privatevpn_config() {
    local vpn_provider=$1
    local config_url=$2
    local extra_pattern=$3
    local tmp_dir target_dir
    echo "Getting PrivateVPN configs using ${config_url}..."
    tmp_dir=$(mktemp -d /tmp/vpn.XXXXXXXX)
    target_dir=$(mktemp -d /tmp/target.XXXXXXXX)
    mkdir "${target_dir}"/{tcp,udp}
    pushd "${tmp_dir}" > /dev/null || exit
    curl -4 -sSL "${config_url}" -o privatevpn.zip || exit
    unzip -q privatevpn.zip || exit
    egrep -lRZ 'sndbuf' . | xargs -0 -l sed -i -rE '/^sndbuf .+$/d'
    egrep -lRZ 'rcvbuf' . | xargs -0 -l sed -i -rE '/^rcvbuf .+$/d'
    egrep -lRZ 'ncp-disable' . | xargs -0 -l sed -i -rE '/^ncp-disable/d'
    find . -regextype posix-egrep -type f -regex ".*UDP.*.ovpn" -exec bash -c 'mv "${1}" "${0}/$(basename ${1// /_})"' "${target_dir}/udp" {} \;
    find . -regextype posix-egrep -type f -regex ".*TCP.*.ovpn" -exec bash -c 'mv "${1}" "${0}/$(basename ${1// /_})"' "${target_dir}/tcp" {} \;
    popd > /dev/null || exit
    _pre_config_update "${vpn_provider}" "${target_dir}"
}

# Get BTGuard configs and update
_update_btguard_config() {
    local vpn_provider=$1
    local config_url=$2
    local extra_pattern=$3
    local tmp_dir target_dir
    echo "Getting BTGuard configs using ${config_url}..."
    tmp_dir=$(mktemp -d /tmp/vpn.XXXXXXXX)
    target_dir=$(mktemp -d /tmp/target.XXXXXXXX)
    mkdir "${target_dir}"/{tcp,udp}
    pushd "${tmp_dir}" > /dev/null || exit
    curl -4 -sSL "${config_url}" -o btguard.zip || exit
    unzip -q btguard.zip || exit
    find . -name "*TCP*.ovpn" -exec bash -c 'mv "${1}" "${0}/$(basename ${1// /_})"' "${target_dir}/tcp" {} \;
    find . -name "*.ovpn" -exec bash -c 'mv "${1}" "${0}/$(basename ${1// /_})"' "${target_dir}/udp" {} \;
    popd > /dev/null || exit
    _pre_config_update "${vpn_provider}" "${target_dir}"
}
