# BookOS mínimo — Fedora 44 / KDE

La imagen predeterminada inicia el escritorio nativo de BookOS escrito en Rust
(compositor Smithay + shell integrado). Incluye Ajustes, Tienda, Bienvenida, Terminal, Reloj,
Bloc de notas, Reproductor de música, Calculadora, Novedades y Archivos de BookOS, más Firefox, Dolphin y KDE
Partition Manager. Se conservan el escritorio Wayland, XWayland, servicios
esenciales, firmware y soporte Samsung Galaxy Book (audio/huella y compilación
DKMS). No incluye el entorno completo de aplicaciones Fedora KDE.

## Validación sin instalar el sistema

```bash
python3 -m unittest discover -s iso/tests -v
python3 iso/profile.py --check
bash -n iso/build-iso.sh iso/build-in-podman.sh iso/files/bookos-boot-finalize.sh
```

Requiere Python con el paquete Fedora `pykickstart`. El constructor usa el mismo
renderizador y valida todos los scripts del kickstart antes de ejecutar lorax.

Primero se compilan las nueve apps desde los proyectos hermanos actuales, en
Fedora 44, sin reutilizar los RPM publicados ni modificar esos proyectos:

```bash
bash iso/build-apps-in-podman.sh
```

Los nombres del menú se localizan durante el empaquetado; los identificadores
y comandos permanecen estables. El manifiesto `bookos-apps.json` registra los
RPM y sus SHA-256. El modo local exige ese manifiesto y excluye esas apps del
repositorio remoto. La copia de trabajo y los logs quedan en `.build/apps/`.

Después se reconstruyen los paquetes de integración, iconos y widgets y se resuelven todas las dependencias
en un contenedor desechable (ejecutar desde BookOS-ISO):

```bash
bash iso/check-packages-in-podman.sh
```

Fuentes visuales: los proyectos hermanos en el directorio BookOS. Los RPM
candidatos quedan en `.build/package-check/repo/`; el informe de resolución,
con versiones, repositorios y tamaños, en `.build/package-check/dependency-resolution.log`.
Esta comprobación no instala la transacción ni publica archivos. Los RPM
construidos son candidatos sin firma; no deben distribuirse así.

Los cuatro packs se instalan también bajo la ruta que consulta Ajustes mediante
enlaces a los temas del sistema. Los widgets se recogen de sus proyectos, sin
capturar el escritorio del desarrollador, y sus traducciones se compilan con
el identificador usado en la ISO. Véase la [documentación de traducciones de Plasma](https://develop.kde.org/docs/plasma/widget/translations-i18n/).

## Construir la ISO candidata

```bash
sudo bash iso/build-in-podman.sh dev 0.6.2 N
```

Por defecto usa `.build/package-check/repo` como repo local (`LOCALREPO=…`
para otro). Necesita sudo real y acceso a dispositivos loop. Resultado:
`bookos-0.6.2-dev-x86_64.iso` y su SHA-256. El trabajo temporal queda
en `.build/compose/`. Cambiar la versión o directorio de salida para cada
construcción: no se reutilizan imágenes con firmas antiguas.

El sistema se llama «BookOS» a secas en todas partes (menú del USB, etiqueta
del volumen, instalador, entrada UEFI y `PRETTY_NAME`); la versión solo va en
el nombre del fichero y en `VERSION`/Ajustes.

El modo servidor se selecciona con `NO_LOCAL_REPO=1`, pero primero deben estar
publicados los nuevos RPM: branding >= 0.6.2-1, welcome >= 1.0.0-4 e
integración >= 0.6.1-8, además de meta 0.6.1-3 y keyring 0.6.1-5. El
`%post` de verificación del kickstart aborta con versiones anteriores. No hay
que borrar estas comprobaciones para usar un repo antiguo.

Las aplicaciones adicionales siguen siendo optativas: `ALLAPPS=S` añade
visor, grabadora y BookOS New. La lista propia `APPS="..."` se admite en
`build-iso.sh`. La selección predeterminada usa `N`.

## Firmas y actualizaciones

Los RPM se verifican con GPG; minisign corresponde a la ISO. La clave GPG
pública viaja en bookos-keyring y se importa durante la composición, fuera de
la transacción RPM. El sistema instalado verifica también los RPM locales.
No se desactiva la comprobación de firmas para evitar un error.

```bash
bash iso/check-artifacts.sh rpm ruta/paquete-firmado.rpm
MINISIGN_PUBKEY=/ruta/clave-publica \\
  bash iso/check-artifacts.sh iso ruta/imagen.iso
```

El verificador distingue una firma válida de un RPM que solo tiene digests.
Usa una base RPM temporal, sin modificar el llavero del equipo. El publicador
comprueba la firma de la ISO antes de subirla. `SIGN=1` exige herramienta y
claves; `SIGN=auto` permite una candidata local sin firma si no hay clave.
Para firmar dentro del constructor directo se admiten `MINISIGN_SECRET_KEY`
y `MINISIGN_PUBKEY`; el wrapper de Podman no monta claves privadas.

## Comprobar arranque y escritorio antes de publicar

1. VirtualBox: disco virtual nuevo de 40 GiB, 4 GiB RAM, 2 CPU, VMSVGA y 3D
   desactivado. Probar el live una vez con BIOS y otra con EFI, con discos
   separados. Registrar versión de VirtualBox, checksum, mensaje y VBox.log.
2. Instalar en cada VM, retirar la ISO y arrancar desde disco. Comprobar menú
   BookOS y acceso al escritorio. En otra VM de prueba, comprobar convivencia
   con un Linux existente y cuál de sus cargadores está activo.
3. En el destino, revisar `/var/log/bookos-boot-finalize.log` y
   `/var/log/bookos-anaconda-boot.log`, ESP vfat, UUID de /boot, BLS,
   kernel e initramfs. La instalación aborta si falla un paso esencial.
4. Comprobar Wi-Fi/Bluetooth/audio y huella en Samsung real; una VM no verifica
   esos controladores. Comprobar también bloqueo, suspensión, USB, Shell desde
   Dolphin, apertura de texto e imágenes y las aplicaciones seleccionadas.
5. Instalar y actualizar un RPM BookOS firmado desde Tienda y desde archivo;
   comprobar rechazo de un RPM sin firma o alterado. Actualizar kernel y
   reiniciar, conservando el kernel anterior (`installonly_limit=2`).

El inventario final queda dentro del sistema en `/usr/share/bookos/packages.tsv`
(nombre, versión/arquitectura, bytes instalados y repositorio de origen).
No se renombra el subvolumen Btrfs de Anaconda. La finalización conserva una
ruta EFI de reserva existente y no reescribe el ESP en el primer arranque.

El rendimiento de BookOS Shell queda fuera de esta modificación. Las pruebas
de sintaxis y resolución no sustituyen una instalación y arranque reales.
