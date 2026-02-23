#!/usr/bin/env bash

[[ "$NGINX_INSTALL" == true ]] || { status_skipped "Nginx module"; return; }

if is_installed nginx; then
    status_skipped "Nginx"
else
    status_installing "Installing Nginx"
    install_pkg nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    status_done "Nginx"
fi

# Disable default site (mostly Debian/Ubuntu)
if [ -f /etc/nginx/sites-enabled/default ]; then
    status_installing "Removing default Nginx site"
    sudo rm -f /etc/nginx/sites-enabled/default
    status_done "Default Nginx site removed"
else
    status_skipped "Default Nginx site"
fi