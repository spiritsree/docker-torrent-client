# shellcheck shell=bash

# Permission update
# Syntax: _perm_update <dir> <uid>
_perm_update() {
    local dir_path=$1
    local user_id=$2

    echo "[TRANSMISSION] Changing ownership of dir ${dir_path} to ${user_id}..."
    if (getent group "${user_id}" > /dev/null 2>&1) &&
        (getent passwd "${user_id}" > /dev/null 2>&1); then
        chown -R "${user_id}:${user_id}" "${dir_path}"
        chmod -R 775 "${dir_path}"
    else
        echo "[TRANSMISSION] User/Group ${user_id} does not exist. Please run it as root..."
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
