#!/usr/bin/env bash
# ============================================================
#  lib/log.sh — logging, output & terminal UI helpers
# ============================================================

# ── Colors ───────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

BLACK="\033[30m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"

BG_BLUE="\033[44m"
BG_GREEN="\033[42m"

# ── Banner ───────────────────────────────────────────────────
print_banner() {
    echo ""
    echo -e "${BOLD}${BLUE}"
    echo "  ███╗   ██╗███████╗██╗    ██╗     ███████╗███╗   ██╗██╗   ██╗"
    echo "  ████╗  ██║██╔════╝██║    ██║     ██╔════╝████╗  ██║██║   ██║"
    echo "  ██╔██╗ ██║█████╗  ██║ █╗ ██║     █████╗  ██╔██╗ ██║██║   ██║"
    echo "  ██║╚██╗██║██╔══╝  ██║███╗██║     ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝"
    echo "  ██║ ╚████║███████╗╚███╔███╔╝     ███████╗██║ ╚████║ ╚████╔╝ "
    echo "  ╚═╝  ╚═══╝╚══════╝ ╚══╝╚══╝      ╚══════╝╚═╝  ╚═══╝  ╚═══╝  "
    echo -e "${RESET}"
    echo -e "  ${DIM}Web Development Environment Installer${RESET}"
    echo ""
}

# ── Section header ───────────────────────────────────────────
section() {
    echo ""
    echo -e "  ${BOLD}${BLUE}┌─────────────────────────────────────────┐${RESET}"
    printf  "  ${BOLD}${BLUE}│${RESET}  ${BOLD}%-41s${RESET}${BOLD}${BLUE}│${RESET}\n" "$*"
    echo -e "  ${BOLD}${BLUE}└─────────────────────────────────────────┘${RESET}"
    echo ""
}

# ── Core loggers ─────────────────────────────────────────────
log()     { echo -e "  ${BLUE}${BOLD}·${RESET}  ${DIM}$*${RESET}"; }
success() { echo -e "  ${GREEN}✔${RESET}  $*"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  ${YELLOW}$*${RESET}"; }
error()   { echo -e "\n  ${RED}✘  ERROR:${RESET} $*\n" >&2; exit 1; }

# ── Install status (overwrite current line) ──────────────────
status_installing() {
    printf "  ${YELLOW}◍${RESET}  %-45s" "$* ..."
}

status_done() {
    printf "\r  ${GREEN}✔${RESET}  %-45s  ${DIM}done${RESET}\n" "$*"
}

status_skipped() {
    echo -e "  ${DIM}–  $*${RESET}"
}

status_fail() {
    printf "\r  ${RED}✘${RESET}  %-45s  ${RED}failed${RESET}\n" "$*"
}

# ── Spinner ──────────────────────────────────────────────────
spinner() {
    local pid=$1
    local delay=0.08
    local i=0
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    while kill -0 "$pid" 2>/dev/null; do
        printf " ${CYAN}%s${RESET}" "${frames[$i]}"
        sleep "$delay"
        printf "\b\b"
        i=$(( (i + 1) % ${#frames[@]} ))
    done
    printf "  \b\b"
}

# ── Run command silently with spinner; fail loudly ───────────
run_quiet() {
    local label="$1"; shift
    local tmp_err
    tmp_err="$(mktemp)"

    status_installing "$label"
    ("$@" >/dev/null 2>"$tmp_err") &
    local pid=$!
    spinner $pid
    wait $pid
    local code=$?

    if [[ $code -ne 0 ]]; then
        status_fail "$label"
        echo -e "\n  ${RED}Command:${RESET} $*"
        echo -e "  ${RED}Output:${RESET}"
        sed 's/^/    /' "$tmp_err" >&2
        rm -f "$tmp_err"
        error "Aborting due to above failure."
    fi

    rm -f "$tmp_err"
    status_done "$label"
}

# ── Prompt helpers ───────────────────────────────────────────

# prompt_input <VAR> <label> <default>
# Prints a styled prompt and stores result in VAR.
# If label contains "password", input is hidden.
prompt_input() {
    local -n _ref=$1
    local label="$2"
    local default="$3"

    local hint=""
    [[ -n "$default" ]] && hint="${DIM} (default: ${default})${RESET}"

    printf "  ${CYAN}?${RESET}  ${BOLD}%-22s${RESET}${hint}  " "$label"

    # Mask input for password fields
    if [[ "${label,,}" == *"password"* ]]; then
        read -rs _ref
        echo ""
    else
        read -r _ref
    fi

    # Use default if empty
    [[ -z "$_ref" && -n "$default" ]] && _ref="$default"
}

# confirm <message>  — returns 0 for yes, 1 for no
confirm() {
    printf "  ${CYAN}?${RESET}  ${BOLD}$*${RESET}  ${DIM}[Y/n]${RESET}  "
    read -r _ans
    [[ "${_ans,,}" != "n" ]]
}

# ── Summary box (printed at the end) ─────────────────────────
print_summary() {
    local -n _items=$1   # nameref to associative array  label → value
    local width=46

    echo ""
    echo -e "  ${BOLD}${GREEN}┌─────────────────────────────────────────────┐${RESET}"
    echo -e "  ${BOLD}${GREEN}│          Environment Ready  ✔               │${RESET}"
    echo -e "  ${BOLD}${GREEN}├─────────────────────────────────────────────┤${RESET}"
    for label in "${!_items[@]}"; do
        local val="${_items[$label]}"
        printf "  ${BOLD}${GREEN}│${RESET}  ${BOLD}%-14s${RESET} ${DIM}→${RESET}  %-25s  ${BOLD}${GREEN}│${RESET}\n" "$label" "$val"
    done
    echo -e "  ${BOLD}${GREEN}└─────────────────────────────────────────────┘${RESET}"
    echo ""
}