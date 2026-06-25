# BookOS 0.6 — Dev (preview)

> ⚠️ **VERSIÓN DE DESARROLLO — INESTABLE.**
> Esta build es del canal **dev**: pensada para probar, no para uso diario.
> **Puede tener muchos errores**, comportamientos a medio terminar, fallos al
> arrancar en algún hardware, temas que no se apliquen bien al primer inicio,
> applets que tarden en cargar y problemas en el instalador. **No la instales en
> tu equipo principal ni sobre datos importantes.** Haz copia de seguridad antes.
> Está basada en **Fedora 44** (pre-release).

---

## Qué incluye

### Escritorio
- **KDE Plasma 6** sobre Fedora 44, sesión **Wayland** (con X11 de respaldo).
- Tema global **BookOS Light** por defecto (y **BookOS Dark** disponible).
- Apariencia completa BookOS:
  - Iconos **BookOS-Tinted / BookOS-Dark / BookOS-Light**.
  - Tema Plasma **bookos-light / bookos-dark**.
  - Esquemas de color **BookOS** (azul por defecto; verde, naranja, rosa, etc.).
  - Estilo Qt **Kvantum** (bookos-light-blue / bookos-dark-blue).
  - Decoración de ventanas **Aurorae BookOS-App**.
  - Tema **GTK BookOS** (Light/Dark · Blue/Green) para apps GTK.
- **Fondos de pantalla** BookOS (claros y oscuros): blue, pine, ember, purple.
- Pantalla de **bloqueo** y **splash de carga** BookOS con el logo nuevo.
- Tema de **inicio de sesión SDDM** BookOS.
- **Plymouth** (logo de arranque) BookOS.

### Widgets / applets propios
- **Book Bar** — isla dinámica (música, rutinas, carga).
- **Launchpad** — lanzador estilo macOS.
- **Menú BookOS** y **Menú estilo Win11**.
- **Control Station** — centro de control rápido.
- **Batería** (normal y pro).

### Apps incluidas
- **BookOS Settings** (Ajustes) 0.6
- **BookOS Store** (tienda de apps)
- **Calculadora**, **Reloj**, **Notas**
- Dolphin, Konsole, Firefox

### Hardware (Samsung Galaxy Book)
- **Huella dactilar**: `libfprint-bookos` (sensor FMV ETU906AXX-E, Book5 Pro).
- **Altavoces**: módulo DKMS **MAX98390** (Book4/5 Pro/Ultra) + firmware SOF.
- **Retroiluminación del teclado**: tecla Fn+F9 / botón en Control Station.
- **Hostname automático** según el modelo del portátil (book5-pro, book4-edge…).
- Parámetros de arranque afinados para Intel Core Ultra (Lunar Lake / Arc xe).

### Sistema
- **Snapshots / rollback** con btrfs + snapper (instantánea antes de actualizar,
  reversión desde GRUB).
- **Sistema de actualización** BookOS (descarga y verifica nuevos ISOs, con
  soporte de parches delta).
- Repos BookOS preconfigurados (stable / beta / dev + tienda de apps).
- **Idiomas**: Español e Inglés (instalador y escritorio).
- **Instalador** (Anaconda WebUI) con branding BookOS.

---

## Problemas conocidos / en progreso

- El **instalador (Anaconda)** puede verse distinto/incompleto respecto al diseño
  final — el tema todavía se está ajustando.
- En el **primer arranque** la apariencia se aplica mediante un refresco al
  iniciar sesión; algún elemento (iconos, applets) puede tardar un instante.
- Posibles **errores de ACPI/firmware** en consola al arrancar (ruido de BIOS,
  normalmente inofensivo).
- El **logo de arranque (Plymouth)** puede no mostrarse en la live ISO según el
  hardware.
- Hardware **no-Samsung**: los módulos específicos no se cargan (no rompen nada,
  simplemente no aplican).
- En general: **build dev = espera fallos**. Reporta lo que encuentres.

---

## Cómo reportar errores

- Web: <https://bookos.es/>
- Indica: modelo del equipo, qué hacías, y captura/registro si puedes
  (`journalctl -b`, foto de la pantalla).

---

*BookOS 0.6 (dev) · basado en Fedora 44 · publicado 2026-06-20*
