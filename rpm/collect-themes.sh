#!/usr/bin/env bash
# Build the BookOS theme source tarballs (Plasma + GTK) into ~/rpmbuild/SOURCES,
# and refresh the Plasma splash QML used by the global look-and-feel so the next
# bundle-look picks up the updated loading screen.
#
#   bash collect-themes.sh [version]      (default 0.6)
set -euo pipefail

VERSION="${1:-0.6}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"          # …/BookOS
PLASMA_SRC="$ROOT/BookOS-Plasma-Theme"
GTK_SRC="$ROOT/BookOS-GTK-Theme"
LOAD_SRC="$ROOT/BookOS-Loading-System"

USER_HOME="${SUDO_USER:+/home/$SUDO_USER}"; USER_HOME="${USER_HOME:-$HOME}"
SOURCES="$USER_HOME/rpmbuild/SOURCES"
mkdir -p "$SOURCES"
say(){ printf '  %s\n' "$*"; }

# ── Plasma theme: desktoptheme + color-schemes + aurorae/themes + kvantum ───
if [ -d "$PLASMA_SRC" ]; then
    STAGE="$(mktemp -d)/bookos-plasma-theme-${VERSION}"
    mkdir -p "$STAGE"
    for d in desktoptheme color-schemes kvantum; do
        [ -d "$PLASMA_SRC/$d" ] && cp -r "$PLASMA_SRC/$d" "$STAGE/"
    done
    # spec expects aurorae/themes/ (skips the _generate.py helper)
    [ -d "$PLASMA_SRC/aurorae/themes" ] && { mkdir -p "$STAGE/aurorae"; cp -r "$PLASMA_SRC/aurorae/themes" "$STAGE/aurorae/"; }
    # drop generator scripts so they don't ship
    find "$STAGE" -name '*.py' -delete
    OUT="$SOURCES/bookos-plasma-theme-${VERSION}.tar.gz"
    tar -C "$(dirname "$STAGE")" -czf "$OUT" "bookos-plasma-theme-${VERSION}"
    rm -rf "$(dirname "$STAGE")"
    say "plasma-theme: $OUT"
else
    echo "  ⚠ no existe $PLASMA_SRC" >&2
fi

# ── GTK theme: themes/BookOS-*-* ────────────────────────────────────────────
if [ -d "$GTK_SRC/themes" ]; then
    STAGE="$(mktemp -d)/bookos-gtk-theme-${VERSION}"
    mkdir -p "$STAGE/themes"
    cp -r "$GTK_SRC/themes/"* "$STAGE/themes/"
    OUT="$SOURCES/bookos-gtk-theme-${VERSION}.tar.gz"
    tar -C "$(dirname "$STAGE")" -czf "$OUT" "bookos-gtk-theme-${VERSION}"
    rm -rf "$(dirname "$STAGE")"
    say "gtk-theme: $OUT"
else
    echo "  ⚠ no existe $GTK_SRC/themes" >&2
fi

# ── Loading: refresh the Plasma splash QML in the dev look-and-feel ─────────
# The Plymouth boot theme is picked up directly by collect-branding.sh from
# BookOS-Loading-System/plymouth/. The Plasma post-login splash lives inside the
# global look-and-feel package (contents/splash/Splash.qml), which bundle-look
# captures from the dev machine — so update it there.
SPLASH="$LOAD_SRC/splash/Splash.qml"
# Splash.qml references images/logo.png — refresh that too, else the splash keeps
# the old baked-in logo. The BookOS logo lives at the loading-system root.
SPLASH_LOGO="$LOAD_SRC/book-os.png"
[ -f "$SPLASH_LOGO" ] || SPLASH_LOGO="$LOAD_SRC/plymouth/logo.png"
if [ -f "$SPLASH" ]; then
    LNF_BASE="${USER_HOME}/.local/share/plasma/look-and-feel"
    found=0
    for lnf in "$LNF_BASE"/*/; do
        cdir="$lnf/contents/splash"
        [ -d "$cdir" ] || continue
        cp -f "$SPLASH" "$cdir/Splash.qml"
        if [ -f "$SPLASH_LOGO" ]; then
            mkdir -p "$cdir/images"
            cp -f "$SPLASH_LOGO" "$cdir/images/logo.png"
        fi
        say "splash: actualizado $(basename "$lnf")/contents/splash/ (Splash.qml + logo)"
        found=1
    done
    [ "$found" = 0 ] && echo "  ⚠ no se encontró contents/splash en $LNF_BASE/*" >&2
else
    echo "  ⚠ no existe $SPLASH" >&2
fi

echo "[✓] Tarballs en $SOURCES. Build:"
echo "    rpmbuild -bb $(dirname "$0")/bookos-plasma-theme.spec"
echo "    rpmbuild -bb $(dirname "$0")/bookos-gtk-theme.spec"
echo "    (luego re-ejecuta bundle-look.sh para capturar el splash nuevo)"
