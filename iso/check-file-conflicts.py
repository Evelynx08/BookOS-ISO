#!/usr/bin/env python3
"""Caza ficheros que dos paquetes reclaman con contenido distinto.

RPM solo tolera que dos paquetes traigan la misma ruta si el fichero es byte a
byte idéntico. Si difieren, aborta la transacción ENTERA, y lo que llega a
anaconda es un "The transaction process has ended with errors" que no dice qué
fichero fue. En un build de ISO eso son ~30 minutos de descarga para no
enterarte de nada.

Pasó de verdad: bookos-branding y bookos-settings empaquetaban los dos
/usr/share/bookos-settings/lockscreen/*.qml copiándolos del MISMO sitio. Eran
idénticos mientras salían del mismo commit, así que rpm lo dejaba pasar; al
recompilar solo uno de los dos, divergieron y el build dejó de terminar.

Alcance: solo los paquetes de BookOS. Son los que compilamos y publicamos
nosotros, y por tanto los únicos sin un CI que ya vigile esto. Comprobar los
1285 paquetes de la transacción obligaría a descargarlos todos (1,5 GiB) para
poder comparar digests, y Fedora ya garantiza que los suyos no se pisan.

Uso:  check-file-conflicts.py DIRECTORIO_CON_RPMS
Sale 1 y lista los choques si hay alguno.
"""
import collections
import subprocess
import sys
from pathlib import Path

# rpmfileAttrs: los %ghost no se instalan, así que nunca provocan un choque.
RPMFILE_GHOST = 64
# st_mode: los directorios sí pueden tener varios dueños, es normal en rpm.
S_IFMT, S_IFDIR = 0o170000, 0o040000

CONSULTA = "[%{FILENAMES}\t%{FILEDIGESTS}\t%{FILEMODES:octal}\t%{FILELINKTOS}\t%{FILEFLAGS}\n]"


def contenido_por_ruta(rpm):
    """Devuelve {ruta: huella} de un RPM, saltando directorios y %ghost.

    La huella lleva modo y destino del symlink además del digest: rpm también
    considera conflicto un mismo fichero con permisos distintos, y en un enlace
    el digest va vacío y lo único que distingue es a dónde apunta.
    """
    salida = subprocess.run(
        ["rpm", "-qp", "--nosignature", "--qf", CONSULTA, str(rpm)],
        capture_output=True, text=True, check=True,
    ).stdout

    ficheros = {}
    for linea in salida.splitlines():
        if not linea.strip():
            continue
        ruta, digest, modo, destino, banderas = linea.split("\t")
        if int(banderas) & RPMFILE_GHOST:
            continue
        if int(modo, 8) & S_IFMT == S_IFDIR:
            continue
        ficheros[ruta] = (digest, modo, destino)
    return ficheros


def busca_choques(rpms):
    reclamos = collections.defaultdict(dict)  # ruta -> {paquete: huella}
    for rpm in rpms:
        paquete = subprocess.run(
            ["rpm", "-qp", "--nosignature", "--qf", "%{NAME}", str(rpm)],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        for ruta, huella in contenido_por_ruta(rpm).items():
            reclamos[ruta][paquete] = huella

    return {
        ruta: dueños
        for ruta, dueños in reclamos.items()
        if len(dueños) > 1 and len(set(dueños.values())) > 1
    }


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)

    rpms = sorted(Path(sys.argv[1]).glob("*.rpm"))
    if not rpms:
        sys.exit(f"no hay ningún .rpm en {sys.argv[1]}")

    choques = busca_choques(rpms)
    if not choques:
        print(f"Sin conflictos de ficheros entre {len(rpms)} paquetes de BookOS.")
        return

    print("CONFLICTO DE FICHEROS: rpm abortará la transacción.\n", file=sys.stderr)
    for ruta, dueños in sorted(choques.items()):
        print(f"  {ruta}", file=sys.stderr)
        for paquete, (digest, modo, destino) in sorted(dueños.items()):
            detalle = digest or f"-> {destino}" or "(vacío)"
            print(f"      {paquete:<32} {modo}  {detalle}", file=sys.stderr)
    print(
        "\nDeja un único dueño para cada ruta. Que los dos paquetes copien el "
        "fichero\ndel mismo sitio no basta: divergen en cuanto recompilas uno solo.",
        file=sys.stderr,
    )
    sys.exit(1)


if __name__ == "__main__":
    main()
