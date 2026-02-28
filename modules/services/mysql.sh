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

# Enable service
_mysql_svc=""
if systemctl list-unit-files 2>/dev/null | grep -q "^mysql.service"; then
    _mysql_svc="mysql"
elif systemctl list-unit-files 2>/dev/null | grep -q "^mariadb.service"; then
    _mysql_svc="mariadb"
fi

if [[ -n "$_mysql_svc" ]]; then
    sudo systemctl enable --now "$_mysql_svc" &>/dev/null || true
fi

# ── Wait for MySQL socket to be ready ────────────────────────
log "Waiting for MySQL to be ready..."
_mysql_ready=false
for _i in $(seq 1 15); do
    # Try both common socket locations
    if sudo mysqladmin ping --silent 2>/dev/null; then
        _mysql_ready=true
        break
    fi
    sleep 2
done

if [[ "$_mysql_ready" != "true" ]]; then
    warn "MySQL did not respond to ping -- skipping auth config"
    warn "Run manually once MySQL is up:"
    warn "  sudo mysql -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;\""
    return
fi

# ── Root password auth fix ───────────────────────────────────
# Determine the current auth plugin for root
_current_plugin=$(sudo mysql -N -e \
    "SELECT plugin FROM mysql.user WHERE User='root' AND Host='localhost';" \
    2>/dev/null || echo "unknown")

log "Current root auth plugin: ${_current_plugin}"

if [[ "$_current_plugin" == "mysql_native_password" ]]; then
    # Already using password auth -- just update the password
    if sudo mysql -e \
        "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;" \
        &>/dev/null; then
        success "MySQL root password updated"
    else
        warn "Could not update MySQL root password"
    fi
else
    # Switch from unix_socket / auth_socket / caching_sha2 to native password
    if sudo mysql -e "
        ALTER USER 'root'@'localhost'
            IDENTIFIED WITH mysql_native_password
            BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
    " &>/dev/null; then
        success "MySQL root auth configured (native password)"
    else
        warn "Could not update MySQL root auth -- try manually:"
        warn "  sudo mysql -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;\""
    fi
fi