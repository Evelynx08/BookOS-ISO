Name:           bookos-meta
Version:        0.6.1
Release:        1%{?dist}
Summary:        BookOS umbrella package — pulls the full BookOS stack
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch

# ── System identity / look: PINNED to this exact release (macOS model) ──
# A version bump forces every visual piece to the SAME version atomically,
# so upgrading 0.5 → 0.6 brings the whole redesign in one dnf transaction.
Requires:       bookos-branding      = %{version}
Requires:       bookos-widgets       = %{version}
Requires:       bookos-icons         = %{version}
Requires:       bookos-plasma-theme  = %{version}
Requires:       bookos-gtk-theme     = %{version}
Requires:       bookos-look-and-feel = %{version}
# Full appearance bundle (global theme, icons, cursor, fonts, GTK + /etc/skel
# applied config) — without this the desktop falls back to plain Breeze.
Requires:       bookos-desktop-defaults = %{version}
# (sddm + wallpapers se entregan dentro de bookos-branding)

# ── Apps: con versión propia, solo necesitan un mínimo (no atadas al salto) ──
# Mínimos alineados con lo realmente publicado en store-files (subir cuando se
# publique una versión mayor de la app correspondiente).
Requires:       bookos-settings   >= 0.4.3
Requires:       bookos-store      >= 0.3.0
Requires:       bookos-calc       >= 0.1.0
Requires:       bookos-clock      >= 0.6.0
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
* %(LC_ALL=C date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6.1-1
- 0.6.1: corrected panel layout (live capture, no dev paths), widgets reliably
  installed, signed repos (gpgcheck), Spanish installer + assorted fixes.

* Fri Jun 19 2026 BookOS <packages@bookos.es> - 0.6-1
- 0.6: widgets pinned into the release set (macOS-style cohesive upgrade)
