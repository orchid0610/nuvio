#!/usr/bin/env bash
# ============================================================
#  bootstrap.sh — new_env one-line installer
#
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/YOUR_USER/new_env/main/bootstrap.sh | bash
#
#  What it does:
#    1. Checks dependencies (git, curl)
#    2. Clones the repo (or pulls if already cloned)
#    3. Hands off to setup.sh
# ============================================================
set -euo pipefail

# ── Config ───────────────────────────────────────────────────
REPO_URL="https://github.com/YOUR_USER/new_env.git"   # <-- update this
INSTALL_DIR="${HOME}/.new_env"

# ── Colors (no lib available yet) ────────────────────────────
_R="\033[1;31m" _G="\033[1;32m" _Y="\033[1;33m" _B="\033[1;34m" _X="\033[0m"
info()  { echo -e "${_B}[INFO]${_X}  $*"; }
ok()    { echo -e "${_G}[OK]${_X}    $*"; }
warn()  { echo -e "${_Y}[WARN]${_X}  $*"; }
die()   { echo -e "${_R}[ERROR]${_X} $*" >&2; exit 1; }
sep()   { echo -e "\n${_B}══════════════════════════════════════${_X}\n"; }

# ── Dependency checks ────────────────────────────────────────
sep
echo -e "  ${_B}new_env${_X} — bootstrap"
sep

command -v git  &>/dev/null || die "git is required. Install it and re-run."
command -v curl &>/dev/null || die "curl is required. Install it and re-run."

# ── Clone or update ──────────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Repo already cloned — pulling latest..."
    git -C "$INSTALL_DIR" pull --ff-only
    ok "Repo updated"
else
    info "Cloning new_env into $INSTALL_DIR ..."
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
    ok "Repo cloned"
fi

# ── Hand off ─────────────────────────────────────────────────
info "Starting setup..."
bash "$INSTALL_DIR/setup.sh"
