#!/usr/bin/env bash
# ============================================================
#  install.sh — nuvio entry point
#  Run directly after cloning, or via bootstrap.sh
# ============================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load libraries ───────────────────────────────────────────
source "$ROOT_DIR/lib/log.sh"
source "$ROOT_DIR/lib/pkg.sh"
source "$ROOT_DIR/lib/config.sh"

# ── Banner ───────────────────────────────────────────────────
print_banner

# ── Interactive prompts ──────────────────────────────────────
prompt_user      # asks for username + projects folder
config_load      # loads module flags + PHP versions from settings.env
pkg_detect       # detects apt / dnf / pacman

# ── Confirm before proceeding ────────────────────────────────
echo -e "  ${DIM}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RESET}"
log "User       : $USERNAME"
log "Projects   : $ROOT_PATH"
log "Distro     : $PKG_MANAGER"
log "PHP vers   : ${PHP_VERSIONS_ARR[*]}"
log "MySQL root : $MYSQL_ROOT_PASSWORD"
echo -e "  ${DIM}┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RESET}"
echo ""

if ! confirm "Everything look good? Start install"; then
    echo ""; log "Aborted."; echo ""; exit 0
fi
echo ""

mkdir -p "$ROOT_PATH"

# ── Helper: source a module by relative path ─────────────────
run_module() {
    local module="$1"
    local path="$ROOT_DIR/modules/${module}.sh"
    [[ -f "$path" ]] || error "Module not found: modules/${module}.sh"
    # shellcheck disable=SC1090
    source "$path"
}

# ── Modules ──────────────────────────────────────────────────
#  Add or remove lines here to control what gets installed.
run_module core/system
run_module packages/php
run_module services/nginx
run_module services/mysql
run_module services/phpmyadmin
run_module scripts/new-site-installer

# ── Summary ──────────────────────────────────────────────────
declare -A summary

summary["User"]="$USERNAME"
summary["www"]="$ROOT_PATH"
[[ "$PHP_INSTALL"       == "true" ]] && summary["PHP"]="${PHP_VERSIONS_ARR[*]}"
[[ "$NGINX_INSTALL"     == "true" ]] && summary["Nginx"]="http://localhost"
[[ "$MYSQL_INSTALL"     == "true" ]] && summary["MySQL"]="root / $MYSQL_ROOT_PASSWORD"
[[ "$PHPMYADMIN_INSTALL" == "true" ]] && summary["phpMyAdmin"]="http://phpmyadmin.test"
summary["new-site"]="sudo new-site <project>"

print_summary summary