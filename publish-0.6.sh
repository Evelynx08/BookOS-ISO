#!/usr/bin/env bash
# Sube los RPMs de BookOS al canal del repo en el NAS y regenera el índice.
#
#   ./publish-0.6.sh [canal] [version]
#   ./publish-0.6.sh dev 0.6        (por defecto)
#
# Requiere: ssh/scp al NAS, y createrepo_c instalado en el NAS.
set -euo pipefail

CHANNEL="${1:-dev}"
# Versión por defecto = la del spec de bookos-meta (fuente de verdad del
# release), así el default no se desincroniza cuando suben los specs.
VERSION="${2:-$(awk '/^Version:/{print $2; exit}' "$(dirname "$0")/rpm/bookos-meta.spec")}"
NAS="${NAS:-evelynx08@192.168.18.227}"
REPO="/var/www/html/public/repo/fedora/44/x86_64/${CHANNEL}"
# Misma URL que el gpgkey= de los .repo: contra esta clave se verifica al final.
PUBKEY_URL="${PUBKEY_URL:-https://bookos.es/api/pubkey.php?type=gpg}"
# Resolver el home real aunque se ejecute con sudo (evita /root/rpmbuild vacío)
USER_HOME="${SUDO_USER:+/home/$SUDO_USER}"
RPMROOT="${RPMROOT:-${USER_HOME:-$HOME}/rpmbuild/RPMS}"
RPMS="${RPMS:-$RPMROOT/noarch}"
ARCH_RPMS="${ARCH_RPMS:-$RPMROOT/$(uname -m)}"

echo "→ Canal: $CHANNEL · Versión: $VERSION · Destino: $NAS:$REPO"

# RPMs a subir: EXACTAMENTE los que entraron en la ISO, es decir, el repo
# candidato que dejan iso/check-packages-in-podman.sh y iso/build-apps-in-podman.sh.
#
# Antes esto era una lista de nombres escrita a mano con globs por $VERSION, y
# se quedó vieja sin avisar: faltaban bookos-desktop, bookos-explorer, calc,
# clock, notepad y store, y settings/player/viewer se buscaban entre los noarch
# cuando son binarios Tauri x86_64. Con `nullglob` eso no falla: sube media
# release en silencio. Leer el repo evita tener que acordarse de cada app nueva.
shopt -s nullglob
CANDIDATOS="${CANDIDATOS:-$(dirname "$0")/.build/package-check/repo}"
[ -d "$CANDIDATOS" ] || { echo "✗ no existe $CANDIDATOS (construye antes: iso/check-packages-in-podman.sh)"; exit 1; }

# Y no todo el directorio, sino lo que la ISO cogió DE AHÍ: el informe de
# resolución dice, paquete a paquete, si ganó el candidato local o el que ya
# está publicado. Subir el directorio entero publicaría versiones más viejas
# que las del canal (el repo local guarda bookos-widgets-0.6.1-8 mientras el
# servidor sirve la -9, que es la que usó la ISO).
RESOLUCION="${RESOLUCION:-$(dirname "$0")/.build/package-check/dependency-resolution.log}"
[ -f "$RESOLUCION" ] || { echo "✗ falta $RESOLUCION (corre antes iso/check-packages-in-podman.sh)"; exit 1; }

# Columnas de la tabla de dnf: nombre arch epoch:version-release repo tamaño.
mapfile -t files < <(
    awk '$2 ~ /^(noarch|x86_64|i686)$/ && $3 ~ /^[0-9]+:/ && $4 == "bookos-candidate" {
             evr = $3; sub(/^[0-9]+:/, "", evr); print $1 "-" evr "." $2 ".rpm"
         }' "$RESOLUCION" | sort -u | while read -r fichero; do
        [ -f "$CANDIDATOS/$fichero" ] && printf '%s\n' "$CANDIDATOS/$fichero"
    done
)
[ ${#files[@]} -gt 0 ] || { echo "✗ el informe no lista ningún paquete local; ¿está al día?"; exit 1; }
echo "→ ${#files[@]} paquetes desde $CANDIDATOS:"
printf '    %s\n' "${files[@]##*/}"

# ── Los RPMs se firman EN EL NAS, no aquí ──────────────────────────────────
# La clave de release ("BookOS Release Signing") vive solo en el keyring del NAS
# y no debe salir de ahí. Aquí NO se firma: los paquetes suben SIN firma.
#
# Por qué importa: el NAS corre rpm 4.20, que al firmar escribe RPMTAG_OPENPGP
# solo si el paquete no traía ya uno — y --delsign tampoco sabe borrarlo. Si un
# RPM llega firmado desde aquí (rpm 6 escribe ese tag), el NAS le añade encima su
# RSAHEADER pero la firma vieja se queda dentro, y Fedora 44 —que verifica
# RPMTAG_OPENPGP— lo rechaza con "Importación de la clave no ayuda, ¿clave
# incorrecta?". Por eso abortamos si algo llega firmado.
GPG_NAME="${BOOKOS_GPG_NAME:-BookOS Release Signing}"

echo "→ Comprobando que ningún RPM lleve firma previa…"
presigned=()
for f in "${files[@]}"; do
    sig=$(rpm -qp --nosignature --qf '%{RSAHEADER:pgpsig}%{OPENPGP}' "$f" 2>/dev/null)
    case "$sig" in *"(none)(none)"*) ;; *) presigned+=("$(basename "$f")") ;; esac
done
if [ ${#presigned[@]} -gt 0 ]; then
    echo "✗ Estos RPMs ya vienen firmados y el NAS no podrá limpiar la firma vieja:"
    printf '    %s\n' "${presigned[@]}"
    echo "  Quítales la firma con rpm >= 6 antes de publicar:"
    echo "      rpmsign --delsign <esos .rpm>"
    exit 1
fi
echo "  ✓ los ${#files[@]} van sin firmar"

echo "→ Subiendo ${#files[@]} RPMs a /tmp del NAS…"
scp "${files[@]}" "$NAS:/tmp/"

echo "→ Firmando en el NAS + moviendo al repo + createrepo_c (pide sudo en el NAS)…"
names=$(printf '/tmp/%s ' $(basename -a "${files[@]}"))
# rpmsign va SIN sudo: la clave está en el keyring del usuario, no en el de root.
ssh -t "$NAS" "set -e
    rpmsign --define '_gpg_name $GPG_NAME' --addsign $names
    sudo mkdir -p '$REPO'
    sudo mv $names '$REPO/'
    sudo createrepo_c '$REPO'
    sudo chown -R www-data:www-data '$REPO'"

# ── Verificar lo YA publicado, con el rpm de esta máquina ──────────────────
# Esta máquina es Fedora (rpm >= 6): verifica RPMTAG_OPENPGP igual que lo hará el
# dnf de los usuarios. Es la única comprobación que de verdad predice si un
# cliente aceptará el paquete — el rpm 4 del NAS diría "OK" aunque estuviera mal.
BASEURL="https://bookos.es/repo/fedora/44/x86_64/$CHANNEL"
echo "→ Verificando las firmas publicadas contra $PUBKEY_URL…"
vdb=$(mktemp -d); trap 'rm -rf "$vdb"' EXIT
curl -fsS "$PUBKEY_URL" -o "$vdb/pubkey.asc"
rpmkeys --dbpath="$vdb" --import "$vdb/pubkey.asc"
bad=0
for f in $(basename -a "${files[@]}"); do
    if ! curl -fsS "$BASEURL/$f" -o "$vdb/p.rpm"; then
        echo "  ✗ $f — no se pudo descargar del repo"; bad=1; continue
    fi
    if ! rpmkeys --dbpath="$vdb" --checksig "$vdb/p.rpm" >/dev/null 2>&1; then
        echo "  ✗ $f — FIRMA INCORRECTA (los clientes lo rechazarán)"; bad=1
    fi
done
if [ "$bad" -ne 0 ]; then
    echo "✗ Hay paquetes publicados con firma inválida. NO anuncies esta versión."
    exit 1
fi

echo "✓ Publicado y verificado: los ${#files[@]} RPMs validan con la clave que sirve el servidor."
echo "  curl -sI $BASEURL/repodata/repomd.xml | head -1"
