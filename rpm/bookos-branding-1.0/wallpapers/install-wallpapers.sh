#!/usr/bin/env bash
# Install BookOS wallpapers only.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SRC="$SCRIPT_DIR/Wallpapers-1.0"

if [[ ! -d "$SRC" ]]; then
    echo "Error: Wallpapers-1.0 not found at $SRC" >&2
    exit 1
fi

# Pick target: system if root/sudo available, else user dir.
if [[ $EUID -eq 0 ]]; then
    DEST="/usr/share/wallpapers/BookOS"
    SUDO=""
elif command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
    DEST="/usr/share/wallpapers/BookOS"
    SUDO="sudo"
else
    read -rp "Install system-wide with sudo? [Y/n] " ans
    if [[ "${ans,,}" != "n" ]]; then
        DEST="/usr/share/wallpapers/BookOS"
        SUDO="sudo"
    else
        DEST="$HOME/.local/share/wallpapers/BookOS"
        SUDO=""
    fi
fi

echo "Installing wallpapers -> $DEST"
$SUDO mkdir -p "$DEST/Dark" "$DEST/Light"
$SUDO cp -v "$SRC/Dark/"*.{png,svg} "$DEST/Dark/" 2>/dev/null || true
$SUDO cp -v "$SRC/Light/"*.{png,svg} "$DEST/Light/" 2>/dev/null || true

echo "Done."
