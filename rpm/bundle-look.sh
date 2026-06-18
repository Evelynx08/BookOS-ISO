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
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
LOC="${XDG_DATA_HOME:-$HOME/.local/share}"
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

ICON=$(val kdeglobals Icons Theme)
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
log "[ cursor ]";        grab "$(find_dir icons "$CURSOR")" icons
log "[ aurorae deco ]";  grab "$(find_dir aurorae/themes "$DECO")" aurorae/themes
log "[ kvantum ]";       grab "$(find_dir Kvantum "$KVAN")" Kvantum
log "[ gtk theme ]";     grab "$(find_dir themes "$GTK")"   themes
log "[ color scheme ]"
for r in "$LOC" /usr/share; do
  for f in "$r"/color-schemes/*.colors; do
    [ -f "$f" ] && case "$(basename "$f")" in *Book*|"$COLORS".colors) mkdir -p "$OUT/share/color-schemes"; cp -a "$f" "$OUT/share/color-schemes/"; log "  + color-schemes/$(basename "$f")";; esac
  done
done
log "[ fonts (SN Pro + any local) ]"
mkdir -p "$OUT/share/fonts/bookos"
for r in /usr/local/share/fonts "$LOC/fonts" "$HOME/.fonts"; do
  [ -d "$r" ] && find "$r" -iname 'SNPro*' -o -iname 'SN*Pro*' 2>/dev/null | while read -r f; do cp -a "$f" "$OUT/share/fonts/bookos/" && log "  + fonts/bookos/$(basename "$f")"; done
done

# ── Resolved config for the live user (so the look is APPLIED, not just present)
log ""; log "[ skel config ]"
for f in kdeglobals plasmarc kwinrc kcminputrc kscreenlockerrc ksplashrc; do
  [ -f "$CFG/$f" ] && cp -a "$CFG/$f" "$OUT/skel/.config/" && log "  + skel/.config/$f"
done
for g in gtk-3.0 gtk-4.0 Kvantum; do
  [ -d "$CFG/$g" ] && { mkdir -p "$OUT/skel/.config/$g"; cp -a "$CFG/$g/." "$OUT/skel/.config/$g/"; log "  + skel/.config/$g/"; }
done

# ── Pack ──────────────────────────────────────────────────────────────────
SZ=$(du -sh "$OUT" | cut -f1); log ""; log "TOTAL bundle size: $SZ"
tar -C "$(dirname "$OUT")" -cf - "$(basename "$OUT")" | zstd -19 -T0 -o "${OUT}.tar.zst" 2>/dev/null
echo; echo "Bundle: $OUT/  ($SZ)"; echo "Tarball: ${OUT}.tar.zst"; echo "Manifest:"; cat "$MAN"
