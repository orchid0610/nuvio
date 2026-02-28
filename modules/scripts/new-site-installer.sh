#!/usr/bin/env bash
# ============================================================
#  modules/scripts/new-site-installer.sh
#  Copies the new-site utility into /usr/local/bin
# ============================================================

section "CLI Tools"

_src="$ROOT_DIR/bin/new-site"
_dest="/usr/local/bin/new-site"

if [[ ! -f "$_src" ]]; then
    warn "bin/new-site not found in repo — skipping"
    return
fi

if [[ -f "$_dest" ]]; then
    status_skipped "new-site (already in /usr/local/bin)"
else
    sudo cp "$_src" "$_dest"
    sudo chmod +x "$_dest"
    status_done "new-site installed → $_dest"
fi
