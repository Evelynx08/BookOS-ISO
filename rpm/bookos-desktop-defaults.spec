Name:           bookos-desktop-defaults
Version:        0.6.1
Release:        1%{?dist}
Summary:        BookOS default desktop appearance (global theme, icons, cursor, fonts, GTK + applied config)
License:        Redistributable, no modification
URL:            https://bookos.es/
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
# The global look-and-feel cascade references these, so ship them together.
Requires:       plasma-workspace
Requires:       kvantum
# The shipped icon theme inherits Papirus; needed or icons fall back to breeze.
Requires:       papirus-icon-theme
# The login apply step (see %install) copies the BookOS panel layout shipped by
# bookos-look-and-feel and shows the bookos-* plasmoids shipped by bookos-widgets.
# Pulling them here means existing installs gain both on a plain `dnf upgrade`.
Requires:       bookos-look-and-feel
Requires:       bookos-widgets

%description
Bundles every asset the BookOS desktop look depends on — the BookOS global
look-and-feel themes, the bookos-dark Plasma style, the BookOS aurorae window
decoration, the bookos kvantum style, the catppuccin-bookos GTK theme and
BookOS color schemes — and the resolved Plasma config in /etc/skel so every new
user (and the live session) boots into the full BookOS appearance instead of
plain Breeze. (Cursor theme and fonts are intentionally NOT shipped — BookOS
keeps the stock cursor/fonts and ships only its own icon packs via bookos-icons.)

%prep
%setup -q

%install
# Theme assets → /usr/share
install -dm755 %{buildroot}/usr/share
cp -a share/. %{buildroot}/usr/share/

# Applied appearance config → /etc/skel (copied into every new user's home)
install -dm755 %{buildroot}/etc/skel
cp -a skel/. %{buildroot}/etc/skel/

# ── Apply BookOS panel layout to ALREADY-INSTALLED users ────────────────────
# /etc/skel only reaches NEW users. Systems installed before the widgets fix
# have a pre-widget panel and never pick up the new layout. This system-wide
# login hook runs once per existing user to give them the bookos-* plasmoids.
#
# Guards (must ALL hold or it no-ops, so customised panels are never clobbered):
#   - per-user marker absent (so it runs at most once, ever), AND
#   - the user's current panel has NO "bookos-" plasmoid (i.e. a pre-fix layout).
# It seeds the layout from the system copy bookos-look-and-feel ships at
# /usr/share/bookos/layouts/default-appletsrc, then restarts plasmashell.
install -dm755 %{buildroot}/usr/libexec
cat > %{buildroot}/usr/libexec/bookos-apply-layout <<'SH'
#!/usr/bin/env bash
# Idempotent, per-user, runs at login via /etc/xdg/autostart.
set -eu
SRC=/usr/share/bookos/layouts/default-appletsrc
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/plasma-org.kde.plasma.desktop-appletsrc"
MARK="${XDG_CONFIG_HOME:-$HOME/.config}/bookos/.layout-applied"

# Nothing to apply if the system layout isn't installed.
[ -f "$SRC" ] || exit 0
# Already handled this user once — never touch their panel again.
[ -f "$MARK" ] && exit 0
# User already has BookOS widgets in their panel — leave their setup alone,
# just mark so we don't re-check every login.
if [ -f "$DEST" ] && grep -q 'bookos-' "$DEST"; then
    mkdir -p "$(dirname "$MARK")"; : > "$MARK"; exit 0
fi

# Apply: back up the old panel, drop in the BookOS layout, mark, reload shell.
mkdir -p "$(dirname "$MARK")" "$(dirname "$DEST")"
[ -f "$DEST" ] && cp -f "$DEST" "$DEST.pre-bookos.bak"
cp -f "$SRC" "$DEST"
: > "$MARK"

# Restart plasmashell so the new panel takes effect this session (kde5 or kde6).
if command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell 2>/dev/null || true
elif command -v kquitapp5 >/dev/null 2>&1; then
    kquitapp5 plasmashell 2>/dev/null || true
fi
( command -v kstart >/dev/null 2>&1 && kstart plasmashell || \
  command -v kstart5 >/dev/null 2>&1 && kstart5 plasmashell || \
  setsid plasmashell ) >/dev/null 2>&1 &
exit 0
SH
chmod 0755 %{buildroot}/usr/libexec/bookos-apply-layout

install -dm755 %{buildroot}/etc/xdg/autostart
cat > %{buildroot}/etc/xdg/autostart/bookos-apply-layout.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=BookOS Apply Panel Layout
Comment=One-time: give pre-existing users the BookOS panel widgets
Exec=/usr/libexec/bookos-apply-layout
OnlyShowIn=KDE;
X-KDE-autostart-phase=2
NoDisplay=true
EOF

# Drop assets already owned by bookos-plasma-theme (Kvantum styles, Plasma
# desktoptheme, color schemes, aurorae). Shipping them here too causes rpm file
# conflicts. desktop-defaults only owns the UNIQUE bits (global look-and-feel,
# ColorFlow icons, MacTahoe cursor, SN Pro fonts, GTK theme + skel config).
rm -rf %{buildroot}/usr/share/Kvantum
rm -rf %{buildroot}/usr/share/plasma/desktoptheme
rm -rf %{buildroot}/usr/share/color-schemes
rm -rf %{buildroot}/usr/share/aurorae
# BookOS GTK themes are owned by bookos-gtk-theme; drop them here if the captured
# active theme happens to be one of them, to avoid an rpm file conflict.
rm -rf %{buildroot}/usr/share/themes/BookOS-*

# Generate the file list (names contain spaces and '+', so let find build it).
( cd %{buildroot}
  find usr/share etc/skel -mindepth 1 \
    \( -type f -o -type l \) -printf '"/%p"\n' \
    -o -type d -printf '%%%%dir "/%p"\n'
) > %{_builddir}/%{name}-files.list

%files -f %{_builddir}/%{name}-files.list
%attr(0755,root,root) /usr/libexec/bookos-apply-layout
/etc/xdg/autostart/bookos-apply-layout.desktop

%post
# Rebuild the icon cache so the shipped theme is picked up immediately.
# (No fonts/cursor shipped here — icons live in bookos-icons.)
gtk-update-icon-cache -qf /usr/share/icons/hicolor 2>/dev/null || true

%changelog
* %(LC_ALL=C date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6.1-1
- Pull bookos-widgets + bookos-look-and-feel so `dnf upgrade` gives existing
  installs the plasmoids and panel layout.
- Add one-time login apply (/etc/xdg/autostart) that gives pre-fix users the
  BookOS panel; guarded by a per-user marker and skips customised panels.
- Panel layout shipped from the live capture (correct heights / fit+fill /
  floating, no dev paths).

* Fri Jun 19 2026 BookOS <packages@bookos.es> - 0.6-1
- Initial: full BookOS desktop appearance bundle + /etc/skel applied config
