#!/usr/bin/env bash
# Build the libfprint-bookos RPM from the local fork checkout.
#
#   bash make-libfprint-rpm.sh [src-dir] [version]
#
# Defaults: src-dir=~/Descargas/BookOS/libfprint-fmv-etu906axx-e-fix4Book5Pro
#           version=1.94.9  (must match the Version: in libfprint-bookos.spec)
set -euo pipefail

SRC="${1:-$HOME/Descargas/BookOS/libfprint-fmv-etu906axx-e-fix4Book5Pro}"
VERSION="${2:-1.94.9}"
NAME="libfprint-bookos"
SPEC="$(cd "$(dirname "$0")" && pwd)/${NAME}.spec"

[ -d "$SRC" ]   || { echo "✗ no existe el código: $SRC"; exit 1; }
[ -f "$SPEC" ]  || { echo "✗ no existe el spec: $SPEC"; exit 1; }

# Resolve the real user's rpmbuild even under sudo.
USER_HOME="${SUDO_USER:+/home/$SUDO_USER}"; USER_HOME="${USER_HOME:-$HOME}"
SOURCES="$USER_HOME/rpmbuild/SOURCES"
mkdir -p "$SOURCES"

OUT="$SOURCES/${NAME}-${VERSION}.tar.gz"
echo "→ Empaquetando $SRC → $OUT"
if git -C "$SRC" rev-parse >/dev/null 2>&1; then
    # Clean tarball straight from git (ignores build/ and untracked cruft).
    git -C "$SRC" archive --prefix="${NAME}-${VERSION}/" -o "$OUT" HEAD
else
    # Fallback: tar the tree, excluding the meson build dir.
    tar --exclude='./build' --exclude='./.git' \
        --transform "s,^\.,${NAME}-${VERSION}," \
        -czf "$OUT" -C "$SRC" .
fi

echo "→ rpmbuild -bb $SPEC"
rpmbuild -bb "$SPEC"
echo "[✓] RPM en $USER_HOME/rpmbuild/RPMS/$(uname -m)/"
