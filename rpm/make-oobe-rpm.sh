#!/usr/bin/env bash
# Build the bookos-oobe RPM from the staged source tree.
#
#   bash make-oobe-rpm.sh [version]
#
# Default version=0.6.1 (must match Version: in bookos-oobe.spec).
# Source tree: rpm/bookos-oobe/  (session, app, oobe.py, Main.qml, unidad systemd)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
VERSION="${1:-0.6.1}"
NAME="bookos-oobe"
SRC="$HERE/$NAME"
SPEC="$HERE/${NAME}.spec"

[ -d "$SRC" ]  || { echo "✗ no existe el árbol fuente: $SRC"; exit 1; }
[ -f "$SPEC" ] || { echo "✗ no existe el spec: $SPEC"; exit 1; }

USER_HOME="${SUDO_USER:+/home/$SUDO_USER}"; USER_HOME="${USER_HOME:-$HOME}"
SOURCES="$USER_HOME/rpmbuild/SOURCES"
mkdir -p "$SOURCES"

OUT="$SOURCES/${NAME}-${VERSION}.tar.gz"
echo "→ Empaquetando $SRC → $OUT"
tar --transform "s,^\.,${NAME}-${VERSION}," -czf "$OUT" -C "$SRC" .

echo "→ rpmbuild -bb $SPEC"
rpmbuild -bb "$SPEC"
echo "[✓] RPM en $USER_HOME/rpmbuild/RPMS/noarch/"
