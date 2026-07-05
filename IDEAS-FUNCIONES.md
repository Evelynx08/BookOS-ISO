# BookOS — ideas de funciones diferenciales

Lluvia de ideas de cosas que podrían venderse como "funciones BookOS" (lo que
hace que no sea "otro KDE más"). No es un plan ni un compromiso de versión,
solo material para elegir qué construir. Marco entre paréntesis qué tan lejos
está de lo que ya existe en el repo.

## Personalización

- **Iconos personalizables desde Ajustes BookOS.** Ya hay `bookos-icons`
  (BookOS-Tinted Dark/Light) y Papirus vía `bookos-desktop-integration`
  (colores de carpeta). Falta la UI: un selector en bookos-settings que
  cambie el tema de iconos + color de carpetas sin pasar por Ajustes del
  Sistema de KDE. (icons + folder color ya existen — falta la página)
  - Extensión: iconos por-carpeta arrastrando una imagen (ya hay precedente
    en el ServiceMenu "Color de carpeta").
- **Editor de accent color / esquema en vivo** con preview instantáneo,
  reutilizando los color-schemes `BookOS{Dark,Light}{Blue,Green,...}` ya
  empaquetados como puntos de partida en vez de la rueda de color genérica.
- **Perfiles de escritorio guardables**: capturar el layout de paneles +
  wallpaper + tema actual con un nombre ("Trabajo", "Casa") y poder
  restaurarlo. Técnicamente es serializar lo que ya captura `bundle-look.sh`
  + `dumpCurrentLayoutJS`, pero para el usuario final en un botón.
- **Modo "Focus" / minimalista**: un toggle que oculta miniaplicaciones no
  esenciales del panel superior (notificaciones, bluetooth, etc.) y deja solo
  reloj + control center, para producir capturas limpias o reducir distracción.

## Snapshots y recuperación (mayor impacto, base ya sentada)

- El kickstart YA instala `snapper` + `grub-btrfsd` y crea la config root en
  `%post`. Lo que falta es la experiencia "sencilla":
  - **Botón "Crear punto de restauración" en bookos-settings** antes de
    actualizar el sistema (equivalente a Time Machine / restore point de
    Windows) — un wrapper de `snapper create` con descripción automática
    ("antes de actualizar: <fecha>").
  - **Snapshot automático pre-`dnf upgrade`** (hay soporte snapper-de-facto
    vía plugins en otras distros; en Fedora habría que engancharlo a un hook
    de dnf o a un temporizador systemd que detecte transacciones).
  - **Restaurar desde el menú de arranque** ya existe vía grub-btrfs
    ("BookOS snapshots" submenu) — falta documentarlo/anunciarlo y quizás
    un atajo desde Ajustes ("Reiniciar y elegir snapshot").
  - **Purga automática** de snapshots viejos (timeline snapper con límites
    razonables para no llenar el disco en un portátil).

## Ajustes rápidos / hardware Galaxy Book

- **Perfiles de energía con automatizaciones**: ya existen los comandos
  `--fan-mode=silent/auto/turbo` vía `samsung-galaxybook-extras` en el widget
  de batería; la idea es exponerlos como "escenas" (ej. "Silencioso en
  batería, Turbo enchufado") en vez de botones sueltos.
- **Retroiluminación de teclado con curva automática** (apagarla a los N
  segundos de inactividad, ya que ahora el ciclo manual Fn+F9 funciona) —
  ahorro de batería sin fricción.
- **Centro de "salud del portátil"**: ciclos de batería, temperatura,
  estado del SSD (smartctl), todo con el lenguaje visual de BookOS en vez de
  mandar al usuario a una terminal.

## Productividad / integración ya iniciada

- Ya existe Live States (`org.bookos.LiveStates`, MPRIS + UPower) pensado
  para la dynamic island del lockscreen — se puede extender a más fuentes:
  progreso de descargas, notificaciones de calendario, "no molestar" activo.
- Los gestos de touchpad (libinput-gestures) ya cubren minimizar/Exposé/
  Overview/launcher — añadir un panel en Ajustes para remapearlos sin editar
  el `.conf` a mano (hoy es un archivo de texto).
- KRunner ya tiene clima y acciones de sistema — candidatos a sumar:
  conversión de unidades, "abrir configuración de X" (deep-link a páginas de
  Ajustes del Sistema), snippets rápidos.

## Instalación / primer arranque

- **Asistente de bienvenida post-instalación** (tipo GNOME Initial Setup pero
  BookOS): elegir tema claro/oscuro, activar gestos, fijar apps a la barra,
  en una sola pantalla la primera vez que se inicia sesión — hoy el primer
  login solo aplica el look-and-feel silenciosamente.
- **Selector de "perfil de uso" en el instalador** (Anaconda ya tiene el
  branding BookOS): "Estudio", "Programación", "Multimedia" que instalen un
  grupo de apps opcional distinto vía `bookos-meta` con variantes de
  Recommends.

## Ideas más especulativas (requieren más diseño)

- Backup cifrado a un NAS/USB con un asistente gráfico (restic/borg por
  debajo, UI BookOS encima).
- Modo "invitado" con perfil temporal que se borra al cerrar sesión.
- Widget de traducción rápida integrado en el menú de selección de texto.

---
Próximo paso sugerido: priorizar 2-3 de aquí (snapshots sencillos y perfiles
de energía parecen las de mayor payoff con menos esfuerzo, dado que la
infraestructura ya existe) y convertirlas en un plan de implementación real.
