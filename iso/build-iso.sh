#!/usr/bin/env bash
# BookOS ISO builder.
#
# Usage:
#   sudo bash build-iso.sh <os-name> <dev|beta|stable> <version> [outdir] [allapps:S/N]
#
# Examples:
#   sudo bash build-iso.sh BookOS dev 0.6
#   sudo bash build-iso.sh BookOS stable 1.0 ~/isos S
#   sudo bash build-iso.sh "BookOS Lite" beta 0.6-rc.1 /var/isos N
#
# Optional env overrides:
#   RELEASEVER=44                       Fedora base release (default 44)
#   APPS="bookos-player bookos-viewer"  explicit optional-app list (implies allapps=S)
#   SIGN=0                              skip minisign signing (default: sign if key present)
#   WORKDIR=/var/tmp/...                build scratch dir
set -euo pipefail

# ── Args ────────────────────────────────────────────────────────────────
OS_NAME="${1:-}"
CHANNEL="${2:-}"
VERSION="${3:-}"
OUTDIR="${4:-$PWD}"
ALLAPPS="${5:-N}"

usage() {
    echo "Usage: sudo bash $0 <os-name> <dev|beta|stable> <version> [outdir] [allapps:S/N]"
    echo "  e.g. sudo bash $0 BookOS dev 0.6 ~/isos S"
    exit 1
}
[ -z "$OS_NAME" ] || [ -z "$CHANNEL" ] || [ -z "$VERSION" ] && usage
case "$CHANNEL" in stable|beta|dev) ;; *) echo "✗ canal inválido: '$CHANNEL' (usa dev|beta|stable)"; exit 1;; esac
case "$ALLAPPS" in S|s|Y|y|N|n) ;; *) echo "✗ allapps debe ser S o N"; exit 1;; esac
[ "$(id -u)" = "0" ] || { echo "✗ debe ejecutarse como root (lorax lo necesita)"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RELEASEVER="${RELEASEVER:-44}"
WORKDIR="${WORKDIR:-/var/tmp/bookos-iso-${CHANNEL}}"

# ── Optional app set ──────────────────────────────────────────────────────
# "all apps" pulls the full BookOS app catalog on top of the core meta set.
# Override the list with APPS="...". Empty when allapps=N.
DEFAULT_OPTIONAL_APPS="bookos-player bookos-viewer bookos-voicerecorder"
if [ -n "${APPS:-}" ]; then
    OPTIONAL_APPS="$APPS"
elif [ "$ALLAPPS" = "S" ] || [ "$ALLAPPS" = "s" ] || [ "$ALLAPPS" = "Y" ] || [ "$ALLAPPS" = "y" ]; then
    OPTIONAL_APPS="$DEFAULT_OPTIONAL_APPS"
else
    OPTIONAL_APPS=""
fi
# Newline-separate for the kickstart %packages section
OPTIONAL_APPS_KS="$(printf '%s\n' $OPTIONAL_APPS)"

# ── Tooling check ─────────────────────────────────────────────────────────
command -v livemedia-creator >/dev/null || { echo "✗ falta lorax: sudo dnf install lorax-lmc-novirt"; exit 1; }

mkdir -p "$WORKDIR" "$OUTDIR"
rm -rf "$WORKDIR"/results 2>/dev/null || true

# ── Materialize kickstart ──────────────────────────────────────────────────
# Markers live in bookos-base.ks (pulled in via %include), so we MUST flatten
# first and substitute on the merged result — otherwise the base's
# __BOOKOS_*__ placeholders would never be replaced.
KS_IN="$SCRIPT_DIR/bookos-$CHANNEL.ks"
[ -f "$KS_IN" ] || { echo "✗ no existe el kickstart: $KS_IN"; exit 1; }

KS_RAW="$WORKDIR/bookos-raw.ks"
ksflatten -c "$KS_IN" -o "$KS_RAW" 2>/dev/null || cp "$KS_IN" "$KS_RAW"

# Substitute simple vars. __RELEASEVER__/__BASEARCH__ are made literal in the
# bookos repo URL (anaconda doesn't reliably expand $releasever in a kickstart
# `repo --baseurl`, which left bookos-* as "No match" during the build).
sed -e "s/__BOOKOS_NAME__/$OS_NAME/g" \
    -e "s/__BOOKOS_VERSION__/$VERSION/g" \
    -e "s/__BOOKOS_CHANNEL__/$CHANNEL/g" \
    -e "s/__RELEASEVER__/$RELEASEVER/g" \
    -e "s/__BASEARCH__/x86_64/g" \
    "$KS_RAW" > "$KS_RAW.sub"
# Replace the optional-apps placeholder line with the (possibly empty) list,
# keeping the package section valid (one package per line, or removed).
awk -v apps="$OPTIONAL_APPS_KS" '
    /__BOOKOS_OPTIONAL_APPS__/ { if (apps != "") print apps; next }
    { print }
' "$KS_RAW.sub" > "$WORKDIR/bookos-flat.ks"
rm -f "$KS_RAW" "$KS_RAW.sub"

# ── Build ──────────────────────────────────────────────────────────────────
# Slugify the OS name for the filename (spaces → -, lowercase).
SLUG="$(echo "$OS_NAME" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9.-')"
ISO_NAME="${SLUG}-${VERSION}-${CHANNEL}-x86_64.iso"

echo "──────────────────────────────────────────────"
echo "  OS        : $OS_NAME"
echo "  Channel   : $CHANNEL"
echo "  Version   : $VERSION"
echo "  Fedora    : $RELEASEVER"
echo "  All apps  : $ALLAPPS  ${OPTIONAL_APPS:+($OPTIONAL_APPS)}"
echo "  Output    : $OUTDIR/$ISO_NAME"
echo "──────────────────────────────────────────────"

livemedia-creator \
    --make-iso \
    --no-virt \
    --ks "$WORKDIR/bookos-flat.ks" \
    --iso-only \
    --iso-name "$ISO_NAME" \
    --resultdir "$WORKDIR/results" \
    --project "$OS_NAME" \
    --releasever "$RELEASEVER" \
    --volid "$(echo "$SLUG" | cut -c1-11)-$VERSION"

mv "$WORKDIR/results/$ISO_NAME" "$OUTDIR/"
echo "[✓] $OUTDIR/$ISO_NAME"

# ── Fix boot-menu title ("BookOS 44" → "BookOS <version>") ────────────────
# lorax stamps the GRUB/isolinux menu labels as "<project> <releasever>", so
# the live boot menu reads "BookOS 44" (the Fedora base). Rewrite those labels
# to the BookOS version. Needs xorriso to remaster in place; skipped (with a
# note) if it's missing — purely cosmetic, never fatal.
if command -v xorriso >/dev/null; then
    ISO_PATH="$OUTDIR/$ISO_NAME"
    EXDIR="$WORKDIR/bootcfg"; rm -rf "$EXDIR"; mkdir -p "$EXDIR"
    # Boot config files that may carry the title (paths vary by Fedora spin).
    CFGS="/isolinux/isolinux.cfg /EFI/BOOT/grub.cfg /EFI/BOOT/BOOT.conf /boot/grub2/grub.cfg"
    CHANGED=0
    for c in $CFGS; do
        if xorriso -osirrox on -indev "$ISO_PATH" -extract "$c" "$EXDIR/$(basename "$c")" 2>/dev/null; then
            # Only on menu-title lines (label/menuentry/title), so kernel args
            # that may contain "$RELEASEVER" are left untouched. Cover the exact
            # project name and a lowercase slug variant.
            sed -i -E "/(menu label|menuentry|^\s*title|set default_title|^label )/I {
                s/$OS_NAME $RELEASEVER/$OS_NAME $VERSION/g
                s/$SLUG $RELEASEVER/$SLUG $VERSION/Ig
            }" "$EXDIR/$(basename "$c")"
            xorriso -boot_image any keep -dev "$ISO_PATH" \
                -update "$EXDIR/$(basename "$c")" "$c" 2>/dev/null && CHANGED=1
        fi
    done
    [ "$CHANGED" = 1 ] && echo "[✓] Menú GRUB: '$OS_NAME $RELEASEVER' → '$OS_NAME $VERSION'" \
                       || echo "[i] No se encontró el título en los configs de arranque (sin cambios)."
else
    echo "[i] xorriso no instalado: el menú de arranque seguirá diciendo '$OS_NAME $RELEASEVER'."
    echo "    Para corregirlo: sudo dnf install xorriso  y vuelve a construir."
fi

# ── Sign (minisign) ──────────────────────────────────────────────────────
if [ "${SIGN:-1}" != "0" ] && command -v minisign >/dev/null && [ -f /etc/bookos/minisign.key ]; then
    minisign -Sm "$OUTDIR/$ISO_NAME" -s /etc/bookos/minisign.key
    echo "[✓] Firmado: $OUTDIR/$ISO_NAME.minisig"
elif [ "${SIGN:-1}" != "0" ]; then
    echo "[i] Sin firmar (no hay /etc/bookos/minisign.key). Exporta SIGN=0 para silenciar."
fi
