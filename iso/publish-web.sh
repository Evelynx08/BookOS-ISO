#!/usr/bin/env bash
# Publica una ISO ya construida en bookos.es (web de descargas).
#
#   iso/publish-web.sh <path-a-la.iso> <version> [canal] [notas]
#   iso/publish-web.sh bookos-0.6.1-dev-x86_64.iso 0.6.1-2 dev "fixes OOBE + widgets"
#
# version: semver-like, ^[0-9]+\.[0-9]+(\.[0-9]+)?(-[A-Za-z0-9.]+)?$ (lo valida
#          admin.php). canal: stable|beta|dev (default: dev).
#
# Dos pasos: 1) sube el fichero (+ .minisig si existe) a storage/iso/ en el NAS
# (vía /tmp + sudo mv — evelynx08 no está en el grupo www-data ahora mismo,
# así que el scp directo a storage/iso/ da Permiso denegado);
# 2) POST a admin.php?action=publish_local con X-Api-Key para registrarlo en
# el manifest (evita subir 4+ GB por HTTP, que chocaría con límites de PHP).
#
# Requiere: ssh/scp al NAS, y el token en ~/.config/bookos/apikey (chmod 600).
set -euo pipefail

ISO="${1:?uso: $0 <iso> <version> [canal] [notas]}"
VERSION="${2:?falta version}"
CHANNEL="${3:-dev}"
NOTES="${4:-}"
NAS="${NAS:-evelynx08@A5-NAS}"
API="${API:-https://bookos.es/api/admin.php}"
KEYFILE="${KEYFILE:-$HOME/.config/bookos/apikey}"

[ -f "$ISO" ] || { echo "✗ no existe: $ISO"; exit 1; }
[ -f "$KEYFILE" ] || { echo "✗ falta $KEYFILE (crea una API key en el panel admin, apikey_create)"; exit 1; }
APIKEY="$(<"$KEYFILE")"

FILENAME="BookOS-${VERSION}.iso"
echo "→ Versión: $VERSION · Canal: $CHANNEL · Destino: $NAS:storage/iso/$FILENAME"

# ── 1) Subir el fichero (+ firma si existe) ────────────────────────────────
FILES=("$ISO")
[ -f "$ISO.minisig" ] && FILES+=("$ISO.minisig")

echo "→ Subiendo ${#FILES[@]} fichero(s) a /tmp del NAS…"
scp "${FILES[@]}" "$NAS:/tmp/"

REMOTE_ISO="/tmp/$(basename "$ISO")"
REMOTE_SIG="/tmp/$(basename "$ISO").minisig"
echo "→ Moviendo a storage/iso/ como $FILENAME (pide sudo en el NAS)…"
ssh -t "$NAS" "
    sudo mv '$REMOTE_ISO' '/var/www/html/storage/iso/$FILENAME' &&
    ([ -f '$REMOTE_SIG' ] && sudo mv '$REMOTE_SIG' '/var/www/html/storage/iso/$FILENAME.minisig' || true) &&
    sudo chown www-data:www-data '/var/www/html/storage/iso/$FILENAME' &&
    sudo chmod 644 '/var/www/html/storage/iso/$FILENAME'
"

# ── 2) Registrar en el manifest ────────────────────────────────────────────
echo "→ Registrando en el manifest (publish_local)…"
resp="$(curl -s -w '\n%{http_code}' -X POST "$API?action=publish_local" \
    -H "X-Api-Key: $APIKEY" \
    -F "version=$VERSION" \
    -F "channel=$CHANNEL" \
    -F "filename=$FILENAME" \
    -F "notes=$NOTES")"
body="$(echo "$resp" | head -n -1)"
code="$(echo "$resp" | tail -n1)"

echo "$body"
if [ "$code" != "200" ]; then
    echo "✗ HTTP $code — no se registró en el manifest (el fichero ya está subido; corrige y reintenta solo el POST)"
    exit 1
fi
echo "✓ Publicado: https://bookos.es/api/releases.json.php"
