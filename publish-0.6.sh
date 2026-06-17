#!/usr/bin/env bash
# Sube los RPMs de BookOS al canal del repo en el NAS y regenera el índice.
#
#   ./publish-0.6.sh [canal] [version]
#   ./publish-0.6.sh dev 0.6        (por defecto)
#
# Requiere: ssh/scp al NAS, y createrepo_c instalado en el NAS.
set -euo pipefail

CHANNEL="${1:-dev}"
VERSION="${2:-0.6}"
NAS="${NAS:-evelynx08@A5-NAS}"
REPO="/var/www/html/public/repo/fedora/44/x86_64/${CHANNEL}"
RPMS="$HOME/rpmbuild/RPMS/noarch"

echo "→ Canal: $CHANNEL · Versión: $VERSION · Destino: $NAS:$REPO"

# RPMs a subir (los que existan para esta versión)
shopt -s nullglob
files=("$RPMS"/bookos-{branding,widgets,plasma-theme,look-and-feel,meta,settings,viewer,player}-"$VERSION"-*.rpm)
[ ${#files[@]} -gt 0 ] || { echo "✗ no hay RPMs $VERSION en $RPMS"; exit 1; }

echo "→ Subiendo ${#files[@]} RPMs a /tmp del NAS…"
scp "${files[@]}" "$NAS:/tmp/"

echo "→ Moviendo al repo + createrepo_c (pide sudo en el NAS)…"
names=$(printf '/tmp/%s ' $(basename -a "${files[@]}"))
ssh -t "$NAS" "sudo mkdir -p '$REPO' && sudo mv $names '$REPO/' && sudo createrepo_c '$REPO' && sudo chown -R www-data:www-data '$REPO'"

echo "✓ Publicado. Comprueba:"
echo "  curl -sI https://bookos.es/repo/fedora/44/x86_64/$CHANNEL/repodata/repomd.xml | head -1"
