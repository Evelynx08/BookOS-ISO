#!/usr/bin/env bash
# BookOS — abre una terminal en la carpeta dada (para el ServiceMenu de click-derecho).
# Prefiere bookos-shell; si no está, konsole.
set -eu
target="${1:-$PWD}"
[ -d "$target" ] || target="$(dirname "$target")"
cd "$target" || exit 1
if command -v bookos-shell >/dev/null 2>&1; then
    exec bookos-shell
elif command -v konsole >/dev/null 2>&1; then
    exec konsole --workdir "$target"
else
    exec xterm
fi
