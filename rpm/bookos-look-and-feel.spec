Name:           bookos-look-and-feel
Version:        0.6.1
Release:        5%{?dist}
Summary:        BookOS default desktop layout (places the BookOS widgets on the panel)
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch
Source0:        plasma-org.kde.plasma.desktop-appletsrc
# Plasma 6 stores panel thickness/floating in plasmashellrc, NOT in the
# appletsrc — without it the ISO panels come out at the stock 44px height.
Source1:        plasmashellrc
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
install -Dm644 %{SOURCE1} %{buildroot}/etc/skel/.config/plasmashellrc

# Also keep a system copy so kickstart/first-boot can re-apply if needed.
install -dm755 %{buildroot}/usr/share/bookos/layouts
install -Dm644 %{SOURCE0} %{buildroot}/usr/share/bookos/layouts/default-appletsrc
install -Dm644 %{SOURCE1} %{buildroot}/usr/share/bookos/layouts/default-plasmashellrc

%files
/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc
/etc/skel/.config/plasmashellrc
/usr/share/bookos/layouts/default-appletsrc
/usr/share/bookos/layouts/default-plasmashellrc

%changelog
* Sat Jul 04 2026 BookOS <packages@bookos.es> - 0.6.1-3
- Bandeja del sistema (solo Notificaciones, oculta) para habilitar los banners
  flotantes: el motor de popups vive en el applet real de KDE, que necesita estar
  instanciado. Tambien da hogar a iconos de bandeja de apps (Discord, etc.)
* %(LC_ALL=C date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6.1-2
- Recaptured layout: new control-center widget family (bluetooth/brightness/
  network/volume/notifications/controlcenter) on the top panel
- Ship plasmashellrc (panel thickness 52px dock / 32px top, floating) — Plasma 6
  keeps panel geometry there, fixes wrong panel heights on the ISO
* %(LC_ALL=C date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6-1
- 0.6: default desktop layout with BookOS widgets pre-placed
