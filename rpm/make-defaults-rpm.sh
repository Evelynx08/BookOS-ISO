#!/usr/bin/env bash
# make-defaults-rpm.sh — turn a bundle-look.sh payload into the
# bookos-desktop-defaults RPM in one shot.
#
#   bash make-defaults-rpm.sh <bookos-look-bundle.tar.zst> [version]
#
# The bundle is produced on the reference PC (the one with the good theme) by:
#   bash bundle-look.sh        ->  bookos-look-bundle.tar.zst
# Copy it here, then run this.
set -euo pipefail
BUNDLE="${1:?uso: make-defaults-rpm.sh <bundle.tar.zst> [version]}"
VER="${2:-0.6}"
NAME=bookos-desktop-defaults
SPEC="$(cd "$(dirname "$0")" && pwd)/${NAME}.spec"

[ -f "$BUNDLE" ] || { echo "✗ no existe el bundle: $BUNDLE"; exit 1; }
[ -f "$SPEC" ]   || { echo "✗ no existe el spec: $SPEC"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
echo "→ Extrayendo bundle…"
tar -C "$TMP" -xf "$BUNDLE"                      # → $TMP/bookos-look-bundle/{share,skel}
BDIR="$(find "$TMP" -maxdepth 1 -type d -name '*look-bundle*' | head -1)"
[ -d "$BDIR/share" ] && [ -d "$BDIR/skel" ] || { echo "✗ el bundle no tiene share/ + skel/"; exit 1; }

SRC="$TMP/${NAME}-${VER}"
mkdir -p "$SRC"
cp -a "$BDIR/share" "$BDIR/skel" "$SRC/"

mkdir -p "$HOME/rpmbuild/SOURCES"
tar -C "$TMP" -czf "$HOME/rpmbuild/SOURCES/${NAME}-${VER}.tar.gz" "${NAME}-${VER}"
echo "→ Fuente: $HOME/rpmbuild/SOURCES/${NAME}-${VER}.tar.gz"

echo "→ rpmbuild…"
rpmbuild -bb "$SPEC"
echo "[✓] $HOME/rpmbuild/RPMS/noarch/${NAME}-${VER}-1.noarch.rpm"
