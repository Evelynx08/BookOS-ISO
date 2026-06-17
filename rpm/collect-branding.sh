#!/usr/bin/env bash
# Assembles bookos-branding-<version>.tar.gz from the scattered asset repos
# into the layout that bookos-branding.spec expects, then drops it in
# ~/rpmbuild/SOURCES so `rpmbuild -bb bookos-branding.spec` works.
#
# Usage:  ./collect-branding.sh [version]   (default 0.6)
set -euo pipefail

VERSION="${1:-0.6}"
# Repo root = two levels up from this script (…/BookOS/BookOS-ISO/rpm → …/BookOS)
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STAGE="$(mktemp -d)/bookos-branding-${VERSION}"
mkdir -p "$STAGE"/{logos,wallpapers,sddm-theme,plymouth-theme,lockscreen,anaconda}

say(){ printf '  %s\n' "$*"; }
warn(){ printf '  ⚠ %s\n' "$*" >&2; }

echo "[*] Collecting branding assets (v${VERSION}) from $ROOT"

# ── Logos ───────────────────────────────────────────────────────────────
if [ -f "$ROOT/BookOS-Anaconda/pixmaps/bookos-logo.svg" ]; then
    cp "$ROOT/BookOS-Anaconda/pixmaps/bookos-logo.svg" "$STAGE/logos/bookos.svg"
    cp "$ROOT/BookOS-Anaconda/pixmaps/bookos-logo.svg" "$STAGE/logos/bookos-symbolic.svg"
    say "logos: bookos.svg + symbolic (from Anaconda pixmaps)"
else
    warn "no logo found — spec needs logos/bookos.svg, .png, -symbolic.svg"
fi
# PNG: rasterize if a tool exists, else warn (spec installs bookos.png)
if [ -f "$STAGE/logos/bookos.svg" ] && command -v rsvg-convert >/dev/null; then
    rsvg-convert -w 256 -h 256 "$STAGE/logos/bookos.svg" -o "$STAGE/logos/bookos.png"
    say "logos: rasterized bookos.png"
else
    warn "bookos.png NOT generated (install librsvg2-tools or add it by hand)"
fi

# ── Wallpapers ──────────────────────────────────────────────────────────
if [ -d "$ROOT/BookOS-Wallpapers/Wallpapers-1.0" ]; then
    cp -r "$ROOT/BookOS-Wallpapers/Wallpapers-1.0/." "$STAGE/wallpapers/"
    say "wallpapers: copied Dark + Light"
else
    warn "no wallpapers dir found"
fi

# ── SDDM theme (login screen) ───────────────────────────────────────────
if [ -d "$ROOT/BookOS-SDDM/theme-sddm/bookos" ]; then
    cp -r "$ROOT/BookOS-SDDM/theme-sddm/bookos/." "$STAGE/sddm-theme/"
    say "sddm-theme: copied"
else
    warn "no SDDM theme found"
fi

# ── Lockscreen QML ──────────────────────────────────────────────────────
if compgen -G "$ROOT/BookOS-Settings/src-tauri/extra/lockscreen/*.qml" >/dev/null; then
    cp "$ROOT"/BookOS-Settings/src-tauri/extra/lockscreen/*.qml "$STAGE/lockscreen/"
    say "lockscreen: copied QML"
else
    warn "no lockscreen QML found"
fi

# ── Plymouth boot splash ────────────────────────────────────────────────
# NOTE: BookOS-Loading-System currently holds a Plasma *splash* (look-and-feel
# QML), which is NOT a Plymouth boot theme. A real Plymouth theme needs a
# bookos.plymouth + bookos.script + images. Until that exists, fall back to a
# minimal two-step theme so the boot doesn't show the Fedora logo.
if [ -f "$ROOT/BookOS-Loading-System/plymouth/bookos.plymouth" ]; then
    cp -r "$ROOT/BookOS-Loading-System/plymouth/." "$STAGE/plymouth-theme/"
    say "plymouth-theme: copied"
else
    warn "NO real Plymouth theme — generating a minimal fallback (logo on bg)"
    cat > "$STAGE/plymouth-theme/bookos.plymouth" <<EOF
[Plymouth Theme]
Name=BookOS
Description=BookOS boot splash
ModuleName=script
[script]
ImageDir=/usr/share/plymouth/themes/bookos
ScriptFile=/usr/share/plymouth/themes/bookos/bookos.script
EOF
    cat > "$STAGE/plymouth-theme/bookos.script" <<'EOF'
Window.SetBackgroundTopColor(0.04, 0.04, 0.05);
Window.SetBackgroundBottomColor(0.04, 0.04, 0.05);
logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth()/2 - logo.image.GetWidth()/2);
logo.sprite.SetY(Window.GetHeight()/2 - logo.image.GetHeight()/2);
EOF
    [ -f "$STAGE/logos/bookos.png" ] && cp "$STAGE/logos/bookos.png" "$STAGE/plymouth-theme/logo.png" || true
fi

# ── Anaconda installer branding (pixmaps + WebUI CSS) ───────────────────
if [ -d "$ROOT/BookOS-Anaconda" ]; then
    [ -d "$ROOT/BookOS-Anaconda/pixmaps" ] && cp -r "$ROOT/BookOS-Anaconda/pixmaps" "$STAGE/anaconda/pixmaps"
    [ -d "$ROOT/BookOS-Anaconda/theme" ]   && cp -r "$ROOT/BookOS-Anaconda/theme"   "$STAGE/anaconda/theme"
    say "anaconda: pixmaps + theme CSS"
else
    warn "no BookOS-Anaconda dir — installer keeps Fedora look"
fi

# ── Pack ────────────────────────────────────────────────────────────────
OUT="${HOME}/rpmbuild/SOURCES/bookos-branding-${VERSION}.tar.gz"
mkdir -p "$(dirname "$OUT")"
tar -C "$(dirname "$STAGE")" -czf "$OUT" "bookos-branding-${VERSION}"
rm -rf "$(dirname "$STAGE")"
echo "[✓] $OUT"
echo "    Build:  rpmbuild -bb $ROOT/BookOS-ISO/rpm/bookos-branding.spec"
