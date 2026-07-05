Name:           bookos-branding
Version:        0.6.1
Release:        5%{?dist}
Summary:        BookOS branding (logos, wallpapers, SDDM/Plymouth themes)
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch
Source0:        %{name}-%{version}.tar.gz
Requires:       sddm
Requires:       plymouth

Provides:       system-logos
Provides:       system-release
Conflicts:      fedora-logos
Conflicts:      generic-logos

%description
BookOS branding: replaces Fedora default logos, wallpapers, login screen,
boot splash and OS metadata with BookOS identity.

%prep
%setup -q

%install
# OS logos / icons
install -Dm644 logos/bookos-symbolic.svg       %{buildroot}/usr/share/icons/hicolor/scalable/apps/start-here.svg
install -Dm644 logos/bookos.svg                %{buildroot}/usr/share/pixmaps/bookos.svg
install -Dm644 logos/bookos.png                %{buildroot}/usr/share/pixmaps/bookos.png
# Icono del lanzador "Instalar BookOS" (liveinst)
if [ -f anaconda/pixmaps/bookos-install.svg ]; then
    install -Dm644 anaconda/pixmaps/bookos-install.svg %{buildroot}/usr/share/pixmaps/bookos-install.svg
fi

# Wallpapers
# Nunito (OFL) — reemplaza SN Pro (restrictiva); alias fontconfig para configs viejas
if [ -d fonts/nunito ]; then
    install -dm755 %{buildroot}%{_datadir}/fonts/bookos-nunito
    install -m644 fonts/nunito/*.ttf %{buildroot}%{_datadir}/fonts/bookos-nunito/
    install -m644 fonts/nunito/OFL.txt %{buildroot}%{_datadir}/fonts/bookos-nunito/
    install -Dm644 fonts/60-bookos-snpro-alias.conf         %{buildroot}%{_sysconfdir}/fonts/conf.d/60-bookos-snpro-alias.conf
fi

install -dm755 %{buildroot}/usr/share/backgrounds/bookos
cp -r wallpapers/* %{buildroot}/usr/share/backgrounds/bookos/

# Paquetes de wallpaper para el SELECTOR de Plasma (/usr/share/wallpapers).
# Los archivos sueltos de /usr/share/backgrounds NO salen en el selector —
# por eso solo se veia el azul. Cada paquete lleva la variante clara como
# images/ y la oscura como images_dark/ (Plasma 6 cambia solo con el tema).
for lp in wallpapers/Light/*.png; do
    name=$(basename "$lp" .png)
    Name="$(tr '[:lower:]' '[:upper:]' <<< ${name:0:1})${name:1}"
    pkg=%{buildroot}/usr/share/wallpapers/BookOS-$Name
    install -Dm644 "$lp" "$pkg/contents/images/2880x1800.png"
    [ -f "wallpapers/Dark/${name}_dark.png" ] &&         install -Dm644 "wallpapers/Dark/${name}_dark.png" "$pkg/contents/images_dark/2880x1800.png"
    install -Dm644 "$lp" "$pkg/contents/screenshot.png"
    cat > "$pkg/metadata.json" <<METAEOF
{
    "KPlugin": {
        "Id": "BookOS-$Name",
        "Name": "BookOS $Name",
        "License": "CC-BY-SA-4.0",
        "Authors": [{ "Name": "BookOS" }]
    }
}
METAEOF
done

# SDDM theme
install -dm755 %{buildroot}/usr/share/sddm/themes/bookos
cp -r sddm-theme/* %{buildroot}/usr/share/sddm/themes/bookos/

# Plymouth boot splash
install -dm755 %{buildroot}/usr/share/plymouth/themes/bookos
cp -r plymouth-theme/* %{buildroot}/usr/share/plymouth/themes/bookos/

# KDE Plasma lockscreen QML (staged; activated by bookos-settings toggle)
install -dm755 %{buildroot}/usr/share/bookos-settings/lockscreen
cp lockscreen/*.qml %{buildroot}/usr/share/bookos-settings/lockscreen/

# Anaconda installer branding — kept under a bookos/ subdir so it never
# conflicts with files owned by the anaconda package itself.
if [ -d anaconda ]; then
    install -dm755 %{buildroot}/usr/share/anaconda/bookos
    cp -r anaconda/* %{buildroot}/usr/share/anaconda/bookos/
fi

# Anaconda product profile — THIS is what makes the installer default to btrfs
# (file_system_type + btrfs partitioning) and load the BookOS WebUI stylesheet.
# Anaconda reads it from /usr/share/anaconda/product.d/ at runtime.
if [ -f anaconda/product.d/bookos.conf ]; then
    install -Dm644 anaconda/product.d/bookos.conf \
        %{buildroot}/usr/share/anaconda/product.d/bookos.conf
    # anaconda F35+ SOLO lee profile.d/ (con [Profile Detection] os_id=bookos);
    # product.d se mantiene por compatibilidad.
    install -Dm644 anaconda/product.d/bookos.conf \
        %{buildroot}/usr/share/anaconda/profile.d/bookos.conf
    # F44: anaconda SOLO carga perfiles de /etc/anaconda/profile.d (verificado
    # con pyanaconda real; /usr/share/anaconda/profile.d ni existe).
    install -Dm644 anaconda/product.d/bookos.conf \
        %{buildroot}%{_sysconfdir}/anaconda/profile.d/bookos.conf
fi
# WebUI stylesheet at the path referenced by bookos.conf's webui_stylesheet key.
if [ -f anaconda/theme/anaconda-webui-bookos.css ]; then
    install -Dm644 anaconda/theme/anaconda-webui-bookos.css \
        %{buildroot}/usr/share/anaconda/cockpit/anaconda-webui/preload/bookos.css
fi
# GTK custom_stylesheet path referenced by bookos.conf (legacy fallback UI).
if [ -f anaconda/theme/anaconda-bookos.css ]; then
    install -Dm644 anaconda/theme/anaconda-bookos.css \
        %{buildroot}/usr/share/anaconda/pixmaps/bookos/anaconda-bookos.css
fi
# Welcome addon referenced by the product profile.
if [ -d anaconda/addon/org_bookos_welcome ]; then
    install -dm755 %{buildroot}/usr/share/anaconda/addons
    cp -r anaconda/addon/org_bookos_welcome %{buildroot}/usr/share/anaconda/addons/
fi

%files
/etc/anaconda/profile.d/bookos.conf
/usr/share/pixmaps/bookos-install.svg
/usr/share/fonts/bookos-nunito/
%config(noreplace) /etc/fonts/conf.d/60-bookos-snpro-alias.conf
/usr/share/wallpapers/BookOS-*/
/usr/share/icons/hicolor/scalable/apps/start-here.svg
/usr/share/pixmaps/bookos.svg
/usr/share/pixmaps/bookos.png
/usr/share/backgrounds/bookos/
/usr/share/sddm/themes/bookos/
/usr/share/plymouth/themes/bookos/
/usr/share/bookos-settings/lockscreen/
/usr/share/anaconda/bookos/
/usr/share/anaconda/product.d/bookos.conf
/usr/share/anaconda/profile.d/bookos.conf
%dir /usr/share/anaconda/cockpit/anaconda-webui/preload
/usr/share/anaconda/cockpit/anaconda-webui/preload/bookos.css
/usr/share/anaconda/pixmaps/bookos/anaconda-bookos.css
/usr/share/anaconda/addons/org_bookos_welcome/

%post
plymouth-set-default-theme bookos -R 2>/dev/null || true
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true

# ── Apply BookOS look to the Anaconda WebUI installer ───────────────────
# The WebUI (Cockpit/React) lives in a versioned path that differs across
# Fedora releases, so we locate index.html at runtime instead of hardcoding.
# Adding bookos.css beside it + a <link> is non-destructive and re-applies
# cleanly if anaconda-webui updates.
THEME=/usr/share/anaconda/bookos/theme
if [ -f "$THEME/anaconda-webui-bookos.css" ]; then
    for idx in $(find /usr/share/cockpit/anaconda-webui /usr/share/anaconda -name index.html -path '*anaconda-webui*' 2>/dev/null); do
        dir=$(dirname "$idx")
        cp -f "$THEME/anaconda-webui-bookos.css" "$dir/bookos.css" 2>/dev/null || true
        cp -f /usr/share/anaconda/bookos/pixmaps/bookos-logo.svg "$dir/bookos-logo.svg" 2>/dev/null || true
        # inject the stylesheet link once
        if ! grep -q 'bookos.css' "$idx" 2>/dev/null; then
            sed -i 's#</head>#    <link rel="stylesheet" href="bookos.css">\n</head>#' "$idx" 2>/dev/null || true
        fi
    done
fi
# Kiosk-Firefox chrome tint (thin browser shell around the WebUI)
if [ -f "$THEME/userChrome.css" ]; then
    for fxdir in /usr/share/anaconda/firefox-theme/live/chrome /usr/share/anaconda/firefox-theme/default/chrome; do
        mkdir -p "$fxdir" 2>/dev/null && cp -f "$THEME/userChrome.css" "$fxdir/userChrome.css" 2>/dev/null || true
    done
fi
# Classic GTK Anaconda fallback CSS (older paths / non-WebUI)
[ -f "$THEME/anaconda-bookos.css" ] && cp -f "$THEME/anaconda-bookos.css" /usr/share/anaconda/anaconda-bookos.css 2>/dev/null || true
true

%changelog
* Sun Jul 05 2026 BookOS <packages@bookos.es> - 0.6.1-5
- userChrome.css del instalador: restaura la regla :has() que colapsa TODA la
  barra de Firefox (antes se veia el chrome completo: VPN, extensiones, tabs)
* Sun Jul 05 2026 BookOS <packages@bookos.es> - 0.6.1-4
- Perfil anaconda en /etc/anaconda/profile.d (ruta real en F44) -> btrfs de verdad
- default_partitioning: free en GiB (60/40 se parseaban como bytes)
* %(LC_ALL=C date "+%a %b %d %Y") BookOS <packages@bookos.es> - 0.6-1
- 0.6: real Plymouth theme + Anaconda installer branding
