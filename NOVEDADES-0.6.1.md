# BookOS 0.6.1 — Novedades

Todo lo nuevo que vas a notar al usar esta versión.

## 🧩 Nuevos widgets en el panel

- **Centro de control** (o `Meta+X`): ajustes rápidos en un solo panel —
  Wi-Fi, Bluetooth, modo avión, luz nocturna, brillo y volumen.
- **Widgets individuales de Wi-Fi, Bluetooth, brillo, volumen y
  notificaciones**, cada uno con su panel desplegable al estilo BookOS.
- **Notificaciones con No molestar**: campana con contador de no leídas,
  historial y silencio por 1h / 4h / 8h / hasta que lo apagues.
- **Batería mejorada**: porcentaje, modos de rendimiento del ventilador
  (silencioso / auto / turbo en Galaxy Book) y estilo configurable.

## 🔔 Notificaciones flotantes

Los avisos de las apps ahora aparecen como banners flotantes arriba a la
derecha (antes solo se guardaban en el historial). Las apps con icono de
bandeja (Discord, Steam…) también tienen ya su sitio en el panel.

## 🚀 Launcher (Launchpad)

- Navega entre páginas con la **rueda del ratón** o con las **flechas** del
  teclado (←/→, ↑/↓, AvPág/RePág).
- Sigue igual: buscar al escribir, carpetas arrastrando una app sobre otra.

## 🎨 Apariencia

- **Dos temas globales: BookOS-Dark y BookOS-Light**, completos: pantalla de
  bloqueo con dynamic island, splash de arranque propia (distinta en claro y
  oscuro, ya sin logo deformado), OSD y decoraciones de ventana a juego.
- **12 esquemas de color**: claro y oscuro en azul, verde, naranja, rosa,
  morado y rojo.
- **4 fondos de pantalla BookOS** (blue, ember, pine, purple) en el selector,
  con variante oscura automática al cambiar de tema. Solo fondos BookOS —
  fuera los de serie de Fedora/KDE.
- **Nueva tipografía Nunito** en todo el sistema (sustituye a SN Pro).
- **Alt+Tab** con el selector BookOS (iconos) y **Meta+Tab** con
  previsualizaciones de ventana.
- Selector de temas limpio: BookOS + Breeze, nada más.

## 👆 Gestos de touchpad

- **3 dedos abajo** → minimizar todo
- **3 dedos arriba** → Exposé (ventanas de la app)
- **4 dedos arriba** → Vista general
- **Pellizco de 4 dedos** → Launcher

## ⌨️ Atajos y apps por defecto

- **Ctrl+Alt+T** → BookOS Shell (terminal)
- **Meta+I** → Ajustes BookOS
- **Meta+X** → Centro de control · **Meta+Z** → menú BookOS · **Meta** → Launcher
- **Fn+F9** → retroiluminación del teclado en ciclo 0% → 33% → 66% → 100%
  (Galaxy Book4/Book5)
- Archivos de texto se abren con **BookOS Notepad** e imágenes con
  **BookOS Viewer**; "Abrir terminal aquí" usa BookOS Shell.
- En KRunner (Alt+Espacio): escribe `clima <ciudad>` o acciones rápidas
  (wifi, bluetooth, no molestar, captura, suspender…) — ya activados.

## 🖥️ "Acerca de este PC"

El menú BookOS ahora muestra también el **número de serie** del equipo.

## 🔧 Sistema

- **Instalador en español** (y el sistema en vivo), con teclado español.
- **El instalador usa btrfs**: snapshots del sistema listos desde el primer
  día (restaurables desde el menú de arranque con grub-btrfs).
- **Arranque más rápido**: ISO en vivo con compresión zstd y arranque del
  sistema sin esperas de red innecesarias.
- **Arranque con marca BookOS**: splash Plymouth propia y GRUB dice BookOS
  (adiós "Fedora" y "BookOS 44").
- **Bluetooth recuerda tu elección**: si lo apagas, sigue apagado tras
  reiniciar.
- Paneles con su tamaño correcto: barra superior fina (32px) y dock (52px)
  flotante que esquiva ventanas.

## 📦 Para quien actualiza desde 0.6

Todo llega con `dnf upgrade` vía `bookos-meta` 0.6.1. Los temas antiguos
"BookOS Dark/Light" (con espacio) quedan sustituidos por **BookOS-Dark** y
**BookOS-Light**.
