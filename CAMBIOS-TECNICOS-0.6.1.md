# BookOS 0.6.1 — Cambios técnicos de esta sesión

Resumen para desarrollo (no confundir con `NOVEDADES-0.6.1.md`, que es cara al
usuario). Todo lo de aquí quedó implementado, compilado y — donde aplica —
publicado en bookos.es.

## Primer arranque: usuario ya no queda en `liveuser`

**Problema**: la instalación live copia el rootfs tal cual al disco.
`liveuser` se crea con `useradd` dentro de la propia imagen (Fedora lo hace en
runtime vía `livesys-scripts`, BookOS no), así que sobrevivía a la instalación
junto con `zz-live-autologin.conf` (SDDM `Relogin=true`) — el usuario creado
en Anaconda nunca llegaba a hacer login.

**Fix** — `bookos-live-cleanup`, dos vías (mismo patrón que el fix de GRUB
visible ya existente):
- Fragmento `%post` de Anaconda (`zz-bookos-live-cleanup.ks`), corre chrooteado
  en el destino al final de cada instalación.
- Unidad firstboot de respaldo (`bookos-live-cleanup.service`,
  `ConditionKernelCommandLine=!rd.live.image`, `Before=display-manager.service`).
- Borra `liveuser` solo si existe otro usuario UID≥1000 real; si no, lo
  bloquea con `passwd -l` (nunca deja una cuenta sin contraseña).
- También va empaquetado en `bookos-desktop-integration` (no solo en el
  kickstart), para que **instalaciones ya existentes se curen con
  `dnf update`** sin reinstalar.

## Gestos de touchpad rotos (`qdbus6`)

`libinput-gestures.conf` llamaba a `qdbus6` — binario de **Arch**, inexistente
en Fedora — así que cada gesto fallaba en silencio. Reescrito con
`gdbus call --session --dest … --method …` (glib2, siempre presente),
verificado por introspección D-Bus real de `org.kde.kglobalaccel` y
`org.kde.plasmashell`.

El `%post` de `bookos-desktop-integration` además **repara los homes ya
existentes**: sobreescribe `~/.config/libinput-gestures.conf` de cada usuario
si detecta `qdbus6` dentro (o si falta autostart), y deja un fallback de
sistema en `/etc/libinput-gestures.conf`. Así los equipos ya instalados
también se arreglan con `dnf update`, no solo las instalaciones nuevas
(`/etc/skel` solo aplica a usuarios *nuevos*).

→ `bookos-desktop-integration-0.6.1-7` (publicado, repo dev).

## Asistente de primer arranque: BookOS Welcome (OOBE)

Se integró **BookOS Welcome** (`~/Descargas/BookOS/BookOS-Welcome`, C++/Qt6 +
QML, ya existente, estilo macOS Setup Assistant) como el flujo real de primer
arranque, sustituyendo un esqueleto previo (`bookos-oobe`, PyQt6 — descartado,
fuente conservada sin usar).

**Flujo**: Bienvenida → Idioma → Teclado → Wi-Fi → Privacidad → Términos →
Cuenta local (wheel) → Huella (si hay sensor) → Tema claro/oscuro → Fin.
Corre en `kwin_wayland` kiosko (`--drm --no-lockscreen --no-global-shortcuts
--exit-with-session`) **antes** de SDDM.

**Parches aplicados sobre el proyecto original**:
- La unidad no tenía `ConditionKernelCommandLine=!rd.live.image` →
  habría bloqueado el arranque de la propia sesión **live**. Añadido, más
  `After=bookos-live-cleanup.service`.
- La sesión ahora sale marcando "done" si ya existe un usuario real
  (reinstalación conservando `/home`, o llega por update a un sistema en uso).
- **Bug de idioma/teclado**: `languageChosen`/`keyboardChosen` solo se
  emitían al hacer *tap* en la lista. Aceptar la preselección con
  "Siguiente" aplicaba los defaults internos (`en_US`/`us`) — cualquiera
  que hiciera next-next acababa con teclado inglés pese a ver "Español"
  seleccionado. Detectado revisando capturas de pantalla del asistente
  (`BOOKOS_WELCOME_SHOT`, modo dry-run). Fix: el botón Siguiente confirma
  ahora la selección visible antes de avanzar.
- **Gotcha Qt** (rompió el primer intento de build de la ISO): compilado en
  contenedor con repo `updates` activo → Qt 6.11, pero el compose de la ISO
  solo resuelve el repo base (Qt 6.10) → *"nada proporciona Qt_6.11"*. Encima
  `qmlcachegen` mete un `Requires` de API **privada** pineado a la versión
  exacta de Qt del build (`Qt_6.11_PRIVATE_API`), que habría roto también
  cualquier futuro update de Qt en sistemas instalados. Fix: `NO_CACHEGEN` en
  `qt_add_qml_module` (QML interpretado en runtime, coste despreciable para
  un asistente que corre una vez) + compilar con `--disablerepo=updates`.

Build: **siempre en contenedor `registry.fedoraproject.org/fedora:44`**,
nunca en el host CachyOS/Arch (glibc/Qt distintos). → `bookos-welcome-1.0.0-3`
(publicado, repo dev).

## Anaconda: menos pantallas, sin preguntar dos veces

Con Welcome cubriendo idioma/teclado, cuenta y Wi-Fi, esas páginas del WebUI
de Anaconda quedan ocultas vía perfil (mismo mecanismo que usa Fedora
Workstation para su página de cuentas):

```
hidden_webui_pages = anaconda-screen-language anaconda-screen-accounts anaconda-screen-network
```

Aplicado en el bloque python de parcheo de perfil del kickstart **y** en
`~/Descargas/BookOS/BookOS-Anaconda/product.d/bookos.conf` (fuente del RPM
`bookos-branding`). Queda visible solo fecha/hora (Welcome no la cubre);
`timezone` del kickstart pasó de `UTC` a `Europe/Madrid` como default sensato.

## Widgets recapturados

`bookos-widgets.spec` tenía dos bugs que impedían el build:
- `%{_sourcedir}` dentro de un comentario se expandía igual (rpm no
  distingue comentarios ahí) → `%%{_sourcedir}`.
- `%changelog` con `%(date …)` dinámico rompía el chequeo de orden
  cronológico de rpmbuild según cuándo se compilara. Fechas fijadas.

`collect-widgets.sh` + `rpmbuild` → `bookos-widgets-0.6.1-7` (publicado).

## `bookos-settings` / `bookos-store`: pipeline arreglado, no bloqueaban

Se investigó como bloqueador de la build y **resultó ser un falso positivo**:
esos dos paquetes no van al repo RPM de Fedora sino a un repo aparte,
`bookos.es/store-files/` — ya tenían versión publicada (`0.6.0` / `0.6.1`)
que satisface los mínimos de `bookos-meta` (`>= 0.4.3` / `>= 0.3.0`).

De paso: `bookos-settings` nunca estaba en la lista `APPS_ALL` de
`~/Descargas/BookOS/build-apps.sh` (el directorio real es `BookOS-Settings`,
con mayúsculas — nombre distinto al que se venía usando). Añadido y
compilado como verificación; salió idéntico a lo ya publicado.

## Scripts de publicación

- **`publish-0.6.sh`** (repo RPM Fedora): le faltaba el bit ejecutable, y no
  tenía entradas para `bookos-welcome` ni `kdeconnect-bookos` (futuro) en su
  lista de globs — añadidas.
- **`iso/publish-web.sh`** (publicación de la ISO en la web): la memoria de
  sesiones anteriores lo documentaba pero **no existía en disco** — reescrito
  desde cero verificando el contrato exacto contra el código real del
  servidor (`Bookos-web/api/admin.php`, acción `publish_local`): sube el ISO
  por scp a `/tmp` del NAS (evelynx08 no está en el grupo `www-data`
  actualmente pese a lo que decía una memoria vieja — se necesita el rodeo
  `/tmp` + `sudo mv`, no scp directo a `storage/iso/`), luego `sudo mv` +
  `chown www-data` + `chmod 644`, y finalmente `POST` a
  `admin.php?action=publish_local` con `X-Api-Key`.

## Estado de publicación en bookos.es (canal `dev`)

| Paquete | Versión | Repo |
|---|---|---|
| bookos-desktop-integration | 0.6.1-7 | repo Fedora |
| bookos-widgets | 0.6.1-7 | repo Fedora |
| bookos-welcome | 1.0.0-3 | repo Fedora |
| bookos-settings | 0.6.0-1 | store-files (ya estaba) |
| bookos-store | 0.6.1-1 | store-files (ya estaba) |
| ISO `bookos-0.6.1-dev-x86_64.iso` | 0.6.1 | web de descargas — release `dev/0.6.1` viejo borrado del manifest, republicación en curso |

## Pendiente / siguiente sesión

- Confirmar que el `sudo mv` + registro (`publish_local`) de la ISO nueva se
  completó en bookos.es.
- Prueba real en VM: traspaso Plymouth → `kwin_wayland` kiosko (Welcome) →
  SDDM, enrolado de huella, Wi-Fi.
- `kdeconnect-bookos` (fork `BookOS-Link`, plugin `netshare`): sin `.spec`
  todavía, no publicado.
- `BookOS-Envoiroment` (fork completo de kwin/plasma-desktop/plasma-workspace):
  valorado como no maduro para sustituir Plasma; recomendado como patchset
  sobre el SRPM de Fedora en vez de fork completo (pendiente de decidir).
