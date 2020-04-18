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
    local settings_file=$1

    for setting in $(jq -r 'to_entries | map(.key + "=" + (.value | tostring)) | .[]' "${settings_file}"); do
        key=$(echo "transmission_${setting%=*}" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
        value=${setting#*=}
        if [[ -z "$(printf '%s' "${!key}")" ]]; then
            eval "export $key=$value"
        fi
    done
}

# Get default GW/interface/network
_get_default_gw() {
    export def_gateway=''
    export def_interface=''
    export def_gateway_net=''
    eval "$( ip route list match 0.0.0.0 | \
             awk '{ if ($5 != "tun0")
                    {
                        print "export def_gateway="$3;
                        print "export def_interface="$5;
                        exit;
                    }
                }'
        )"
    eval "$( ip route list dev "${def_interface}" | \
             awk '{ if ($5 == "link")
                    {
                            print "export def_gateway_net="$1;
                            exit;
                    }
                }'
            )"
}
