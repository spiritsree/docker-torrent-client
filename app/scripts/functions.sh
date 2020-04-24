# shellcheck shell=bash

# Convert to lower case
_lowercase() {
    local in=$1
    local out=''
    out=$(echo "${in}" | tr '[:upper:]' '[:lower:]')
    echo "${out}"
}

# Function to allow port/IP in firewall
_firewall_allow_port() {
    local port
    local source_ip
    port=$1
    source_ip=$2

    if [[ -n "${port-}" ]]; then
        if [[ -n "${source_ip-}" ]]; then
            echo "[FIREWALL] Allowing IP ${source_ip} to port ${port} in firewall..."
            ufw allow from "${source_ip}" to any port "${port}" > /dev/null
        else
            echo "[FIREWALL] Allowing port ${port} in firewall..."
            ufw allow "${port}" > /dev/null
        fi
    fi
}

# Get settings if config exists
_get_settings() {
    local client=$1
    local settings_file=$2

    for setting in $(jq -r 'to_entries | map(.key + "=" + (.value | tostring)) | .[]' "${settings_file}"); do
        key=$(echo "${client}_${setting%=*}" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
        value=${setting#*=}
        if [[ -z "$(printf '%s' "${!key}")" ]]; then
            eval "export $key=$value"
        fi
    done
}

# Get default GW/interface/network
_get_default_gw() {
    export DEF_GW=''
    export DEF_INT=''
    export DEF_GW_CIDR=''
    eval "$( ip route list match 0.0.0.0 | \
             awk '{ if ($5 != "tun0")
                    {
                        print "export DEF_GW="$3;
                        print "export DEF_INT="$5;
                        exit;
                    }
                }'
        )"
    eval "$( ip route list dev "${DEF_INT}" | \
             awk '{ if ($5 == "link")
                    {
                            print "export DEF_GW_CIDR="$1;
                            exit;
                    }
                }'
            )"
}

# Permission update
# Syntax: _perm_update <dir> <uid>
_perm_update() {
    local dir_path=$1
    local user_id=$2

    echo "[CLIENT] Changing ownership of dir ${dir_path} to ${user_id}..."
    if (getent group "${user_id}" > /dev/null 2>&1) &&
        (getent passwd "${user_id}" > /dev/null 2>&1); then
        chown -R "${user_id}:${user_id}" "${dir_path}"
        chmod -R 775 "${dir_path}"
    else
        echo "[CLIENT] User/Group ${user_id} does not exist. Please run it as root..."
        exit 1
    fi
}

# Create dir if not exist and update permission
# Syntax: _create_dir_perm <dir> <uid>
_create_dir_perm() {
    local dir_path=$1
    local user_id=$2

    if [[ ! -d "${dir_path}" ]]; then
        mkdir -p "${dir_path}"
    fi

    _perm_update "${dir_path}" "${user_id}"
}
