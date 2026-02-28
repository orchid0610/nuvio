#!/usr/bin/env bash
# ============================================================
#  modules/services/phpmyadmin.sh — phpMyAdmin install
#  Only supported on Debian / Ubuntu (apt)
# ============================================================

section "phpMyAdmin"

if [[ "$PHPMYADMIN_INSTALL" != "true" ]]; then
    status_skipped "phpMyAdmin (disabled in config)"
    return
fi

if [[ "$PKG_MANAGER" != "apt" ]]; then
    warn "phpMyAdmin module only supported on Debian/Ubuntu — skipping"
    return
fi

# ── Install ──────────────────────────────────────────────────
if [[ -d /usr/share/phpmyadmin ]]; then
    status_skipped "phpMyAdmin (already installed)"
else
    run_quiet "Installing phpMyAdmin" \
        bash -c "echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect none' \
                     | sudo debconf-set-selections \
                 && echo 'phpmyadmin phpmyadmin/dbconfig-install boolean false' \
                     | sudo debconf-set-selections \
                 && sudo DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin"
    status_done "phpMyAdmin"
fi

# ── Nginx vhost ──────────────────────────────────────────────
local vhost=/etc/nginx/sites-available/phpmyadmin
local php_sock_version="${PHP_VERSIONS_ARR[-1]}"   # use highest configured version

if [[ -f "$vhost" ]]; then
    status_skipped "phpMyAdmin Nginx vhost (already exists)"
else
    log "Creating phpMyAdmin Nginx vhost (phpmyadmin.test → php${php_sock_version}-fpm)"
    sudo tee "$vhost" >/dev/null <<NGINX
server {
    listen 80;
    server_name phpmyadmin.test;
    root /usr/share/phpmyadmin;

    index index.php index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${php_sock_version}-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINX
    sudo ln -sf "$vhost" /etc/nginx/sites-enabled/phpmyadmin
    success "phpMyAdmin Nginx vhost created"
fi

# ── /etc/hosts entry ─────────────────────────────────────────
if grep -q "phpmyadmin.test" /etc/hosts; then
    status_skipped "hosts entry (phpmyadmin.test)"
else
    echo "127.0.0.1 phpmyadmin.test" | sudo tee -a /etc/hosts >/dev/null
    success "Added phpmyadmin.test to /etc/hosts"
fi

# ── Reload Nginx ─────────────────────────────────────────────
sudo nginx -t &>/dev/null && sudo systemctl reload nginx &>/dev/null \
    && success "Nginx reloaded" \
    || warn "Nginx config test failed — check manually"
