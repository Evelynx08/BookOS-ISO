Name:           bookos-meta
Version:        0.6
Release:        1%{?dist}
Summary:        BookOS umbrella package — pulls the full BookOS stack
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch

# ── System identity / look: PINNED to this exact release (macOS model) ──
# A version bump forces every visual piece to the SAME version atomically,
# so upgrading 0.5 → 0.6 brings the whole redesign in one dnf transaction.
Requires:       bookos-branding     = %{version}
Requires:       bookos-widgets      = %{version}
Requires:       bookos-plasma-theme = %{version}
# (sddm + wallpapers se entregan dentro de bookos-branding)

# ── Apps: con versión propia, solo necesitan un mínimo (no atadas al salto) ──
Requires:       bookos-settings   >= 0.5.0
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
* %(date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6-1
- 0.6: widgets pinned into the release set (macOS-style cohesive upgrade)
