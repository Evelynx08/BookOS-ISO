#!/usr/bin/env bash
# capture-look.sh — snapshot the BookOS desktop appearance from a reference PC.
#
# Run as the normal user whose desktop looks the way the ISO should look:
#   bash capture-look.sh
# It writes ./bookos-look-report.txt — send that file back.
#
# It only READS config; it changes nothing.
set -u
OUT="bookos-look-report.txt"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL="${XDG_DATA_HOME:-$HOME/.local/share}"

exec > "$OUT" 2>&1

sec() { echo; echo "===== $* ====="; }

echo "BookOS look report — $(date -Iseconds)"
echo "user=$USER host=$(hostname) plasma=$(plasmashell --version 2>/dev/null | head -1)"

sec "kdeglobals (appearance keys)"
grep -iE 'LookAndFeel|ColorScheme|^Theme=|IconTheme|cursor|widgetStyle|^Name=|fixed=|font=' "$CFG/kdeglobals" 2>/dev/null

sec "plasma desktop theme (plasmarc)"
grep -iE 'name=' "$CFG/plasmarc" 2>/dev/null

sec "window decoration (kwinrc [org.kde.kdecoration2] / [Windows])"
awk '/^\[org.kde.kdecoration2\]/{p=1} /^\[/{if($0!~/kdecoration2/)p=0} p' "$CFG/kwinrc" 2>/dev/null

sec "cursor (kcminputrc)"
grep -iE 'cursorTheme|cursorSize' "$CFG/kcminputrc" 2>/dev/null

sec "icons (kdeglobals [Icons])"
awk '/^\[Icons\]/{p=1;next} /^\[/{p=0} p' "$CFG/kdeglobals" 2>/dev/null

sec "lockscreen (kscreenlockerrc [Greeter])"
awk '/^\[Greeter\]/{p=1;print;next} /^\[/{p=0} p' "$CFG/kscreenlockerrc" 2>/dev/null

sec "splash screen (ksplashrc)"
cat "$CFG/ksplashrc" 2>/dev/null

sec "Kvantum (active)"
grep -iE 'theme=' "$CFG/Kvantum/kvantum.kvconfig" 2>/dev/null

sec "GTK theme (settings.ini)"
grep -iE 'theme-name|icon-name|font-name|cursor' "$CFG/gtk-3.0/settings.ini" "$CFG/gtk-4.0/settings.ini" 2>/dev/null

sec "Installed BookOS global look-and-feel packages"
for d in "$LOCAL"/plasma/look-and-feel/*Book* /usr/share/plasma/look-and-feel/*Book*; do
    [ -d "$d" ] && echo "  $d"
done

sec "Installed BookOS plasma desktopthemes"
for d in "$LOCAL"/plasma/desktoptheme/*ook* /usr/share/plasma/desktoptheme/*ook*; do
    [ -d "$d" ] && echo "  $(basename "$d")  ($d)"
done

sec "Installed BookOS color schemes"
for f in "$LOCAL"/color-schemes/*Book* /usr/share/color-schemes/*Book*; do
    [ -f "$f" ] && echo "  $(basename "$f")"
done

sec "Icon / cursor themes present (BookOS or Apple)"
for d in "$LOCAL"/icons/* /usr/share/icons/*; do
    b=$(basename "$d")
    case "$b" in *ook*|Apple*|*cursor*) echo "  $b" ;; esac
done 2>/dev/null

sec "SDDM theme config (/etc/sddm.conf.d)"
grep -riE 'Current=|Theme' /etc/sddm.conf.d/ 2>/dev/null

sec "Ownership of key theme dirs (orphan = hand-installed, needs packaging)"
for p in /usr/share/sddm/themes/bookos "/usr/share/plasma/look-and-feel/BookOS Dark"; do
    [ -e "$p" ] && { rpm -qf "$p" 2>/dev/null || echo "ORPHAN: $p"; }
done

echo
echo "===== END — send bookos-look-report.txt back ====="
