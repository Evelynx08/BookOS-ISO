#!/usr/bin/env bash
# bundle-look.sh — collect EVERY asset the BookOS desktop look depends on,
# resolved from the reference PC, into one payload that can be shipped in the
# ISO (installed to /usr/share + applied to the live user via /etc/skel).
#
#   bash bundle-look.sh [outdir]      # default: ./bookos-look-bundle
#
# Reads the active global look-and-feel's `defaults` cascade and grabs the
# exact icon theme / cursor / aurorae / kvantum / plasma style / color scheme /
# fonts / GTK theme it names — wherever they live (~/.local, /usr/share,
# /usr/local). Produces:
#   <outdir>/share/...            assets → become /usr/share/...
#   <outdir>/skel/.config/...     resolved config → /etc/skel
#   <outdir>/MANIFEST.txt         what was grabbed + sizes + orphan flags
#   bookos-look-bundle.tar.zst    the lot, ready to send.
set -u
OUT="${1:-bookos-look-bundle}"

# ── Resolve the REAL user's home ────────────────────────────────────────────
# This script reads the desktop look from the calling user's ~/.config and
# ~/.local/share. If invoked under sudo, $HOME is /root and EVERYTHING resolves
# empty (icons=, cursor=, plasma=…), producing a hollow bundle that ships a
# plain Breeze desktop with missing/tiny icons. Re-resolve to SUDO_USER's home
# so `sudo bash bundle-look.sh` captures the operator's actual desktop.
if [ "$(id -u)" = "0" ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
    [ -n "$REAL_HOME" ] && HOME="$REAL_HOME"
    echo "[i] sudo detectado → capturando el look de '$SUDO_USER' ($HOME)"
fi
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
LOC="${XDG_DATA_HOME:-$HOME/.local/share}"

# Sanity guard: abort if the look can't be read (empty home / wrong user),
# rather than silently shipping a hollow bundle as happened with the root run.
[ -f "$CFG/kdeglobals" ] || { echo "✗ no existe $CFG/kdeglobals — ¿usuario equivocado? Aborto para no generar un bundle vacío."; exit 1; }
rm -rf "$OUT"; mkdir -p "$OUT/share" "$OUT/skel/.config"
MAN="$OUT/MANIFEST.txt"; : > "$MAN"
log(){ echo "$*"; echo "$*" >> "$MAN"; }

# Resolve a theme dir by name across the standard search paths; echo first hit.
find_dir(){ # $1 = subdir under data roots, $2 = name
  for r in "$LOC" /usr/share /usr/local/share; do
    [ -d "$r/$1/$2" ] && { echo "$r/$1/$2"; return 0; }
  done; return 1; }

grab(){ # $1=found path  $2=dest subdir under share/
  [ -n "$1" ] && [ -d "$1" ] || { log "  !! MISSING: $2"; return; }
  mkdir -p "$OUT/share/$2"
  cp -a "$1" "$OUT/share/$2/"
  case "$1" in "$LOC"/*) o="(local)";; *) rpm -qf "$1" >/dev/null 2>&1 && o="(rpm)" || o="(ORPHAN)";; esac
  log "  + $2/$(basename "$1")  $(du -sh "$1"|cut -f1)  $o"
}

# ── Read the active global theme's cascade ────────────────────────────────
LNF=$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage 2>/dev/null)
[ -n "$LNF" ] || LNF=$(grep -m1 'LookAndFeelPackage=' "$CFG/kdeglobals" | cut -d= -f2)
LNFDIR=$(find_dir plasma/look-and-feel "$LNF")
log "Global look-and-feel: '$LNF'  ($LNFDIR)"
DEF="$LNFDIR/contents/defaults"
val(){ awk -v g="[$1][$2]" '$0==g{f=1;next} /^\[/{f=0} f&&$1~/^'"$3"'=/{sub(/^[^=]*=/,"");print;exit}' "$DEF" 2>/dev/null; }

# The active icon theme is whatever kdeglobals [Icons] Theme says NOW — the user
# may have overridden the global-theme default (e.g. BookOS-Tinted instead of
# ColorFlow). Read that first; fall back to the look-and-feel cascade.
ICON=$(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null)
[ -n "$ICON" ] || ICON=$(grep -A20 '^\[Icons\]' "$CFG/kdeglobals" 2>/dev/null | grep -m1 '^Theme=' | cut -d= -f2)
[ -n "$ICON" ] || ICON=$(val kdeglobals Icons Theme)
CURSOR=$(val kcminputrc Mouse cursorTheme)
COLORS=$(val kdeglobals General ColorScheme)
PLASMA=$(val plasmarc Theme name)
DECO=$(val kwinrc org.kde.kdecoration2 theme); DECO=${DECO#__aurorae__svg__}
KVAN=$(grep -m1 'theme=' "$CFG/Kvantum/kvantum.kvconfig" 2>/dev/null | cut -d= -f2)
GTK=$(grep -m1 'gtk-theme-name' "$CFG/gtk-3.0/settings.ini" 2>/dev/null | cut -d= -f2 | tr -d ' ')
log "Resolved: icons=$ICON cursor=$CURSOR colors=$COLORS plasma=$PLASMA deco=$DECO kvantum=$KVAN gtk=$GTK"
log ""

# ── Grab assets ───────────────────────────────────────────────────────────
log "[ global theme(s) ]"
for t in "BookOS Dark" "BookOS Light" "BookOS Light1" "$LNF"; do
  d=$(find_dir plasma/look-and-feel "$t") && grab "$d" plasma/look-and-feel
done
log "[ plasma desktoptheme ]"; grab "$(find_dir plasma/desktoptheme "$PLASMA")" plasma/desktoptheme
log "[ icon theme ]";    grab "$(find_dir icons "$ICON")"   icons
# Cursor + fonts intentionally NOT bundled: BookOS ships only its icon packs;
# the system keeps the stock cursor theme and fonts. (Was: grab MacTahoe/Apple
# cursor and SN Pro — dropped per design decision.)
log "[ aurorae deco ]";  grab "$(find_dir aurorae/themes "$DECO")" aurorae/themes
log "[ kvantum ]";       grab "$(find_dir Kvantum "$KVAN")" Kvantum
log "[ gtk theme ]";     grab "$(find_dir themes "$GTK")"   themes
log "[ color scheme ]"
for r in "$LOC" /usr/share; do
  for f in "$r"/color-schemes/*.colors; do
    [ -f "$f" ] && case "$(basename "$f")" in *Book*|"$COLORS".colors) mkdir -p "$OUT/share/color-schemes"; cp -a "$f" "$OUT/share/color-schemes/"; log "  + color-schemes/$(basename "$f")";; esac
  done
done
# Fonts intentionally NOT bundled (SN Pro dropped per design decision).

# ── Resolved config for the live user (so the look is APPLIED, not just present)
log ""; log "[ skel config ]"
for f in kdeglobals plasmarc kwinrc kcminputrc kscreenlockerrc ksplashrc; do
  [ -f "$CFG/$f" ] && cp -a "$CFG/$f" "$OUT/skel/.config/" && log "  + skel/.config/$f"
done
for g in gtk-3.0 gtk-4.0 Kvantum; do
  [ -d "$CFG/$g" ] && { mkdir -p "$OUT/skel/.config/$g"; cp -a "$CFG/$g/." "$OUT/skel/.config/$g/"; log "  + skel/.config/$g/"; }
done

# ── Panel layout: capture LIVE + sanitize ──────────────────────────────────
# The on-disk layout.js is stale (Plasma only flushes panels on logout) and full
# of /home/<dev> paths. Grab the running layout (matches what you actually see)
# and ship it for EVERY bundled look, then sanitize dev paths / floating. This is
# the fix for panels coming out wrong on the ISO.
SANITIZE="$(dirname "$0")/sanitize-layout.sh"
LIVE_LAYOUT="$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.dumpCurrentLayoutJS 2>/dev/null || true)"
if [ -n "$LIVE_LAYOUT" ]; then
  log ""; log "[ panel layout: live capture ]"
  while IFS= read -r lj; do
    printf '%s\n' "$LIVE_LAYOUT" > "$lj"; log "  + live -> $lj"
  done < <(find "$OUT/share/plasma/look-and-feel" -path '*/contents/layouts/org.kde.plasma.desktop-layout.js')
else
  log "  ⚠ plasmashell no responde (dumpCurrentLayoutJS vacío) — uso layout en disco"
fi
# Sanitize whatever layouts ended up in the bundle (live or on-disk fallback).
if [ -f "$SANITIZE" ]; then
  find "$OUT/share/plasma/look-and-feel" -path '*/contents/layouts/org.kde.plasma.desktop-layout.js' -exec bash "$SANITIZE" {} +
fi

# ── Pack ──────────────────────────────────────────────────────────────────
SZ=$(du -sh "$OUT" | cut -f1); log ""; log "TOTAL bundle size: $SZ"
tar -C "$(dirname "$OUT")" -cf - "$(basename "$OUT")" | zstd -19 -T0 -o "${OUT}.tar.zst" 2>/dev/null
echo; echo "Bundle: $OUT/  ($SZ)"; echo "Tarball: ${OUT}.tar.zst"; echo "Manifest:"; cat "$MAN"
