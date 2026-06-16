#!/usr/bin/env bash
# BookOS ISO builder.
# Usage:
#   sudo ./build-iso.sh stable 1.0
#   sudo ./build-iso.sh beta   1.1-rc.1
#   sudo ./build-iso.sh dev    1.2-dev.42
set -euo pipefail

CHANNEL="${1:?usage: $0 <stable|beta|dev> <version>}"
VERSION="${2:?missing version}"
case "$CHANNEL" in stable|beta|dev) ;; *) echo "invalid channel"; exit 1;; esac

[ "$(id -u)" = "0" ] || { echo "must run as root (lorax needs it)"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKDIR="${WORKDIR:-/var/tmp/bookos-iso-${CHANNEL}}"
OUTDIR="${OUTDIR:-$PWD}"
RELEASEVER="${RELEASEVER:-44}"   # Fedora version base (44 = dnf5 default)

mkdir -p "$WORKDIR"
rm -rf "$WORKDIR"/results 2>/dev/null || true

# Materialize kickstart with substituted vars
KS_IN="$SCRIPT_DIR/bookos-$CHANNEL.ks"
KS_OUT="$WORKDIR/bookos-$CHANNEL-$VERSION.ks"
sed -e "s/__BOOKOS_VERSION__/$VERSION/g" \
    -e "s/__BOOKOS_CHANNEL__/$CHANNEL/g" \
    "$KS_IN" > "$KS_OUT"

# Flatten %include manually (lorax doesn't always resolve them recursively)
ksflatten -c "$KS_OUT" -o "$WORKDIR/bookos-flat.ks" 2>/dev/null || cp "$KS_OUT" "$WORKDIR/bookos-flat.ks"

ISO_NAME="bookos-${VERSION}-${CHANNEL}-x86_64.iso"

echo "[*] Building $ISO_NAME (releasever=$RELEASEVER)..."
livemedia-creator \
    --make-iso \
    --no-virt \
    --ks "$WORKDIR/bookos-flat.ks" \
    --iso-only \
    --iso-name "$ISO_NAME" \
    --resultdir "$WORKDIR/results" \
    --project "BookOS" \
    --releasever "$RELEASEVER" \
    --title "BookOS $VERSION $CHANNEL" \
    --volid "BookOS-$VERSION"

mv "$WORKDIR/results/$ISO_NAME" "$OUTDIR/"
echo "[✓] $OUTDIR/$ISO_NAME"

# Optional: sign with minisign if key present
if command -v minisign >/dev/null && [ -f /etc/bookos/minisign.key ]; then
    minisign -Sm "$OUTDIR/$ISO_NAME" -s /etc/bookos/minisign.key
    echo "[✓] Signed: $OUTDIR/$ISO_NAME.minisig"
fi
