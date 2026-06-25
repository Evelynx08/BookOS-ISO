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
# Resolver el home real aunque se ejecute con sudo (evita /root/rpmbuild vacío)
USER_HOME="${SUDO_USER:+/home/$SUDO_USER}"
RPMROOT="${RPMROOT:-${USER_HOME:-$HOME}/rpmbuild/RPMS}"
RPMS="${RPMS:-$RPMROOT/noarch}"
ARCH_RPMS="${ARCH_RPMS:-$RPMROOT/$(uname -m)}"

echo "→ Canal: $CHANNEL · Versión: $VERSION · Destino: $NAS:$REPO"

# RPMs a subir (los que existan para esta versión)
shopt -s nullglob
# noarch: temas/widgets/apps + el módulo de audio DKMS (es noarch).
files=("$RPMS"/bookos-{branding,widgets,icons,plasma-theme,gtk-theme,look-and-feel,desktop-defaults,meta,settings,viewer,player,galaxybook-audio}-"$VERSION"-*.rpm)
# arch-specific: libfprint-bookos (compilado). Versiona aparte (1.94.9), así que
# se recoge por nombre, no por $VERSION.
files+=("$ARCH_RPMS"/libfprint-bookos-*.rpm)
[ ${#files[@]} -gt 0 ] || { echo "✗ no hay RPMs $VERSION en $RPMS"; echo "  (si están en otra ruta: RPMS=/ruta ./publish-0.6.sh $CHANNEL $VERSION)"; exit 1; }

# ── Firmar los RPMs ────────────────────────────────────────────────────────
# Los repos instalados tienen gpgcheck=1, así que los paquetes DEBEN ir firmados
# o dnf los rechazará en los dispositivos. La clave pública se sirve en
# https://bookos.es/api/pubkey.php?type=gpg (el gpgkey= de los .repo) para que el
# primer install/upgrade la importe solo. SIGN=0 omite la firma (NO recomendado).
GPG_NAME="${BOOKOS_GPG_NAME:-$(rpm --eval '%{?_gpg_name}')}"
if [ "${SIGN:-1}" != "0" ]; then
    [ -n "$GPG_NAME" ] || { echo "✗ Sin clave GPG: define _gpg_name en ~/.rpmmacros o BOOKOS_GPG_NAME=…  (o SIGN=0 para omitir, romperá gpgcheck=1)"; exit 1; }
    command -v rpmsign >/dev/null || { echo "✗ falta rpmsign: sudo dnf install rpm-sign"; exit 1; }
    echo "→ Firmando ${#files[@]} RPMs con '$GPG_NAME'…"
    rpmsign --define "_gpg_name $GPG_NAME" --addsign "${files[@]}"
else
    echo "⚠ SIGN=0: subiendo RPMs SIN firmar — gpgcheck=1 los rechazará en los dispositivos."
fi

echo "→ Subiendo ${#files[@]} RPMs a /tmp del NAS…"
scp "${files[@]}" "$NAS:/tmp/"

echo "→ Moviendo al repo + createrepo_c (pide sudo en el NAS)…"
names=$(printf '/tmp/%s ' $(basename -a "${files[@]}"))
ssh -t "$NAS" "sudo mkdir -p '$REPO' && sudo mv $names '$REPO/' && sudo createrepo_c '$REPO' && sudo chown -R www-data:www-data '$REPO'"

echo "✓ Publicado. Comprueba:"
echo "  curl -sI https://bookos.es/repo/fedora/44/x86_64/$CHANNEL/repodata/repomd.xml | head -1"
