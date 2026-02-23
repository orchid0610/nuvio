#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$ROOT_DIR/config/settings.yaml"

# Load core utils
source "$ROOT_DIR/modules/core/utils.sh"
source "$ROOT_DIR/modules/core/base.sh"

# Load config
USERNAME=$(grep '^username:' "$CONFIG_FILE" | awk '{print $2}')
ROOT_FOLDER=$(grep '^root_folder:' "$CONFIG_FILE" | awk '{print $2}')
ROOT_PATH="/home/$USERNAME/$ROOT_FOLDER"
mkdir -p "$ROOT_PATH"

NGINX_INSTALL=$(grep '^nginx_install:' "$CONFIG_FILE" | awk '{print $2}')
MYSQL_INSTALL=$(grep '^mysql_install:' "$CONFIG_FILE" | awk '{print $2}')
PHPMYADMIN_INSTALL=$(grep '^phpmyadmin_install:' "$CONFIG_FILE" | awk '{print $2}')
PHP_INSTALL=$(grep '^php_install:' "$CONFIG_FILE" | awk '{print $2}')

PHP_VERSIONS=($(grep 'php_versions:' -A 3 "$CONFIG_FILE" | grep '-' | awk '{print $2}'))

# Run modules
run_module core/system
run_module packages/php
run_module services/nginx
run_module services/mysql
run_module services/phpmyadmin
run_module scripts/scripts