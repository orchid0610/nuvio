#!/usr/bin/env bash
# ============================================================
#  lib/config.sh -- load settings.env + prompt for user info
#  Requires: lib/log.sh
# ============================================================

# Interactive prompts for username, project folder, MySQL password.
# Uses plain locals to avoid nameref issues under set -euo pipefail.
prompt_user() {
    section "Setup"

    local default_user="${SUDO_USER:-$USER}"
    local _u _f _p

    prompt_input _u "Linux username"      "$default_user"
    prompt_input _f "Projects folder"     "www"
    prompt_input _p "MySQL root password" "1234"

    USERNAME="$_u"
    ROOT_FOLDER="$_f"
    MYSQL_ROOT_PASSWORD="$_p"
    echo ""

    # Validate username exists -- subshell prevents set -e from firing
    if ! ( id "$USERNAME" &>/dev/null ); then
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