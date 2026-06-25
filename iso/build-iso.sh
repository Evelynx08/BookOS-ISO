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

# ── Live-ISO kernel cmdline ────────────────────────────────────────────────
# Injected into the live boot menu via lmc --extra-boot-args (fills the lorax
# @EXTRA@ placeholder in BOTH the BIOS and EFI grub.cfg). NO ISO remaster, so
# the appended GPT/ESP partition stays intact.
#
# Default set is taken from a working Intel Core Ultra 200V (Lunar Lake, Arc
# 130V/140V, xe driver) laptop where the stock live ISO loaded then crashed.
# ibt=off + intel_pstate=passive are the boot-critical ones; the rest are the
# laptop's power-tuning params. nohz_full is intentionally dropped (core-count
# specific). Override with EXTRA_BOOT_ARGS="...".
EXTRA_BOOT_ARGS="${EXTRA_BOOT_ARGS:-ibt=off intel_pstate=passive nowatchdog nvme_core.default_ps_max_latency_us=5500 pcie_aspm=force pcie_aspm.policy=powersupersave workqueue.power_efficient=1 xe.enable_psr=1}"

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
# Flatten %include ourselves: ksflatten was dropped from pykickstart in recent
# Fedora and isn't guaranteed in the build container. Our kickstarts only use a
# single level of relative `%include foo.ks`, so inline each included file
# (resolved relative to SCRIPT_DIR). This replaces the unreliable
# `ksflatten || cp` that silently dropped the base ks (and dracut-live with it).
awk -v dir="$SCRIPT_DIR" '
    /^[[:space:]]*%include[[:space:]]+/ {
        f = $2
        if (f !~ /^\//) f = dir "/" f
        while ((getline line < f) > 0) print line
        close(f)
        next
    }
    { print }
' "$KS_IN" > "$KS_RAW"
grep -q '^dracut-live' "$KS_RAW" \
    || { echo "✗ el kickstart aplanado no contiene dracut-live (include no resuelto). Abortando."; exit 1; }

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

# ── Optional: LOCAL bookos repo ─────────────────────────────────────────────
# Test freshly-built RPMs without publishing to bookos.es. Point the build-time
# `repo --name=bookos` line at a local createrepo_c'd dir:
#   createrepo_c /path/to/rpms && BOOKOS_LOCAL_REPO=/path/to/rpms bash build-iso.sh …
# (Only swaps the OS-package repo; bookos-apps/store-files stays remote. The
#  trailing space in '--name=bookos ' avoids touching '--name=bookos-apps'.)
if [ -n "${BOOKOS_LOCAL_REPO:-}" ]; then
    [ -f "$BOOKOS_LOCAL_REPO/repodata/repomd.xml" ] \
        || { echo "✗ $BOOKOS_LOCAL_REPO no es un repo (falta repodata/). Corre: createrepo_c $BOOKOS_LOCAL_REPO"; exit 1; }
    echo "[i] Repo bookos LOCAL: file://$BOOKOS_LOCAL_REPO"
    sed -i -E "s#(repo --name=bookos )--baseurl=[^ ]+#\1--baseurl=file://$BOOKOS_LOCAL_REPO#" "$WORKDIR/bookos-flat.ks"
fi

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
echo "  Boot args : $EXTRA_BOOT_ARGS"
echo "──────────────────────────────────────────────"

livemedia-creator \
    --make-iso \
    --no-virt \
    --ks "$WORKDIR/bookos-flat.ks" \
    --iso-only \
    --iso-name "$ISO_NAME" \
    --resultdir "$WORKDIR/results" \
    --project "$OS_NAME" \
    --extra-boot-args "$EXTRA_BOOT_ARGS" \
    --releasever "$RELEASEVER" \
    --volid "$(echo "$SLUG" | cut -c1-11)-$VERSION"

mv "$WORKDIR/results/$ISO_NAME" "$OUTDIR/"
echo "[✓] $OUTDIR/$ISO_NAME"

# ── Checksum ────────────────────────────────────────────────────────────────
# Publish a SHA256SUMS next to the ISO so users without minisign can still
# verify the download (sha256sum -c "$ISO_NAME.sha256").
( cd "$OUTDIR" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256" )
echo "[✓] $OUTDIR/$ISO_NAME.sha256"

# ── Fix boot-menu title ("BookOS 44" → "BookOS <version>") ────────────────
# lorax stamps the GRUB/isolinux menu labels as "<project> <releasever>", so
# the live boot menu reads "BookOS 44" (the Fedora base).
#
# WARNING: do NOT remaster the finished ISO in place with
#   xorriso -boot_image any keep -dev ... -update
# That keeps the El Torito BIOS image but DROPS the appended GPT partition
# (partition 2 = the EFI System Partition holding images/efiboot.img that
# lorax appends via xorrisofs -append_partition). The result boots on BIOS
# but NOT on UEFI ("ISO not UEFI compatible"). efiboot.img lives only inside
# that appended partition, so once dropped it cannot be recovered.
#
# Fix the labels on the extracted tree BEFORE lorax assembles the ISO, or
# leave the cosmetic "BookOS 44" title. We choose the latter: purely cosmetic,
# never worth breaking UEFI boot.
echo "[i] Menú de arranque puede decir '$OS_NAME $RELEASEVER' (cosmético)."
echo "    No se remasteriza la ISO: hacerlo destruye la partición ESP/UEFI."

# ── Sign (minisign) ──────────────────────────────────────────────────────
if [ "${SIGN:-1}" != "0" ] && command -v minisign >/dev/null && [ -f /etc/bookos/minisign.key ]; then
    minisign -Sm "$OUTDIR/$ISO_NAME" -s /etc/bookos/minisign.key
    echo "[✓] Firmado: $OUTDIR/$ISO_NAME.minisig"
elif [ "${SIGN:-1}" != "0" ]; then
    echo "[i] Sin firmar (no hay /etc/bookos/minisign.key). Exporta SIGN=0 para silenciar."
fi
