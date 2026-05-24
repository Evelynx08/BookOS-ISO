#!/usr/bin/env bash
# Recolecta todos los assets BookOS de tu sistema → ./assets/
# Para luego empaquetar y distribuir junto con apply-bookos-look.sh

set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
A="$SRC/assets"

mkdir -p "$A"/{look-and-feel,desktoptheme,plasmoids,aurorae,color-schemes,kvantum,gtk-themes,icons,sddm}

cp_if() { [[ -e "$1" ]] && cp -r "$1" "$2" && echo "  + $1"; }

echo ":: look-and-feel"
for t in "BookOS Dark" "BookOS Light"; do
    cp_if "$HOME/.local/share/plasma/look-and-feel/$t" "$A/look-and-feel/"
done

echo ":: desktoptheme"
for t in bookos-dark bookos-light BookOS-Dark-Blue; do
    cp_if "$HOME/.local/share/plasma/desktoptheme/$t" "$A/desktoptheme/"
done

echo ":: plasmoids"
for t in com.bookos.bookbar com.bookos.launchpad com.bookos.win11menu KdeControlStation; do
    cp_if "$HOME/.local/share/plasma/plasmoids/$t" "$A/plasmoids/"
done

echo ":: aurorae"
for t in BookOS-App-Dark BookOS-App-Light; do
    cp_if "$HOME/.local/share/aurorae/themes/$t" "$A/aurorae/"
done

echo ":: color-schemes"
cp $HOME/.local/share/color-schemes/BookOS*.colors "$A/color-schemes/" 2>/dev/null && echo "  + BookOS*.colors"

echo ":: kvantum"
for t in bookos-dark-blue bookos-light-blue; do
    cp_if "$HOME/.config/Kvantum/$t" "$A/kvantum/"
done

echo ":: gtk-themes"
for t in BookOS-Dark BookOS-Dark-Blue BookOS-Light; do
    cp_if "$HOME/.local/share/themes/$t" "$A/gtk-themes/"
done

echo ":: sddm (requiere sudo)"
if [[ -d /usr/share/sddm/themes/bookos ]]; then
    sudo cp -r /usr/share/sddm/themes/bookos "$A/sddm/" && sudo chown -R "$USER:$USER" "$A/sddm"
    echo "  + bookos sddm"
fi

echo
echo "Listo. Carpeta ./assets/ poblada."
du -sh "$A"
