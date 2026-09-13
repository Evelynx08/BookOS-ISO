"""Comprueba el detector de conflictos con RPMs construidos al vuelo.

Se construyen paquetes de verdad con rpmbuild en vez de simular la salida de
`rpm -qp`: lo que se quiere fijar es que coincidimos con el criterio REAL de rpm
(digest, modo, symlink; los directorios y los %ghost no cuentan), y eso solo lo
demuestra un RPM auténtico.
"""
import importlib.util
import shutil
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("check_file_conflicts", ROOT / "check-file-conflicts.py")
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)

RUTA = "/usr/share/bookos-test/compartido.qml"


def construye(destino, nombre, contenido, modo="0644", ghost=False):
    """Construye un noarch mínimo que instala RUTA con ese contenido.

    El modo va en %attr y no en el install: rpmbuild reescribe los permisos del
    buildroot (_fixperms), así que un chmod en %install no llega al RPM.
    """
    top = Path(tempfile.mkdtemp())
    marca_ghost = "%ghost " if ghost else ""
    (top / "spec").write_text(textwrap.dedent(f"""\
        Name:      {nombre}
        Version:   1
        Release:   1
        Summary:   test
        License:   GPL-3.0
        BuildArch: noarch
        %description
        test
        %install
        mkdir -p %{{buildroot}}$(dirname {RUTA})
        printf '%s' '{contenido}' > %{{buildroot}}{RUTA}
        %files
        {marca_ghost}%attr({modo},root,root) {RUTA}
        """))
    subprocess.run(
        ["rpmbuild", "--define", f"_topdir {top}", "--define", "_build_id_links none",
         "-bb", str(top / "spec")],
        check=True, capture_output=True,
    )
    for rpm in (top / "RPMS").rglob("*.rpm"):
        shutil.copy(rpm, destino)
    shutil.rmtree(top, ignore_errors=True)


@unittest.skipIf(shutil.which("rpmbuild") is None, "hace falta rpmbuild")
class FileConflictTests(unittest.TestCase):
    def setUp(self):
        self.dir = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.dir, True)

    def test_mismo_fichero_con_distinto_contenido_es_conflicto(self):
        # El fallo real: bookos-branding y bookos-settings con QML divergentes.
        construye(self.dir, "paquete-uno", "contenido A")
        construye(self.dir, "paquete-dos", "contenido B")
        choques = checker.busca_choques(sorted(self.dir.glob("*.rpm")))
        self.assertEqual(set(choques), {RUTA})
        self.assertEqual(set(choques[RUTA]), {"paquete-uno", "paquete-dos"})

    def test_mismo_fichero_identico_no_es_conflicto(self):
        # rpm lo permite, y es lo que enmascaró el fallo hasta que divergieron.
        construye(self.dir, "paquete-uno", "mismos bytes")
        construye(self.dir, "paquete-dos", "mismos bytes")
        self.assertEqual(checker.busca_choques(sorted(self.dir.glob("*.rpm"))), {})

    def test_mismo_contenido_con_permisos_distintos_es_conflicto(self):
        # Comprobado con `rpm -i --test`: rpm también lo rechaza, no solo el digest.
        construye(self.dir, "paquete-uno", "mismos bytes", modo="0644")
        construye(self.dir, "paquete-dos", "mismos bytes", modo="0755")
        self.assertIn(RUTA, checker.busca_choques(sorted(self.dir.glob("*.rpm"))))

    def test_los_ghost_no_cuentan(self):
        # Un %ghost no se instala, así que nunca puede chocar con nadie.
        construye(self.dir, "paquete-uno", "contenido A")
        construye(self.dir, "paquete-dos", "contenido B", ghost=True)
        self.assertEqual(checker.busca_choques(sorted(self.dir.glob("*.rpm"))), {})

    def test_los_directorios_pueden_tener_varios_duenos(self):
        construye(self.dir, "paquete-uno", "contenido A")
        construye(self.dir, "paquete-dos", "contenido B")
        choques = checker.busca_choques(sorted(self.dir.glob("*.rpm")))
        # El fichero sí choca, pero el directorio que lo contiene no: rpm permite
        # que varios paquetes co-posean un directorio.
        self.assertIn(RUTA, choques)
        self.assertNotIn(str(Path(RUTA).parent), choques)


if __name__ == "__main__":
    unittest.main()
