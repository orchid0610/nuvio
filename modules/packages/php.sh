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
for _ver in "${PHP_VERSIONS_ARR[@]}"; do

    if pkg_installed "php${_ver}-fpm" || pkg_installed "php-fpm"; then
        status_skipped "PHP ${_ver} (already installed)"
        continue
    fi

    # Build the package list inline — no subshell function needed
    case "$PKG_MANAGER" in
        apt)
            run_quiet "Installing PHP ${_ver}" \
                sudo apt install -y \
                    "php${_ver}" "php${_ver}-fpm" "php${_ver}-cli" \
                    "php${_ver}-mysql" "php${_ver}-mbstring" "php${_ver}-xml" \
                    "php${_ver}-curl" "php${_ver}-zip" "php${_ver}-bcmath" \
                    "php${_ver}-intl" "php${_ver}-readline"
            ;;
        dnf)
            run_quiet "Installing PHP ${_ver}" \
                sudo dnf install -y php php-fpm php-cli php-mysqlnd \
                    php-mbstring php-xml php-curl php-zip php-bcmath php-intl
            ;;
        pacman)
            run_quiet "Installing PHP ${_ver}" \
                sudo pacman -S --noconfirm php php-fpm php-intl \
                    php-mbstring php-curl php-xml php-zip php-bcmath
            ;;
    esac

    # Enable FPM service — safe grep with || true
    _php_svc=""
    if systemctl list-unit-files 2>/dev/null | grep -q "php${_ver}-fpm.service"; then
        _php_svc="php${_ver}-fpm"
    elif systemctl list-unit-files 2>/dev/null | grep -q "php-fpm.service"; then
        _php_svc="php-fpm"
    fi
    if [[ -n "$_php_svc" ]]; then
        sudo systemctl enable --now "$_php_svc" &>/dev/null || true
    fi

    if pkg_installed "php${_ver}-fpm" || pkg_installed "php-fpm"; then
        status_done "PHP ${_ver}"
    else
        status_fail "PHP ${_ver}"
    fi
done

# ── PHP CLI alternatives (apt only) ─────────────────────────
if [[ "$PKG_MANAGER" == "apt" ]]; then
    if update-alternatives --list php &>/dev/null; then
        status_skipped "PHP CLI alternatives (already configured)"
    else
        log "Configuring PHP CLI alternatives..."
        for _ver in "${PHP_VERSIONS_ARR[@]}"; do
            sudo update-alternatives --install /usr/bin/php php \
                "/usr/bin/php${_ver}" "${_ver//./}" &>/dev/null || true
        done
        _latest="${PHP_VERSIONS_ARR[-1]}"
        sudo update-alternatives --set php "/usr/bin/php${_latest}" &>/dev/null || true
        success "PHP CLI default → php${_latest}"
    fi
fi
