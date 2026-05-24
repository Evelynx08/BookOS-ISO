Name:           bookos-meta
Version:        1.0
Release:        1%{?dist}
Summary:        BookOS umbrella package — pulls the full BookOS stack
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch

# Core stack — DNF will upgrade these in lockstep when bookos-meta bumps.
Requires:       bookos-branding   = %{version}-%{release}
Requires:       bookos-settings   >= 0.4.2
Requires:       bookos-store      >= 0.3.0
Requires:       bookos-calc       >= 0.1.0
Requires:       bookos-clock      >= 1.0.0
Requires:       bookos-notepad    >= 0.1.0
# KDE base
Requires:       plasma-workspace
Requires:       sddm
Requires:       dolphin
Requires:       konsole

%description
Umbrella package for the BookOS desktop. Installing or upgrading bookos-meta
brings the rest of the BookOS stack to the matching release version.

This RPM contains no files — it only defines Requires.

%files
# (empty)

%changelog
* %(date "+%a %b %d %Y") BookOS <packages@bookos.es> - 1.0-1
- 1.0 release
