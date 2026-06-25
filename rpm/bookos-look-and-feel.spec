Name:           bookos-look-and-feel
Version:        0.6.1
Release:        1%{?dist}
Summary:        BookOS default desktop layout (places the BookOS widgets on the panel)
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch
Source0:        plasma-org.kde.plasma.desktop-appletsrc
# The layout references these widgets by id, so it must not be installed without them.
Requires:       bookos-widgets = %{version}
Requires:       plasma-workspace

%description
The default BookOS desktop: a ready-made Plasma panel layout that places the
BookOS widgets (menu, launchpad, bookbar, control station, battery) and sets
the BookOS wallpaper. Shipped via /etc/skel so every new user — including the
one created by the installer — boots straight into the BookOS desktop instead
of an empty Plasma panel.

%install
# /etc/skel: copied into every new user's home by useradd (and by Anaconda).
install -dm755 %{buildroot}/etc/skel/.config
install -Dm644 %{SOURCE0} %{buildroot}/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc

# Also keep a system copy so kickstart/first-boot can re-apply if needed.
install -dm755 %{buildroot}/usr/share/bookos/layouts
install -Dm644 %{SOURCE0} %{buildroot}/usr/share/bookos/layouts/default-appletsrc

%files
/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc
/usr/share/bookos/layouts/default-appletsrc

%changelog
* %(LC_ALL=C date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6-1
- 0.6: default desktop layout with BookOS widgets pre-placed
