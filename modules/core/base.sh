#!/usr/bin/env bash

# Detect package manager
detect_package_manager() {
    if command -v apt >/dev/null; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt install -y"
        UPDATE_CMD="sudo apt update -y && sudo apt upgrade -y"
    elif command -v dnf >/dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="sudo dnf upgrade -y"
    elif command -v pacman >/dev/null; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        UPDATE_CMD="sudo pacman -Syu --noconfirm"
    else
        error "Unsupported distro or package manager!"
    fi
}

install_pkg() {
    local pkg="$1"
    $INSTALL_CMD "$pkg"
}

update_system() {
    log "Updating system using $PKG_MANAGER..."
    status_installing "System update"
    ($UPDATE_CMD) &
    pid=$!
    spinner $pid
    wait $pid
    status_done "System packages updated"
}

# Run detection
detect_package_manager