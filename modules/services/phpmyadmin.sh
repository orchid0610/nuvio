#!/usr/bin/env bash

[[ "$PHPMYADMIN_INSTALL" == true ]] || { status_skipped "phpMyAdmin module"; return; }

if [ "$PKG_MANAGER" != "apt" ]; then
    warn "phpMyAdmin module skipped: only supported on Debian/Ubuntu"
    return
fi

if [ -d /usr/share/phpmyadmin ]; then
    status_skipped "phpMyAdmin"
else
    status_installing "Installing phpMyAdmin"
    (
        echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | sudo debconf-set-selections
        echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | sudo debconf-set-selections
        sudo DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin
    ) &
    pid=$!
    spinner $pid
    wait $pid
    status_done "phpMyAdmin"
fi

# Add nginx config
if [ ! -f /etc/nginx/sites-available/phpmyadmin ]; then
    status_installing "Creating phpMyAdmin Nginx config"
    sudo tee /etc/nginx/sites-available/phpmyadmin >/dev/null <<EOL
server {
    listen 80;
    server_name phpmyadmin.test;
    root /usr/share/phpmyadmin;

    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL
    sudo ln -sf /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/
    echo "127.0.0.1 phpmyadmin.test" | sudo tee -a /etc/hosts >/dev/null
    status_done "phpMyAdmin Nginx config added"
fi

sudo systemctl reload nginx
status_done "Nginx reloaded"