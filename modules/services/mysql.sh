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

# ── Enable service ───────────────────────────────────────────
_mysql_svc=""
if systemctl list-unit-files 2>/dev/null | grep -q "^mysql.service"; then
    _mysql_svc="mysql"
elif systemctl list-unit-files 2>/dev/null | grep -q "^mariadb.service"; then
    _mysql_svc="mariadb"
fi
if [[ -n "$_mysql_svc" ]]; then
    sudo systemctl enable --now "$_mysql_svc" &>/dev/null || true
fi

# ── Wait for MySQL to be ready ───────────────────────────────
log "Waiting for MySQL to be ready..."
_mysql_ready=false
for _i in $(seq 1 15); do
    if sudo mysqladmin ping --silent 2>/dev/null; then
        _mysql_ready=true
        break
    fi
    sleep 2
done

if [[ "$_mysql_ready" != "true" ]]; then
    warn "MySQL did not respond -- skipping auth config"
    return
fi

# ── Check if root already works with the configured password ─
if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" &>/dev/null; then
    status_skipped "MySQL root auth (password already set correctly)"
    return
fi

# ── Get a working admin connection ───────────────────────────
# Try in order: debian-sys-maint, passwordless sudo, then give up
_mysql_cmd=""
_DEBIAN_CNF="/etc/mysql/debian.cnf"

if [[ -f "$_DEBIAN_CNF" ]] && sudo mysql --defaults-file="$_DEBIAN_CNF" -e "SELECT 1;" &>/dev/null; then
    _mysql_cmd="sudo mysql --defaults-file=$_DEBIAN_CNF"
elif sudo mysql -e "SELECT 1;" &>/dev/null; then
    _mysql_cmd="sudo mysql"
fi

if [[ -z "$_mysql_cmd" ]]; then
    warn "Cannot connect to MySQL as admin -- skipping auth config"
    warn "Run manually:  mysql -u root -p'CURRENT_PASSWORD' -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;\""
    return
fi

# ── Apply the fix ────────────────────────────────────────────
if ${_mysql_cmd} -e "
    ALTER USER 'root'@'localhost'
        IDENTIFIED WITH mysql_native_password
        BY '${MYSQL_ROOT_PASSWORD}';
    FLUSH PRIVILEGES;
" &>/dev/null; then
    success "MySQL root password set to configured value"
else
    warn "Could not update MySQL root password -- run manually:"
    warn "  ${_mysql_cmd} -e \"ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES;\""
fi