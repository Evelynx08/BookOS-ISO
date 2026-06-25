#!/usr/bin/env bash
# collect-widgets.sh — build the bookos-widgets sources reproducibly.
#
# Takes the REAL, maintained widgets from the dev machine
# (~/.local/share/plasma/plasmoids) and turns them into the BookOS-packaged
# plasmoids with short, branded ids (bookos-*). It:
#   1) copies each widget into the BookOS-Widgets/ repo under its short id
#      (repo = source of truth), rewriting metadata.json "Id" to the short id,
#   2) zips each repo widget into ~/rpmbuild/SOURCES/<short-id>.plasmoid,
#      which bookos-widgets.spec consumes.
#
# bookos-battery-pro has no live source widget, so its existing .plasmoid is
# kept as-is (extracted into the repo the first time so the repo stays complete).
#
#   bash collect-widgets.sh
set -euo pipefail

USER_HOME="${HOME}"
PLASMOIDS="$USER_HOME/.local/share/plasma/plasmoids"
REPO="${BOOKOS_WIDGETS_REPO:-$USER_HOME/Descargas/BookOS/BookOS-Widgets}"
SOURCES="$USER_HOME/rpmbuild/SOURCES"
mkdir -p "$REPO" "$SOURCES"

say() { printf '  + %s\n' "$*"; }

# real widget id (in ~/.local)  ->  short packaged id (bookos-*)
MAP=(
  "com.bookos.menu:bookos-menu"
  "com.bookos.launchpad:bookos-launchpad"
  "com.bookos.bookbar:bookos-bookbar"
  "com.bookos.win11menu:bookos-win11menu"
  "KdeControlStation:bookos-controlstation"
  "com.mi.widget.bateria:bookos-battery"
)

set_id() {
  # set_id <metadata.json> <new-id>: rewrite the KPlugin "Id" value in place.
  local f="$1" id="$2"
  sed -i -E "s/(\"Id\"[[:space:]]*:[[:space:]]*\")[^\"]*(\")/\1${id}\2/" "$f"
}

zip_plasmoid() {
  # zip_plasmoid <dir> <short-id>: build <short-id>.plasmoid in the repo (fresh,
  # so the repo stays the source of truth) and copy it into SOURCES for rpmbuild.
  local dir="$1" id="$2" repo_out="$REPO/$2.plasmoid" src_out="$SOURCES/$2.plasmoid"
  rm -f "$repo_out"
  ( cd "$dir" && zip -qr -X "$repo_out" . -x '*.bak' '*/.git/*' 'main.qml.bak' )
  cp -f "$repo_out" "$src_out"
  say "plasmoid: $repo_out -> $src_out"
}

echo ":: widgets reales -> repo (id reducido)"
for pair in "${MAP[@]}"; do
  real="${pair%%:*}"; short="${pair##*:}"
  src="$PLASMOIDS/$real"
  if [ ! -d "$src" ]; then
    echo "  ⚠ falta widget real: $src (omitido)" >&2
    continue
  fi
  dst="$REPO/$short"
  rm -rf "$dst"; mkdir -p "$dst"
  cp -a "$src/." "$dst/"
  # ship the widget, not editor leftovers
  find "$dst" -name '*.bak' -delete 2>/dev/null || true
  [ -f "$dst/metadata.json" ] && set_id "$dst/metadata.json" "$short"
  say "repo: $short (desde $real)"
  zip_plasmoid "$dst" "$short"
done

# bookos-battery-pro: no live source — keep the existing zip, seed the repo from
# it once so the repo is self-contained.
PRO_ZIP="$SOURCES/bookos-battery-pro.plasmoid"
PRO_DIR="$REPO/bookos-battery-pro"
if [ ! -d "$PRO_DIR" ] && [ -f "$PRO_ZIP" ]; then
  mkdir -p "$PRO_DIR"
  unzip -qo "$PRO_ZIP" -d "$PRO_DIR"
  set_id "$PRO_DIR/metadata.json" "bookos-battery-pro" 2>/dev/null || true
  say "repo: bookos-battery-pro (extraído del .plasmoid existente)"
elif [ -d "$PRO_DIR" ]; then
  zip_plasmoid "$PRO_DIR" "bookos-battery-pro"
else
  echo "  ⚠ bookos-battery-pro: sin repo ni .plasmoid — se queda como esté" >&2
fi

echo
echo "[✓] Widgets en $REPO y .plasmoid en $SOURCES. Build:"
echo "    rpmbuild -bb $(cd "$(dirname "$0")" && pwd)/bookos-widgets.spec"
