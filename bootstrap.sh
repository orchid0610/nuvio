#!/usr/bin/env bash
# ============================================================
#  bootstrap.sh — nuvio one-line installer
#
#  Usage:
#    curl -fsSL https://raw.githubusercontent.com/orchid0610/nuvio/main/bootstrap.sh | bash
#
#  What it does:
#    1. Checks dependencies (git, curl)
#    2. Clones the repo (or pulls if already cloned)
#    3. Re-launches install.sh directly (not piped) so
#       interactive prompts work correctly
# ============================================================

# ── Colors (no lib available yet) ────────────────────────────
_R="\033[1;31m" _G="\033[1;32m" _Y="\033[1;33m" _B="\033[1;34m" _X="\033[0m"
info()  { echo -e "${_B}[INFO]${_X}  $*"; }
ok()    { echo -e "${_G}[OK]${_X}    $*"; }
warn()  { echo -e "${_Y}[WARN]${_X}  $*"; }
die()   { echo -e "${_R}[ERROR]${_X} $*" >&2; exit 1; }
sep()   { echo -e "\n${_B}══════════════════════════════════════${_X}\n"; }

# ── Config ───────────────────────────────────────────────────
REPO_URL="https://github.com/orchid0610/nuvio.git"
INSTALL_DIR="${HOME}/.nuvio"

sep
echo -e "  ${_B}nuvio${_X} — bootstrap"
sep

# ── Dependency checks ────────────────────────────────────────
command -v git  &>/dev/null || die "git is required. Install it first:  sudo apt install git"
command -v curl &>/dev/null || die "curl is required. Install it first: sudo apt install curl"

# ── Clone or update ──────────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Repo already cloned — pulling latest..."
    git -C "$INSTALL_DIR" pull --ff-only
    ok "Repo updated"
else
    info "Cloning nuvio into $INSTALL_DIR ..."
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
    ok "Repo cloned"
fi

# ── Re-launch with a real TTY so interactive prompts work ────
# curl | bash has no TTY attached — read gets EOF and skips prompts.
# We hand off by exec'ing install.sh directly from the cloned repo,
# which restores stdin from the terminal.
ok "Bootstrap complete. Launching installer..."
echo ""

exec bash "$INSTALL_DIR/install.sh"