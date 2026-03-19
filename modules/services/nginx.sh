#!/usr/bin/env bash
# ============================================================
#  modules/services/nginx.sh — Nginx install & basic config
# ============================================================

section "Nginx"

if [[ "$NGINX_INSTALL" != "true" ]]; then
    status_skipped "Nginx (disabled in config)"
    return
fi

if pkg_installed nginx; then
    status_skipped "Nginx (already installed)"
else
    run_quiet "Installing Nginx" pkg_install nginx
    sudo systemctl enable --now nginx &>/dev/null || true
    status_done "Nginx"
fi

# Remove default site (Debian/Ubuntu)
if [[ -f /etc/nginx/sites-enabled/default ]]; then
    sudo rm -f /etc/nginx/sites-enabled/default
    success "Default Nginx site removed"
else
    status_skipped "Default Nginx site (not present)"
fi
