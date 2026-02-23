#!/usr/bin/env bash

[[ "$MYSQL_INSTALL" == true ]] || { status_skipped "MySQL module"; return; }

# Package names per distro
case "$PKG_MANAGER" in
    apt) MYSQL_PKG="mysql-server" ;;
    dnf) MYSQL_PKG="mysql-server" ;;
    pacman) MYSQL_PKG="mariadb" ;;
esac

if is_installed "$MYSQL_PKG"; then
    status_skipped "MySQL"
else
    status_installing "Installing MySQL Server"
    install_pkg "$MYSQL_PKG"
    sudo systemctl enable mysql || sudo systemctl enable mariadb
    sudo systemctl start mysql || sudo systemctl start mariadb
    status_done "MySQL Server"
fi