#!/usr/bin/env bash

[[ "$PHP_INSTALL" == true ]] || { status_skipped "PHP module"; return; }

# Add repository only for apt (Ubuntu/Debian)
if [ "$PKG_MANAGER" = "apt" ]; then
    if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        status_installing "Adding PHP PPA"
        (sudo apt install -y software-properties-common &&
         sudo add-apt-repository ppa:ondrej/php -y &&
         sudo apt update -y) &
        pid=$!
        spinner $pid
        wait $pid
        status_done "PHP PPA added"
    else
        status_skipped "PHP PPA"
    fi
fi

# Install each PHP version
for version in "${PHP_VERSIONS[@]}"; do
    if is_installed "php$version-fpm"; then
        status_skipped "PHP $version"
        continue
    fi

    status_installing "PHP $version and extensions"
    (
        # Package names may differ slightly per distro
        case "$PKG_MANAGER" in
            apt)
                install_pkg "php$version php$version-fpm php$version-cli php$version-mysql \
                    php$version-mbstring php$version-xml php$version-curl php$version-zip \
                    php$version-bcmath php$version-intl php$version-readline"
                ;;
            dnf)
                install_pkg "php php-fpm php-cli php-mysqlnd php-mbstring php-xml php-curl \
                    php-zip php-bcmath php-intl"
                ;;
            pacman)
                install_pkg "php php-fpm php-intl php-mbstring php-curl php-xml php-zip php-bcmath"
                ;;
        esac

        # Enable and start FPM if exists
        if systemctl list-units --type=service | grep -q "php$version-fpm"; then
            sudo systemctl enable php$version-fpm
            sudo systemctl start php$version-fpm
        elif systemctl list-units --type=service | grep -q "php-fpm"; then
            sudo systemctl enable php-fpm
            sudo systemctl start php-fpm
        fi
    ) &
    pid=$!
    spinner $pid
    wait $pid

    if is_installed "php$version-fpm" || is_installed "php-fpm"; then
        status_done "PHP $version"
    else
        status_fail "PHP $version"
    fi
done

# Configure PHP CLI alternatives (Ubuntu/Debian only)
if [ "$PKG_MANAGER" = "apt" ]; then
    if ! update-alternatives --list php &>/dev/null; then
        status_installing "Configuring PHP CLI alternatives"
        for version in "${PHP_VERSIONS[@]}"; do
            sudo update-alternatives --install /usr/bin/php php /usr/bin/php$version ${version/./}
        done
        sudo update-alternatives --set php /usr/bin/php${PHP_VERSIONS[-1]/./}
        status_done "PHP CLI alternatives configured"
    else
        status_skipped "PHP CLI alternatives"
    fi
fi