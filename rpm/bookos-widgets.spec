Name:           bookos-widgets
Version:        0.6.1
# Release (no Version) sube con los fixes: bookos-meta pinea `= %%{version}`.
Release:        6%{?dist}
Summary:        BookOS Plasma widgets (menu, launchpad, control station, battery…)
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch
Requires:       plasma-workspace

# Each .plasmoid is a zip of a plasmoid package; filename = plasmoid Id.
# Drop them next to this spec (or point %{_sourcedir} at BookOS-Widgets/).
Source0:        bookos-menu.plasmoid
Source1:        bookos-launchpad.plasmoid
Source2:        bookos-bookbar.plasmoid
Source3:        bookos-win11menu.plasmoid
Source4:        bookos-controlstation.plasmoid
Source5:        bookos-battery.plasmoid
Source6:        bookos-battery-pro.plasmoid
Source7:        bookos-controlcenter.plasmoid
Source8:        bookos-brightness.plasmoid
Source9:        bookos-volume.plasmoid
Source10:       bookos-network.plasmoid
Source11:       bookos-bluetooth.plasmoid
Source12:       bookos-notifications.plasmoid

%description
The BookOS desktop widget set: the macOS-style menu, launchpad, control
station, taskbar and battery plasmoids. Ships as part of the BookOS release
(pulled by bookos-meta), so a version bump updates every widget in lockstep.

%prep
# Nothing to unpack here — each source is a zip handled in %install.

%install
PLASMOID_DIR=%{buildroot}%{_datadir}/plasma/plasmoids
mkdir -p "$PLASMOID_DIR"
for src in %{SOURCE0} %{SOURCE1} %{SOURCE2} %{SOURCE3} %{SOURCE4} %{SOURCE5} %{SOURCE6} \
           %{SOURCE7} %{SOURCE8} %{SOURCE9} %{SOURCE10} %{SOURCE11} %{SOURCE12}; do
    # Plasmoid id = the "Id" in metadata.json; we read it after a temp extract.
    tmp=$(mktemp -d)
    unzip -qo "$src" -d "$tmp"
    id=$(grep -oP '"Id"\s*:\s*"\K[^"]+' "$tmp"/metadata.json 2>/dev/null | head -1)
    # Fallback: derive id from filename (strip .plasmoid)
    [ -z "$id" ] && id=$(basename "$src" .plasmoid)
    mkdir -p "$PLASMOID_DIR/$id"
    cp -a "$tmp"/. "$PLASMOID_DIR/$id/"
    rm -rf "$tmp"
done
# mktemp -d crea el staging 0700 y `cp -a tmp/.` copia ese modo al directorio
# del plasmoide -> en el sistema instalado queda drwx------ root:root y KPackage
# del usuario no puede entrar ("package ... does not exist"). Normaliza todo.
find "$PLASMOID_DIR" -type d -exec chmod 0755 {} +
find "$PLASMOID_DIR" -type f -exec chmod 0644 {} +

%files
%{_datadir}/plasma/plasmoids/*

%changelog
* %(LC_ALL=C date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6.1-3
- Rebuild widgets from live sources for the 0.6.1 ISO
* Thu Jul 02 2026 BookOS <packages@bookos.es> - 0.6.1-2
- Plasma 6.7 API fixes (batterymonitor→powerdevil requestedInhibitions,
  plasma-pa globalMuteSinks, Font.DemiBold, preferredRepresentation)
- brightness: snap slider fixed (id/function collision)
- launchpad: app-name cache + scored search, page culling, hover, dead code out
* %(LC_ALL=C date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6-1
- Widgets refreshed for BookOS 0.6 (performance, springs, control station polish)
