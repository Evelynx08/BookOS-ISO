Name:           bookos-plasma-theme
Version:        0.6.1
Release:        1%{?dist}
Summary:        BookOS Plasma look — desktop theme, color schemes, Aurorae, Kvantum
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz

%description
The BookOS Plasma appearance: Plasma desktop themes, color schemes, Aurorae
window decorations and Kvantum styles. Shipped as part of the BookOS release
(pinned by bookos-meta) so the whole look updates in lockstep.

%prep
%setup -q

%install
# desktoptheme/*  -> /usr/share/plasma/desktoptheme/
if [ -d desktoptheme ]; then
    install -dm755 %{buildroot}/usr/share/plasma/desktoptheme
    cp -r desktoptheme/* %{buildroot}/usr/share/plasma/desktoptheme/
fi
# color-schemes/*.colors -> /usr/share/color-schemes/
if [ -d color-schemes ]; then
    install -dm755 %{buildroot}/usr/share/color-schemes
    cp -r color-schemes/* %{buildroot}/usr/share/color-schemes/
fi
# aurorae/themes/* -> /usr/share/aurorae/themes/  (skip helper scripts)
if [ -d aurorae/themes ]; then
    install -dm755 %{buildroot}/usr/share/aurorae/themes
    cp -r aurorae/themes/* %{buildroot}/usr/share/aurorae/themes/
fi
# kvantum/* -> /usr/share/Kvantum/
if [ -d kvantum ]; then
    install -dm755 %{buildroot}/usr/share/Kvantum
    cp -r kvantum/* %{buildroot}/usr/share/Kvantum/
fi

%files
%dir /usr/share/plasma/desktoptheme
/usr/share/plasma/desktoptheme/*
/usr/share/color-schemes/*
%dir /usr/share/aurorae/themes
/usr/share/aurorae/themes/*
%dir /usr/share/Kvantum
/usr/share/Kvantum/*

%changelog
* %(LC_ALL=C date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6-1
- 0.6: BookOS Plasma theme packaged
