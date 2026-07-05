#!/usr/bin/env bash
# BookOS — fija el color de una carpeta escribiendo su .directory (icono Papirus folder-<color>).
# Uso:  bookos-folder-color.sh <color|default> <carpeta...>
set -eu
color="$1"; shift
for dir in "$@"; do
    [ -d "$dir" ] || continue
    df="$dir/.directory"
    tmp="$(mktemp)"
    # conserva el resto del .directory, quita cualquier Icon previo
    if [ -f "$df" ]; then grep -v '^Icon=' "$df" > "$tmp" || true; else printf '[Desktop Entry]\n' > "$tmp"; fi
    grep -q '^\[Desktop Entry\]' "$tmp" || printf '[Desktop Entry]\n' >> "$tmp"
    if [ "$color" = "default" ]; then
        cp "$tmp" "$df"
    else
        awk -v ic="folder-$color" '/^\[Desktop Entry\]/{print; print "Icon="ic; next} {print}' "$tmp" > "$df"
    fi
    rm -f "$tmp"
    touch "$dir"
done
