Name:           bookos-icons
Version:        0.6.1
Release:        1%{?dist}
Summary:        BookOS icon themes (Dark, Light, Tinted-Dark, Tinted-Light)
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch
# Tarball topdir bookos-icons-%{version}/ holding the BookOS-Icon-Pack-* dirs.
Source0:        %{name}-%{version}.tar.gz
# Every BookOS icon theme has `Inherits=Papirus,breeze,hicolor`; without Papirus
# present, any icon the theme doesn't define falls back to plain breeze
# (generic terminal/folder icons in Alt+Tab, etc.).
Requires:       papirus-icon-theme

%description
The BookOS icon themes. Each pack installs to /usr/share/icons under the name
declared in its index.theme (BookOS-Dark, BookOS-Light, BookOS-Tinted-Dark,
BookOS-Tinted-Light). Pulled by bookos-meta so every icon set tracks the
release version.

%prep
%setup -q

%install
DEST=%{buildroot}%{_datadir}/icons
mkdir -p "$DEST"
for pack in BookOS-Icon-Pack-*/; do
    [ -f "$pack/index.theme" ] || continue
    name="$(grep -m1 '^Name=' "$pack/index.theme" | cut -d= -f2 | tr -d '\r')"
    name="${name:-$(basename "$pack")}"
    rm -rf "$DEST/$name"
    cp -r "$pack" "$DEST/$name"
    rm -f "$DEST/$name/generador.py"     # ship the icons, not the generator
done

# Build the file list (theme names have no spaces, but stay robust).
( cd %{buildroot}
  find usr/share/icons -mindepth 1 \( -type f -o -type l \) -printf '/%p\n' \
    -o -type d -printf '%%%%dir /%p\n'
) > %{_builddir}/%{name}-files.list

%files -f %{_builddir}/%{name}-files.list

%post
for n in BookOS-Dark BookOS-Light BookOS-Tinted-Dark BookOS-Tinted-Light; do
    gtk-update-icon-cache -qf %{_datadir}/icons/"$n" 2>/dev/null || true
done

%changelog
* Fri Jun 19 2026 BookOS <packages@bookos.es> - 0.6-1
- Initial: BookOS Dark/Light/Tinted icon themes
