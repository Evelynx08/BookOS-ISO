#!/usr/bin/env bash
# BookOS Look Installer
# Aplica tema completo BookOS a KDE Plasma 6 (look-and-feel, plasmoids,
# kvantum, aurorae, color-schemes, gtk, sddm, splash).
#
# Uso:
#   ./apply-bookos-look.sh              # interactivo, pregunta dark/light
#   ./apply-bookos-look.sh --dark       # fuerza variante dark
#   ./apply-bookos-look.sh --light      # fuerza variante light
#   ./apply-bookos-look.sh --no-sddm    # salta SDDM (no requiere sudo)
#
# Estructura esperada (todas opcionales — script salta lo que falte):
#   ./assets/look-and-feel/BookOS\ Dark/
#   ./assets/look-and-feel/BookOS\ Light/
#   ./assets/desktoptheme/bookos-dark/
#   ./assets/desktoptheme/bookos-light/
#   ./assets/plasmoids/com.bookos.bookbar/
#   ./assets/plasmoids/KdeControlStation/
#   ./assets/aurorae/BookOS-App-Dark/
#   ./assets/aurorae/BookOS-App-Light/
#   ./assets/color-schemes/BookOSDark.colors
#   ./assets/color-schemes/BookOSLight.colors
#   ./assets/kvantum/bookos-dark-blue/
#   ./assets/kvantum/bookos-light-blue/
#   ./assets/gtk-themes/BookOS-Dark/
#   ./assets/gtk-themes/BookOS-Light/
#   ./assets/sddm/bookos/
#   ./splash/Splash.qml + ./book-os.svg

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$SRC/assets"

# ── colors ──
C_R='\033[1;31m'; C_G='\033[1;32m'; C_Y='\033[1;33m'; C_B='\033[1;34m'; C_0='\033[0m'
info() { echo -e "${C_B}::${C_0} $*"; }
ok()   { echo -e "${C_G}✓${C_0}  $*"; }
warn() { echo -e "${C_Y}!${C_0}  $*"; }
err()  { echo -e "${C_R}✗${C_0}  $*" >&2; }

# ── args ──
VARIANT=""
DO_SDDM=1
for a in "$@"; do
    case "$a" in
        --dark)    VARIANT="dark" ;;
        --light)   VARIANT="light" ;;
        --no-sddm) DO_SDDM=0 ;;
        -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
        *) err "arg desconocido: $a"; exit 1 ;;
    esac
done

# ── pick variant ──
if [[ -z "$VARIANT" ]]; then
    echo
    echo "  ┌─────────────────────────────┐"
    echo "  │   BookOS Look Installer     │"
    echo "  └─────────────────────────────┘"
    echo
    echo "  1) Dark  (azul oscuro)"
    echo "  2) Light (azul claro)"
    echo
    read -rp "  Selecciona variante [1/2]: " choice
    case "$choice" in
        1) VARIANT="dark" ;;
        2) VARIANT="light" ;;
        *) err "opción inválida"; exit 1 ;;
    esac
fi

if [[ "$VARIANT" == "dark" ]]; then
    LNF="BookOS Dark"
    DESKTOP_THEME="bookos-dark"
    AURORAE="BookOS-App-Dark"
    COLOR_SCHEME="BookOSDark"
    KVANTUM="bookos-dark-blue"
    GTK_THEME="BookOS-Dark"
    ICON_THEME="catppuccin-bookos-dark-blue-standard+default"
else
    LNF="BookOS Light"
    DESKTOP_THEME="bookos-light"
    AURORAE="BookOS-App-Light"
    COLOR_SCHEME="BookOSLight"
    KVANTUM="bookos-light-blue"
    GTK_THEME="BookOS-Light"
    ICON_THEME="catppuccin-bookos-light-blue-standard+default"
fi

info "Variante: $VARIANT"

# ── ensure dirs ──
mkdir -p "$HOME/.local/share/plasma/look-and-feel"
mkdir -p "$HOME/.local/share/plasma/desktoptheme"
mkdir -p "$HOME/.local/share/plasma/plasmoids"
mkdir -p "$HOME/.local/share/aurorae/themes"
mkdir -p "$HOME/.local/share/color-schemes"
mkdir -p "$HOME/.local/share/themes"
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.config/Kvantum"

# ── copy assets from repo ──
copy_dir() {
    local src="$1" dst="$2" label="$3"
    if [[ -d "$src" ]]; then
        cp -r "$src"/* "$dst"/ 2>/dev/null && ok "copiado $label"
    else
        warn "saltado $label (no encontrado: $src)"
    fi
}

copy_glob() {
    local src="$1" dst="$2" label="$3"
    if compgen -G "$src" >/dev/null; then
        cp $src "$dst"/ && ok "copiado $label"
    else
        warn "saltado $label"
    fi
}

if [[ -d "$ASSETS" ]]; then
    info "Copiando assets desde $ASSETS"
    copy_dir "$ASSETS/look-and-feel"   "$HOME/.local/share/plasma/look-and-feel"   "look-and-feel"
    copy_dir "$ASSETS/desktoptheme"    "$HOME/.local/share/plasma/desktoptheme"    "desktoptheme"
    copy_dir "$ASSETS/plasmoids"       "$HOME/.local/share/plasma/plasmoids"       "plasmoids"
    copy_dir "$ASSETS/aurorae"         "$HOME/.local/share/aurorae/themes"         "aurorae"
    copy_dir "$ASSETS/kvantum"         "$HOME/.config/Kvantum"                     "kvantum"
    copy_dir "$ASSETS/gtk-themes"      "$HOME/.local/share/themes"                 "gtk-themes"
    copy_dir "$ASSETS/icons"           "$HOME/.local/share/icons"                  "icons"
    copy_glob "$ASSETS/color-schemes/*.colors" "$HOME/.local/share/color-schemes" "color-schemes"

    # SDDM (requiere sudo)
    if [[ "$DO_SDDM" -eq 1 && -d "$ASSETS/sddm" ]]; then
        info "Instalando SDDM theme (necesita sudo)"
        sudo mkdir -p /usr/share/sddm/themes
        sudo cp -r "$ASSETS/sddm"/* /usr/share/sddm/themes/ && ok "sddm copiado"
    fi
else
    warn "carpeta ./assets/ no existe — saltando copia. Aplicando solo con lo ya instalado."
fi

# ── splash (componente local) ──
if [[ -f "$SRC/install.sh" ]]; then
    info "Instalando splash"
    bash "$SRC/install.sh" >/dev/null && ok "splash instalado"
fi

# ── apply settings ──
info "Aplicando configuración"

KW=$(command -v kwriteconfig6 || command -v kwriteconfig5 || echo "")
[[ -z "$KW" ]] && { err "kwriteconfig no encontrado"; exit 1; }

# look-and-feel global
if command -v lookandfeeltool >/dev/null 2>&1; then
    lookandfeeltool -a "$LNF" 2>/dev/null && ok "look-and-feel: $LNF" \
        || warn "lookandfeeltool falló para $LNF"
elif command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
    plasma-apply-lookandfeel -a "$LNF" && ok "look-and-feel: $LNF"
fi

# color scheme
if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme "$COLOR_SCHEME" 2>/dev/null && ok "colors: $COLOR_SCHEME" \
        || warn "color scheme $COLOR_SCHEME no aplicó"
fi

# desktop theme (plasma style)
if command -v plasma-apply-desktoptheme >/dev/null 2>&1; then
    plasma-apply-desktoptheme "$DESKTOP_THEME" 2>/dev/null && ok "desktop theme: $DESKTOP_THEME" \
        || warn "desktop theme falló"
fi

# window decoration (aurorae)
$KW --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae"
$KW --file kwinrc --group org.kde.kdecoration2 --key theme   "__aurorae__svg__$AURORAE"
ok "aurorae: $AURORAE"

# kvantum
if [[ -d "$HOME/.config/Kvantum/$KVANTUM" ]]; then
    mkdir -p "$HOME/.config/Kvantum"
    echo -e "[General]\ntheme=$KVANTUM" > "$HOME/.config/Kvantum/kvantum.kvconfig"
    ok "kvantum: $KVANTUM"
    # forzar qt5/qt6 a usar kvantum
    $KW --file kdeglobals --group KDE --key widgetStyle "kvantum"
fi

# gtk theme
if [[ -d "$HOME/.local/share/themes/$GTK_THEME" ]]; then
    $KW --file kdeglobals --group KDE --key GtkApplicationPreferDarkTheme \
        "$([[ "$VARIANT" == dark ]] && echo true || echo false)"
    # gtk3
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-application-prefer-dark-theme=$([[ "$VARIANT" == dark ]] && echo 1 || echo 0)
EOF
    cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
    ok "gtk: $GTK_THEME"
fi

# icon theme
if [[ -d "$HOME/.local/share/icons/$ICON_THEME" || -d "/usr/share/icons/$ICON_THEME" ]]; then
    if command -v plasma-apply-cursortheme >/dev/null 2>&1; then :; fi
    $KW --file kdeglobals --group Icons --key Theme "$ICON_THEME"
    ok "icons: $ICON_THEME"
fi

# SDDM (requiere sudo)
if [[ "$DO_SDDM" -eq 1 && -d "/usr/share/sddm/themes/bookos" ]]; then
    info "Configurando SDDM (sudo)"
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/bookos.conf >/dev/null <<EOF
[Theme]
Current=bookos
EOF
    ok "sddm activado"
fi

# refresh
info "Refrescando shell"
if command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell 2>/dev/null && kstart plasmashell >/dev/null 2>&1 &
elif command -v kquitapp5 >/dev/null 2>&1; then
    kquitapp5 plasmashell 2>/dev/null && kstart5 plasmashell >/dev/null 2>&1 &
fi

qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null \
    || qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true

echo
ok "BookOS look aplicado."
echo "   Cierra sesión y vuelve a entrar para ver SDDM + splash."
