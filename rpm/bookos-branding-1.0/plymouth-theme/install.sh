#!/usr/bin/env bash
# BookOS Loading System installer
# Installs splash screen into BookOS Dark + BookOS Light look-and-feel themes.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGO_PNG="$SRC_DIR/book-os.png"
LOGO_SVG="$SRC_DIR/book-os.svg"
SPLASH_QML="$SRC_DIR/splash/Splash.qml"

THEMES=(
    "$HOME/.local/share/plasma/look-and-feel/BookOS Dark"
    "$HOME/.local/share/plasma/look-and-feel/BookOS Light"
    "$HOME/.local/share/plasma/look-and-feel/BookOS Light1"
)
BG_COLORS=("#000000" "#000000" "#000000")

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1"; exit 1; }; }
need convert
[[ -f "$LOGO_PNG" ]] || { echo "no logo png: $LOGO_PNG"; exit 1; }
[[ -f "$SPLASH_QML" ]] || { echo "no Splash.qml: $SPLASH_QML"; exit 1; }

# screen size for backgrounds (fallback 1920x1080)
RES="1920x1080"
if command -v xrandr >/dev/null 2>&1; then
    R=$(xrandr 2>/dev/null | awk '/\*/ {print $1; exit}')
    [[ -n "$R" ]] && RES="$R"
fi

for i in "${!THEMES[@]}"; do
    THEME="${THEMES[$i]}"
    BG="${BG_COLORS[$i]}"
    if [[ ! -d "$THEME" ]]; then
        echo "skip (no theme): $THEME"
        continue
    fi

    SPLASH_DIR="$THEME/contents/splash"
    IMG_DIR="$SPLASH_DIR/images"
    mkdir -p "$IMG_DIR"

    cp "$SPLASH_QML" "$SPLASH_DIR/Splash.qml"

    # prefer SVG for crisp scaling; render high-res PNG fallback
    if [[ -f "$LOGO_SVG" ]]; then
        cp "$LOGO_SVG" "$IMG_DIR/logo.svg"
        if command -v rsvg-convert >/dev/null 2>&1; then
            rsvg-convert -w 1024 -h 1024 "$LOGO_SVG" -o "$IMG_DIR/logo.png"
        elif command -v inkscape >/dev/null 2>&1; then
            inkscape "$LOGO_SVG" --export-type=png --export-filename="$IMG_DIR/logo.png" -w 1024 -h 1024 2>/dev/null
        else
            convert -background none -density 600 "$LOGO_SVG" -resize 1024x1024 "$IMG_DIR/logo.png"
        fi
    else
        cp "$LOGO_PNG" "$IMG_DIR/logo.png"
    fi

    convert -size "$RES" "xc:$BG" "$IMG_DIR/background.png"

    # metadata splashscreen entry
    META="$THEME/metadata.json"
    if [[ -f "$META" ]] && command -v python3 >/dev/null 2>&1; then
        python3 - "$META" <<'PYEOF' || true
import json, sys
p = sys.argv[1]
with open(p) as f: data = json.load(f)
kpa = data.setdefault("KPlugin", {})
kpa.setdefault("ServiceTypes", [])
if "Plasma/LookAndFeel" not in kpa["ServiceTypes"]:
    kpa["ServiceTypes"].append("Plasma/LookAndFeel")
with open(p,"w") as f: json.dump(data, f, indent=4)
PYEOF
    fi

    echo "installed splash -> $SPLASH_DIR"
done

# clear plasma splash cache
rm -rf "$HOME/.cache/plasma-svgelements"* 2>/dev/null || true

# activate splash via kwriteconfig if available
if command -v kwriteconfig6 >/dev/null 2>&1; then
    KW=kwriteconfig6
elif command -v kwriteconfig5 >/dev/null 2>&1; then
    KW=kwriteconfig5
else
    KW=""
fi

CURRENT_LNF=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null \
    || kreadconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null \
    || echo "")

case "$CURRENT_LNF" in
    *"BookOS Dark"*|*"BookOS Light"*)
        SPLASH_THEME="$CURRENT_LNF" ;;
    *)
        SPLASH_THEME="org.kde.bookos-dark" ;;
esac

if [[ -n "$KW" ]]; then
    $KW --file ksplashrc --group KSplash --key Theme   "$CURRENT_LNF"
    $KW --file ksplashrc --group KSplash --key Engine  "KSplashQML"
    echo "ksplashrc updated: Theme=$CURRENT_LNF"
fi

echo
echo "Done. Test with:"
echo "  ksplashqml \"$CURRENT_LNF\" --test"
echo "Or pick splash in System Settings -> Splash Screen."
