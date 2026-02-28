#!/usr/bin/env bash
# ============================================================
#  lib/config.sh — load settings.env + prompt for user info
#  Requires: lib/log.sh
# ============================================================

# Interactive prompts for username and project folder.
# Called before config_load so values are available globally.
prompt_user() {
    section "Setup"

    # Suggest the current logged-in user as default
    local default_user="${SUDO_USER:-$USER}"

    prompt_input USERNAME    "Linux username"   "$default_user"
    prompt_input ROOT_FOLDER "Projects folder"  "www"
    prompt_input MYSQL_ROOT_PASSWORD "MySQL root password" "root"
    echo ""

    # Validate username exists on the system
    if ! id "$USERNAME" &>/dev/null; then
        error "User '$USERNAME' does not exist on this system."
    fi

    USER_HOME="/home/$USERNAME"
    ROOT_PATH="$USER_HOME/$ROOT_FOLDER"

    export USERNAME ROOT_FOLDER USER_HOME ROOT_PATH MYSQL_ROOT_PASSWORD
}

config_load() {
    local config_file="$ROOT_DIR/config/settings.env"
    [[ -f "$config_file" ]] || error "Config file not found: $config_file"

    # Source only valid VAR=value lines (skip comments and blanks)
    set -a
    # shellcheck disable=SC1090
    source <(grep -E '^\s*[A-Z_]+=.*' "$config_file")
    set +a

    _require_var PHP_VERSIONS || error "PHP_VERSIONS missing from config/settings.env"

    # Normalize booleans to lowercase
    NGINX_INSTALL="${NGINX_INSTALL,,}"
    MYSQL_INSTALL="${MYSQL_INSTALL,,}"
    PHPMYADMIN_INSTALL="${PHPMYADMIN_INSTALL,,}"
    PHP_INSTALL="${PHP_INSTALL,,}"

    # Convert PHP_VERSIONS string to array
    read -ra PHP_VERSIONS_ARR <<< "$PHP_VERSIONS"

    export NGINX_INSTALL MYSQL_INSTALL PHPMYADMIN_INSTALL PHP_INSTALL
    export PHP_VERSIONS_ARR
}

_require_var() {
    local var="$1"
    if [[ -z "${!var:-}" ]]; then
        warn "Missing required config value: $var"
        return 1
    fi
}