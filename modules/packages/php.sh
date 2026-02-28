#!/usr/bin/env bash
# ============================================================
#  modules/packages/php.sh — PHP multi-version install
# ============================================================

section "PHP"

if [[ "$PHP_INSTALL" != "true" ]]; then
    status_skipped "PHP (disabled in config)"
    return
fi

# ── PPA (apt only) ───────────────────────────────────────────
if [[ "$PKG_MANAGER" == "apt" ]]; then
    if grep -rq "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
        status_skipped "PHP PPA (already added)"
    else
        run_quiet "Adding PHP PPA (ondrej/php)" \
            bash -c "sudo apt install -y software-properties-common \
                     && sudo add-apt-repository ppa:ondrej/php -y \
                     && sudo apt update -y"
    fi
fi

# ── Per-version install ──────────────────────────────────────
for version in "${PHP_VERSIONS_ARR[@]}"; do

    if pkg_installed "php${version}-fpm" || pkg_installed "php-fpm"; then
        status_skipped "PHP ${version} (already installed)"
        continue
    fi

    run_quiet "Installing PHP ${version}" \
        bash -c "_php_install_version ${version}"

    # Enable FPM service
    local svc="php${version}-fpm"
    if ! systemctl list-unit-files | grep -q "${svc}.service"; then
        svc="php-fpm"
    fi
    sudo systemctl enable --now "$svc" &>/dev/null || warn "Could not enable ${svc}"

    if pkg_installed "php${version}-fpm" || pkg_installed "php-fpm"; then
        status_done "PHP ${version}"
    else
        status_fail "PHP ${version}"
    fi
done

# ── PHP CLI alternatives (apt only) ─────────────────────────
if [[ "$PKG_MANAGER" == "apt" ]]; then
    if update-alternatives --list php &>/dev/null; then
        status_skipped "PHP CLI alternatives (already configured)"
    else
        log "Configuring PHP CLI alternatives..."
        for version in "${PHP_VERSIONS_ARR[@]}"; do
            sudo update-alternatives --install /usr/bin/php php \
                "/usr/bin/php${version}" "${version//./}" &>/dev/null
        done
        # Set the last (highest) version as default
        local latest="${PHP_VERSIONS_ARR[-1]}"
        sudo update-alternatives --set php "/usr/bin/php${latest}" &>/dev/null
        success "PHP CLI default → php${latest}"
    fi
fi

# ── Internal helper ──────────────────────────────────────────
_php_install_version() {
    local ver="$1"
    case "$PKG_MANAGER" in
        apt)
            pkg_install \
                "php${ver}" "php${ver}-fpm" "php${ver}-cli" "php${ver}-mysql" \
                "php${ver}-mbstring" "php${ver}-xml" "php${ver}-curl" \
                "php${ver}-zip" "php${ver}-bcmath" "php${ver}-intl" \
                "php${ver}-readline"
            ;;
        dnf)
            pkg_install php php-fpm php-cli php-mysqlnd php-mbstring \
                        php-xml php-curl php-zip php-bcmath php-intl
            ;;
        pacman)
            pkg_install php php-fpm php-intl php-mbstring \
                        php-curl php-xml php-zip php-bcmath
            ;;
    esac
}
