Name:           bookos-branding
Version:        0.6
Release:        1%{?dist}
Summary:        BookOS branding (logos, wallpapers, SDDM/Plymouth themes)
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
Requires:       sddm
Requires:       plymouth

Provides:       system-logos
Provides:       system-release
Conflicts:      fedora-logos
Conflicts:      generic-logos

%description
BookOS branding: replaces Fedora default logos, wallpapers, login screen,
boot splash and OS metadata with BookOS identity.

%prep
%setup -q

%install
# OS logos / icons
install -Dm644 logos/bookos-symbolic.svg       %{buildroot}/usr/share/icons/hicolor/scalable/apps/start-here.svg
install -Dm644 logos/bookos.svg                %{buildroot}/usr/share/pixmaps/bookos.svg
install -Dm644 logos/bookos.png                %{buildroot}/usr/share/pixmaps/bookos.png

# Wallpapers
install -dm755 %{buildroot}/usr/share/backgrounds/bookos
cp -r wallpapers/* %{buildroot}/usr/share/backgrounds/bookos/

# SDDM theme
install -dm755 %{buildroot}/usr/share/sddm/themes/bookos
cp -r sddm-theme/* %{buildroot}/usr/share/sddm/themes/bookos/

# Plymouth boot splash
install -dm755 %{buildroot}/usr/share/plymouth/themes/bookos
cp -r plymouth-theme/* %{buildroot}/usr/share/plymouth/themes/bookos/

# KDE Plasma lockscreen QML (staged; activated by bookos-settings toggle)
install -dm755 %{buildroot}/usr/share/bookos-settings/lockscreen
cp lockscreen/*.qml %{buildroot}/usr/share/bookos-settings/lockscreen/

# Anaconda installer branding — kept under a bookos/ subdir so it never
# conflicts with files owned by the anaconda package itself.
if [ -d anaconda ]; then
    install -dm755 %{buildroot}/usr/share/anaconda/bookos
    cp -r anaconda/* %{buildroot}/usr/share/anaconda/bookos/
fi

%files
/usr/share/icons/hicolor/scalable/apps/start-here.svg
/usr/share/pixmaps/bookos.svg
/usr/share/pixmaps/bookos.png
/usr/share/backgrounds/bookos/
/usr/share/sddm/themes/bookos/
/usr/share/plymouth/themes/bookos/
/usr/share/bookos-settings/lockscreen/
/usr/share/anaconda/bookos/

%post
plymouth-set-default-theme bookos -R 2>/dev/null || true
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true

# ── Apply BookOS look to the Anaconda WebUI installer ───────────────────
# The WebUI (Cockpit/React) lives in a versioned path that differs across
# Fedora releases, so we locate index.html at runtime instead of hardcoding.
# Adding bookos.css beside it + a <link> is non-destructive and re-applies
# cleanly if anaconda-webui updates.
THEME=/usr/share/anaconda/bookos/theme
if [ -f "$THEME/anaconda-webui-bookos.css" ]; then
    for idx in $(find /usr/share/cockpit/anaconda-webui /usr/share/anaconda -name index.html -path '*anaconda-webui*' 2>/dev/null); do
        dir=$(dirname "$idx")
        cp -f "$THEME/anaconda-webui-bookos.css" "$dir/bookos.css" 2>/dev/null || true
        # inject the stylesheet link once
        if ! grep -q 'bookos.css' "$idx" 2>/dev/null; then
            sed -i 's#</head>#    <link rel="stylesheet" href="bookos.css">\n</head>#' "$idx" 2>/dev/null || true
        fi
    done
fi
# Kiosk-Firefox chrome tint (thin browser shell around the WebUI)
if [ -f "$THEME/userChrome.css" ]; then
    for fxdir in /usr/share/anaconda/firefox-theme/live/chrome /usr/share/anaconda/firefox-theme/default/chrome; do
        mkdir -p "$fxdir" 2>/dev/null && cp -f "$THEME/userChrome.css" "$fxdir/userChrome.css" 2>/dev/null || true
    done
fi
# Classic GTK Anaconda fallback CSS (older paths / non-WebUI)
[ -f "$THEME/anaconda-bookos.css" ] && cp -f "$THEME/anaconda-bookos.css" /usr/share/anaconda/anaconda-bookos.css 2>/dev/null || true
true

%changelog
* %(date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6-1
- 0.6: real Plymouth theme + Anaconda installer branding
