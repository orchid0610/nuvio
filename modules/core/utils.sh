#!/usr/bin/env bash

# =========================
# Colors & Logging
# =========================
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
RESET="\033[0m"

log() { echo -e "${BLUE}[INFO]${RESET} $1"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; exit 1; }

# =========================
# Status Indicators
# =========================
status_installing() { echo -ne "${YELLOW}[INSTALLING]${RESET} $1...\r"; }
status_done() { echo -e "${GREEN}[INSTALLED]${RESET} $1"; }
status_skipped() { echo -e "${BLUE}[SKIPPED]${RESET} $1"; }
status_fail() { echo -e "${RED}[FAILED]${RESET} $1"; }

# =========================
# Helper Functions
# =========================
is_installed() {
    # distro-agnostic check
    case "$PKG_MANAGER" in
        apt) dpkg -s "$1" &>/dev/null ;;
        dnf) rpm -q "$1" &>/dev/null ;;
        pacman) pacman -Qi "$1" &>/dev/null ;;
    esac
}

run_module() {
    local module="$1"
    [[ -f "$ROOT_DIR/modules/$module.sh" ]] || error "Module not found: $module"
    log "Running module: $module"
    source "$ROOT_DIR/modules/$module.sh"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}