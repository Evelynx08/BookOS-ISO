Name:           bookos-desktop-defaults
Version:        0.6
Release:        1%{?dist}
Summary:        BookOS default desktop appearance (global theme, icons, cursor, fonts, GTK + applied config)
License:        Redistributable, no modification
URL:            https://bookos.es/
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
# The global look-and-feel cascade references these, so ship them together.
Requires:       plasma-workspace
Requires:       kvantum

%description
Bundles every asset the BookOS desktop look depends on — the BookOS global
look-and-feel themes, the bookos-dark Plasma style, the ColorFlow icon set,
the MacTahoe cursor, the BookOS aurorae window decoration, the bookos kvantum
style, the catppuccin-bookos GTK theme, BookOS color schemes and the SN Pro
fonts — and the resolved Plasma config in /etc/skel so every new user (and the
live session) boots into the full BookOS appearance instead of plain Breeze.

%prep
%setup -q

%install
# Theme assets → /usr/share
install -dm755 %{buildroot}/usr/share
cp -a share/. %{buildroot}/usr/share/

# Applied appearance config → /etc/skel (copied into every new user's home)
install -dm755 %{buildroot}/etc/skel
cp -a skel/. %{buildroot}/etc/skel/

# Generate the file list (names contain spaces and '+', so let find build it).
( cd %{buildroot}
  find usr/share etc/skel -mindepth 1 \
    \( -type f -o -type l \) -printf '"/%p"\n' \
    -o -type d -printf '%%%%dir "/%p"\n'
) > %{_builddir}/%{name}-files.list

%files -f %{_builddir}/%{name}-files.list

%post
# Rebuild caches so the shipped icon theme / fonts are picked up immediately.
gtk-update-icon-cache -f /usr/share/icons/ColorFlow 2>/dev/null || true
fc-cache -f /usr/share/fonts/bookos 2>/dev/null || true

%changelog
* Thu Jun 19 2026 BookOS <packages@bookos.es> - 0.6-1
- Initial: full BookOS desktop appearance bundle + /etc/skel applied config
