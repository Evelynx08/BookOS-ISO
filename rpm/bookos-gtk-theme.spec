Name:           bookos-gtk-theme
Version:        0.6.1
Release:        1%{?dist}
Summary:        BookOS GTK themes (Dark/Light · Blue/Green)
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch
# Tarball with a top-level themes/ dir holding BookOS-{Dark,Light}-{Blue,Green}/
# (built by collect-themes.sh from BookOS-GTK-Theme/).
Source0:        %{name}-%{version}.tar.gz
Requires:       gtk3

%description
The BookOS GTK themes (GTK3/GTK4, plus gnome-shell/cinnamon/xfwm/metacity
variants) in Dark and Light, Blue and Green. Installed to /usr/share/themes so
GTK apps match the Plasma look. Pulled by bookos-meta so the GTK look tracks
the release version.

%prep
%setup -q

%install
install -dm755 %{buildroot}/usr/share/themes
cp -r themes/* %{buildroot}/usr/share/themes/

%files
/usr/share/themes/BookOS-Dark-Blue/
/usr/share/themes/BookOS-Dark-Green/
/usr/share/themes/BookOS-Light-Blue/
/usr/share/themes/BookOS-Light-Green/

%changelog
* Fri Jun 19 2026 BookOS <packages@bookos.es> - 0.6-1
- Initial: BookOS GTK themes (Dark/Light, Blue/Green)
