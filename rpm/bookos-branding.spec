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

%files
/usr/share/icons/hicolor/scalable/apps/start-here.svg
/usr/share/pixmaps/bookos.svg
/usr/share/pixmaps/bookos.png
/usr/share/backgrounds/bookos/
/usr/share/sddm/themes/bookos/
/usr/share/plymouth/themes/bookos/
/usr/share/bookos-settings/lockscreen/

%post
plymouth-set-default-theme bookos -R 2>/dev/null || true
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true

%changelog
* %(date "+%a %b %d %Y") BookOS <packages@bookos.es> - 1.0-1
- Initial BookOS branding RPM
