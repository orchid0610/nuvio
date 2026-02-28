#!/usr/bin/env bash
# ============================================================
#  modules/services/mysql.sh -- MySQL / MariaDB install
# ============================================================

section "MySQL"

if [[ "$MYSQL_INSTALL" != "true" ]]; then
    status_skipped "MySQL (disabled in config)"
    return
fi

case "$PKG_MANAGER" in
    apt|dnf) _mysql_pkg="mysql-server" ;;
    pacman)  _mysql_pkg="mariadb" ;;
esac

if pkg_installed "$_mysql_pkg"; then
    status_skipped "MySQL (already installed)"
else
    run_quiet "Installing MySQL Server" pkg_install "$_mysql_pkg"
    status_done "MySQL Server"
fi

# Enable service -- check name without letting grep exit code kill the script
_mysql_svc=""
if systemctl list-unit-files 2>/dev/null | grep -q "^mysql.service"; then
    _mysql_svc="mysql"
elif systemctl list-unit-files 2>/dev/null | grep -q "^mariadb.service"; then
    _mysql_svc="mariadb"
fi

if [[ -n "$_mysql_svc" ]]; then
    sudo systemctl enable --now "$_mysql_svc" &>/dev/null || true
fi

# ── Root password auth fix ───────────────────────────────────
# Fresh Ubuntu/Debian installs use unix_socket auth by default,
# which blocks phpMyAdmin from connecting with a password.
# This switches root to mysql_native_password.
log "Configuring MySQL root authentication..."

if sudo mysql -e "SELECT 1;" &>/dev/null; then
    if sudo mysql -e "
        ALTER USER 'root'@'localhost'
            IDENTIFIED WITH mysql_native_password
            BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
    " &>/dev/null; then
        success "MySQL root auth configured"
    else
        warn "Could not update MySQL root auth -- run manually if needed"
    fi
else
    warn "Could not connect to MySQL -- skipping auth config"
fi