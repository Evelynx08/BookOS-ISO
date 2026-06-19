Name:           bookos-widgets
Version:        0.6
Release:        1%{?dist}
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

%description
The BookOS desktop widget set: the macOS-style menu, launchpad, control
station, taskbar and battery plasmoids. Ships as part of the BookOS release
(pulled by bookos-meta), so a version bump updates every widget in lockstep.

%prep
# Nothing to unpack here — each source is a zip handled in %install.

%install
PLASMOID_DIR=%{buildroot}%{_datadir}/plasma/plasmoids
mkdir -p "$PLASMOID_DIR"
for src in %{SOURCE0} %{SOURCE1} %{SOURCE2} %{SOURCE3} %{SOURCE4} %{SOURCE5} %{SOURCE6}; do
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

%files
%{_datadir}/plasma/plasmoids/*

%changelog
* %(LC_ALL=C date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6-1
- Widgets refreshed for BookOS 0.6 (performance, springs, control station polish)
