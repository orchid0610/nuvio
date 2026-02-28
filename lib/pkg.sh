#!/usr/bin/env bash
# ============================================================
#  lib/pkg.sh — distro-agnostic package manager helpers
#  Requires: lib/log.sh
# ============================================================

PKG_MANAGER=""

# Detect and export the active package manager
pkg_detect() {
    if command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
    else
        error "No supported package manager found (apt / dnf / pacman)."
    fi
    log "Package manager: ${PKG_MANAGER}"
    export PKG_MANAGER
}

# Update package index + upgrade installed packages
pkg_update() {
    section "System Update"
    case "$PKG_MANAGER" in
        apt)    run_quiet "Updating package index"  sudo apt update -y
                run_quiet "Upgrading packages"      sudo apt upgrade -y ;;
        dnf)    run_quiet "Upgrading packages"      sudo dnf upgrade -y ;;
        pacman) run_quiet "Upgrading packages"      sudo pacman -Syu --noconfirm ;;
    esac
}

# Install one or more packages
pkg_install() {
    case "$PKG_MANAGER" in
        apt)    sudo apt install -y "$@" &>/dev/null ;;
        dnf)    sudo dnf install -y "$@" &>/dev/null ;;
        pacman) sudo pacman -S --noconfirm "$@" &>/dev/null ;;
    esac
}

# Returns 0 if the package is installed, 1 otherwise
pkg_installed() {
    local pkg="$1"
    case "$PKG_MANAGER" in
        apt)    dpkg -s "$pkg" &>/dev/null ;;
        dnf)    rpm -q "$pkg" &>/dev/null ;;
        pacman) pacman -Qi "$pkg" &>/dev/null ;;
    esac
}
