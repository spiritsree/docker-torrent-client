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
    local mount_dir="/config"
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
        jq -c --argjson servers "$(jq -r -c --slurp --raw-input 'split("\n")[:-1]' "${server_file}")" ".${json_key_name}.${vpn_proto} = \$servers" "${main_json_file}" > "${tmp_file}"
    fi
    mv "${tmp_file}" "${main_json_file}"
}

# Make config template
_update_config() {
    local config_dir=$1
    local vpn_provider=$2
    local proto=$3
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
    _update_server_json "${tmp_host_file}" "${vpn_provider}" "${proto}" "${parent_config_path}"
    sed -i 's/^auth-user-pass$/auth-user-pass \/control\/ovpn-auth.txt/' -- *.ovpn
    sed -i -rE 's/^remote .+ ([[:digit:]]+)$/remote {{ .Env.OPENVPN_HOSTNAME }} \1/' -- *.ovpn
    if [[ ! -d "${parent_config_path}/${vpn_provider}/${proto}" ]]; then
        mkdir -p "${parent_config_path}/${vpn_provider}/${proto}"
    fi
    files_to_process=$(find . -type f -regextype egrep -iregex '.*?\.ovpn' -printf '%P\n')
    for file in ${files_to_process}; do
        if [[ ! -f "default.ovpn.tmpl" ]]; then
            cp "${file}" default.ovpn.tmpl
        fi
        if ! diff -q -B -b -Z  default.ovpn.tmpl "${file}" > /dev/null; then
            status="fail"
        fi
    done
    if [[ "${status}" == "success" ]]; then
        mv default.ovpn.tmpl "${parent_config_path}/${vpn_provider}/${proto}/default.ovpn.tmpl"
    fi
    popd > /dev/null || exit
}

# Get HideMyAss Config and update
_update_hidemyass_config() {
    echo "Getting HideMyAss configs..."
    local config_uri=$1
    local tmp_dir ovpn_files target_dir config_domain
    config_domain=$(echo "${config_uri}" | awk -F'/' '{ print $3 }')
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
        "${config_uri}"
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
    pushd "${target_dir}" > /dev/null || exit
    pushd tcp > /dev/null || exit
    _update_config "$(pwd)" 'HideMyAss' 'tcp'
    popd > /dev/null || exit
    pushd udp > /dev/null || exit
    _update_config "$(pwd)" 'HideMyAss' 'udp'
    popd > /dev/null || exit
    popd > /dev/null || exit
}
