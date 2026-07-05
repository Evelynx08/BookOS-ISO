#!/usr/bin/env bash
# BookOS — construir la ISO desde cualquier host (CachyOS/Arch…) vía podman.
# Ejecuta build-iso.sh dentro de un Fedora 44 desechable (lorax necesita
# tooling Fedora + acceso root a loop devices, que el host Arch no da directo).
#
# DOS MODOS:
#   LOCAL (por defecto): usa los RPMs de ../localrepo-<version> SIN publicar.
#                        Ideal para PROBAR la ISO antes de subir nada.
#       sudo bash build-in-podman.sh dev 0.6.1
#
#   SERVIDOR (oficial):  ignora el repo local; la ISO tira del canal ya
#                        publicado en bookos.es. Usa esto DESPUÉS de publicar.
#       sudo NO_LOCAL_REPO=1 bash build-in-podman.sh dev 0.6.1
#
# Extra:  ALLAPPS S incluye todas las apps opcionales (player, viewer, recorder)
#         LOCALREPO=/otra/ruta  fuerza otro repo local
#
# La ISO sale en la raíz de BookOS-ISO/  (bookos-<version>-<canal>-x86_64.iso).
set -euo pipefail

# livemedia-creator necesita loop devices reales: podman DEBE correr como root
# (rootless + --privileged no da acceso a /dev/loop-control).
[ "$(id -u)" = "0" ] || { echo "✗ ejecuta con sudo: sudo bash $0 $*"; exit 1; }

CHANNEL="${1:-dev}"
VERSION="${2:-0.6.1}"
ALLAPPS="${3:-N}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"          # …/BookOS-ISO/iso
ROOT="$(dirname "$SCRIPT_DIR")"                      # …/BookOS-ISO
WORK="${WORK:-$ROOT/podman-work}"
IMG="${IMG:-registry.fedoraproject.org/fedora:44}"
mkdir -p "$WORK"

# ── Modo SERVIDOR: sin repo local ──────────────────────────────────────────
if [ -n "${NO_LOCAL_REPO:-}" ]; then
    echo ":: modo SERVIDOR — la ISO tirará del repo publicado del canal '$CHANNEL'"
    exec podman run --rm --privileged --network=host --security-opt label=disable \
        -v /dev:/dev \
        -v "$ROOT":/build \
        -v "$WORK":/work \
        -e WORKDIR=/work \
        "$IMG" bash -c "
            set -e
            # La imagen fedora de contenedor trae %_install_langs en_US: rpm
            # DESPOJA todas las traducciones de lo que instala anaconda en la
            # ISO (sesion en ingles + instalador sin espanol). Fuera.
            rm -f /etc/rpm/macros.image-language-conf
            dnf -y install lorax-lmc-novirt util-linux
            bash /build/iso/build-iso.sh BookOS $CHANNEL $VERSION /build $ALLAPPS
        "
fi

# ── Modo LOCAL (por defecto): RPMs de ../localrepo-<version> ────────────────
LOCALREPO="${LOCALREPO:-$ROOT/../localrepo-$VERSION}"
[ -d "$LOCALREPO" ] || { echo "✗ no existe LOCALREPO=$LOCALREPO (o usa NO_LOCAL_REPO=1 para el repo del servidor)"; exit 1; }
echo ":: modo LOCAL — usando RPMs de $LOCALREPO (sin publicar)"

exec podman run --rm --privileged --network=host --security-opt label=disable \
        -v /dev:/dev \
    -v "$ROOT":/build \
    -v "$LOCALREPO":/localrepo \
    -v "$WORK":/work \
    -e BOOKOS_LOCAL_REPO=/localrepo \
    -e WORKDIR=/work \
    "$IMG" bash -c "
        set -e
        rm -f /etc/rpm/macros.image-language-conf
        dnf -y install lorax-lmc-novirt createrepo_c util-linux
        createrepo_c --update /localrepo
        bash /build/iso/build-iso.sh BookOS $CHANNEL $VERSION /build $ALLAPPS
    "
