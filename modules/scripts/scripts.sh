#!/usr/bin/env bash

NEW_SITE_SRC="$ROOT_DIR/new-site"
NEW_SITE_DEST="/usr/local/bin/new-site"

if [ ! -f "$NEW_SITE_SRC" ]; then
    warn "⚠️ new-site script not found in $ROOT_DIR. Skipping installation."
    return
fi

if [ -f "$NEW_SITE_DEST" ]; then
    status_skipped "new-site script"
else
    status_installing "Installing new-site script"
    sudo cp "$NEW_SITE_SRC" "$NEW_SITE_DEST"
    sudo chmod +x "$NEW_SITE_DEST"
    status_done "new-site script installed"
fi