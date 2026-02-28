#!/usr/bin/env bash
# ============================================================
#  modules/services/mysql.sh — MySQL / MariaDB install
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

    # Enable whichever service name exists
    if systemctl list-unit-files | grep -q "mysql.service"; then
        sudo systemctl enable --now mysql &>/dev/null
    else
        sudo systemctl enable --now mariadb &>/dev/null
    fi

    status_done "MySQL Server"
fi

# ── Root password auth fix ───────────────────────────────────
# Fresh Ubuntu/Debian installs use unix_socket auth by default,
# which blocks phpMyAdmin from connecting with a password.
# This switches root to mysql_native_password.
log "Configuring MySQL root authentication..."
if sudo mysql -e "SELECT 1;" &>/dev/null; then
    sudo mysql -e "
        ALTER USER 'root'@'localhost'
            IDENTIFIED WITH mysql_native_password
            BY '${MYSQL_ROOT_PASSWORD}';
        FLUSH PRIVILEGES;
    " &>/dev/null && success "MySQL root auth set (password login enabled)" \
                  || warn "Could not update MySQL root auth — check manually"
else
    warn "Could not connect to MySQL as root — skipping auth config"
fi