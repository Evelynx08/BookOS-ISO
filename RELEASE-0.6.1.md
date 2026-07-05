# BookOS 0.6.1 — Notas de la versión

Versión de mantenimiento sobre 0.6: arregla el escritorio de la ISO en vivo
(widgets, tema, paneles) y añade la primera tanda de integración de escritorio
propia (gestos, serial, Live States, atajos).

## Escritorio / Widgets

- **Widgets BookOS funcionan en la ISO.** Los plasmoides se instalaban con
  permisos `0700` (herencia de `mktemp` en el spec) y KPackage no podía ni
  entrar al directorio → "package … does not exist". Ahora se fuerzan
  `0755/0644` al empaquetar. (`bookos-widgets` 0.6.1-4)
- **Nueva familia control center en el panel superior:** `bookos-bluetooth`,
  `bookos-network`, `bookos-brightness`, `bookos-volume`,
  `bookos-notifications` y `bookos-controlcenter` (ajustes rápidos, Meta+X),
  además de menú, batería y reloj. El layout empaquetado estaba capturado antes
  de crearlos y no los incluía.
- **Ids de plasmoide unificados.** El layout capturado refería los ids largos
  de desarrollo (`com.bookos.*`, `KdeControlStation`); el empaquetado los
  renombra a `bookos-*`. `sanitize-layout.sh` reescribe el mapa completo para
  que futuras capturas no regresen.
- **Bluetooth apagado se queda apagado.** Los toggles de Bluetooth (widget y
  control center) usan ahora `rfkill block` en vez de `bluetoothctl power off`:
  systemd-rfkill persiste el estado entre reinicios y `AutoEnable` de bluez ya
  no lo reenciende solo. El de Wi-Fi ya persistía vía NetworkManager.
  (`bookos-widgets` 0.6.1-5)
- **Notificaciones flotantes (banners).** El widget `bookos-notifications` solo
  lleva el historial y No Molestar; los banners en pantalla los dibuja el applet
  real de KDE (motor C++ + layer-shell, imposible de reimplementar en QML puro),
  que debe estar instanciado. Se añade una **bandeja del sistema mínima** al
  panel superior que carga solo Notificaciones (oculta tras la flecha, sin
  campana duplicada; el resto de items de bandeja en `knownItems` para que no se
  auto-activen y dupliquen los widgets BookOS). De paso, da hogar a los iconos
  de bandeja de apps (Discord, etc.), que antes no tenían dónde ir.
  (`bookos-look-and-feel` 0.6.1-3, `bookos-desktop-defaults` 0.6.1-4)

## Paneles

- **Alturas y flotado correctos en la ISO.** Plasma 6 guarda el grosor y el
  flotado de los paneles en `plasmashellrc`, que no se empaquetaba: los paneles
  salían con el grosor por defecto. Ahora se envía a `/etc/skel/.config`:
  dock inferior 52px, flotante, ajustar al contenido; barra superior 32px, no
  flotante (solo miniaplicaciones), rellenar; ambos esquivan ventanas.
  (`bookos-look-and-feel` 0.6.1-2)
- El `layout.js` de los tres global themes (BookOS Dark/Light/Light1) se
  regeneró desde la sesión de referencia con los widgets nuevos y flotado por
  panel. (`bookos-desktop-defaults` 0.6.1-3)

## Integración de escritorio (`bookos-desktop-integration`, nuevo paquete)

- **ServiceMenus** de Dolphin/escritorio: "Abrir terminal aquí" y color de
  carpeta (iconos Papirus).
- **KRunner**: acciones de sistema (wifi, bluetooth, perfil de energía, no
  molestar, bloquear, captura, suspender, cerrar sesión) y clima
  (`clima <ciudad>`).
- **Live States**: broker D-Bus `org.bookos.LiveStates` + puentes MPRIS y
  UPower + CLI `bookos-livestate`; lo consume la dynamic island de la pantalla
  de bloqueo.
- **Número de serie en "Acerca de este PC".** El kernel expone el serial DMI
  solo para root; una regla tmpfiles.d lo hace legible (0444) y el widget del
  menú lo muestra sin pedir contraseña. (0.6.1-3)
- **Gestos de touchpad** (libinput-gestures incluido + regla udev `uaccess`):
  3 dedos abajo = minimizar todo · 3 dedos arriba = Exposé ·
  4 dedos arriba = Overview · pellizco de 4 dedos = launcher. (0.6.1-4)

- **Apps BookOS por defecto**: Ctrl+Alt+T abre BookOS Shell (fallback konsole),
  Meta+I abre Ajustes BookOS (en vez de systemsettings), archivos de texto se
  abren con bookos-notepad e imágenes con bookos-viewer (`/etc/xdg/mimeapps.list`),
  y el terminal por defecto de Dolphin es el wrapper BookOS.
- **KRunner**: los plugins BookOS Acciones y Clima vienen habilitados por
  defecto (faltaba `EnabledByDefault`). (`bookos-desktop-integration` 0.6.1-5)

## Live ISO / Instalador

- **Español por defecto**: la sesión en vivo y Anaconda arrancan en
  `es_ES.UTF-8` con teclado `es` (inglés sigue instalado como idioma extra).
- **Icono del instalador**: el lanzador de Anaconda mostraba el logo de
  Fedora; ahora usa el de BookOS.
- **Fn+F9 cicla la retroiluminación del teclado** (0% → 33% → 66% → 100% → 0%)
  en los Galaxy Book4/Book5: se libera la tecla del toggle on/off de powerdevil
  y se registra el atajo al ciclador en el grupo `[services]` correcto.
- **liveuser se crea al final del %post** (tras poblar `/etc/skel`), así recibe
  toda la config BookOS de una vez; primer login aplica el global theme y
  refresca sycoca antes de cargar el panel.
- Repos de la ISO con `gpgcheck=1` (RPMs firmados); SSH deshabilitado por
  defecto; la build emite `<iso>.sha256`.

### Más arreglos del bugs.md

- **#9 Wallpapers**: los 4 fondos (blue/ember/pine/purple) ahora son paquetes
  del selector de Plasma (`/usr/share/wallpapers/BookOS-*`) con variante oscura
  automática (`images_dark`); los wallpapers stock de Plasma/Fedora se excluyen
  del ISO y se borran en %post. (`bookos-branding` 0.6.1-2)
- **#8 SN Pro fuera**: se incluye **Nunito** (OFL) como fuente del sistema y un
  alias fontconfig `SN Pro→Nunito`; todas las referencias empaquetadas
  (kdeglobals, GTK, reloj, batería) pasan a Nunito. (`bookos-branding` 0.6.1-2)
- **#4 Lanzadores rotos del dock**: se quitan `bookos-settings.desktop` y
  `firefox.desktop` anclados (no aparecían); queda el gestor de archivos.
- **#11 Meta+Tab con previsualizaciones**: Alt+Tab usa el switcher BookOS
  (iconos, ahora empaquetado en `/usr/share/kwin/tabbox`) y Meta+Tab pasa al
  modo alternativo con `thumbnail_grid`. (`bookos-desktop-defaults` 0.6.1-5)

- **#6 Splash**: el logo (3:2) se estiraba por un `sourceSize` cuadrado —
  arreglado con aspect fijo; la variante Light ahora tiene fondo claro propio
  (antes Dark y Light eran idénticas). Fuente del pie → Nunito.
- **#7 Arranque con marca BookOS**: faltaba `plymouth-plugin-script` (el tema
  BookOS es ModuleName=script → caía al spinner de Fedora) y GRUB decía
  "Fedora" (`GRUB_DISTRIBUTOR="BookOS"`).
- **#1 Arranque live más rápido**: squashfs comprimida con **zstd** en vez de
  xz (descompresión mucho más rápida desde USB; ISO algo mayor).

### Instalación en btrfs (¡crítico!)

- El perfil de anaconda de BookOS estaba en `product.d/` (formato pre-F35) y sin
  sección `[Profile Detection]` → anaconda lo ignoraba y particionaba con
  **LVM + ext4**, rompiendo snapper/grub-btrfs en el sistema instalado
  (confirmado con fotos del instalador real). Ahora se instala también en
  `profile.d/` con `[Profile] profile_id=bookos` + `[Profile Detection]
  os_id=bookos` y `default_scheme = BTRFS` (la clave `file_system_type` no
  fuerza el esquema). (`bookos-branding` 0.6.1-2)

## Paquetes de esta versión

| Paquete | Versión | Cambio principal |
|---|---|---|
| bookos-widgets | 0.6.1-5 | permisos 0755, familia control center, rfkill persistente |
| bookos-look-and-feel | 0.6.1-4 | layout nuevo + plasmashellrc (alturas de panel) + bandeja para banners |
| bookos-desktop-defaults | 0.6.1-6 | bundle re-capturado, layout.js con widgets nuevos + bandeja |
| bookos-desktop-integration | 0.6.1-5 | ServiceMenus, KRunner, Live States, serial, gestos |
| bookos-branding | 0.6.1-2 | perfil anaconda en profile.d + default_scheme BTRFS |
| bookos-meta | 0.6.1 | arrastra todo lo anterior (`Requires = %{version}`) |

Build local: `sudo bash iso/build-in-podman.sh dev 0.6.1` (usa
`../localrepo-0.6.1`). Verificación en QEMU: widgets cargan, paneles 52/32px,
serial visible, sesión en español, gestos y Fn+F9 activos.
