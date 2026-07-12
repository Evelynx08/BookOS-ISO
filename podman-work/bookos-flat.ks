# BookOS Dev ISO — bleeding edge, unstable
# BookOS — kickstart base (shared by stable/beta/dev)
# Builds live ISO that includes BookOS branding + bookos-meta + KDE Plasma.

# Primary locale = Spanish (BookOS target market): the live session AND the
# Anaconda installer boot in Spanish. --addsupport keeps extra locales
# installed so the installer language list offers them too.
lang es_ES.UTF-8 --addsupport=en_US.UTF-8
keyboard --vckeymap=es --xlayouts='es'
# Default sensato para es_ES; la página de fecha/hora del WebUI queda VISIBLE
# (es la única que BookOS Welcome no cubre) por si el usuario está en otra zona.
timezone Europe/Madrid
selinux --enforcing
# SSH is intentionally NOT enabled by default: a consumer laptop OS shouldn't
# ship a listening sshd / open firewall port on every install. Users who want
# remote access enable it themselves (systemctl enable --now sshd + open port).
firewall --enabled --service=mdns
network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=NetworkManager,bluetooth

bootloader --location=mbr --append="rhgb quiet rd.live.image ibt=off intel_pstate=passive nowatchdog nvme_core.default_ps_max_latency_us=5500 pcie_aspm=force pcie_aspm.policy=powersupersave workqueue.power_efficient=1 xe.enable_psr=1"
# Live image rootfs sizing for livemedia-creator. This is the SIZE OF THE LIVE
# IMAGE being built, not the installed system — Anaconda chooses the target
# disk layout at install time (Fedora's automatic install defaults to btrfs,
# which is what we want for snapshots).
part / --size=20000 --fstype="ext4"

# Root account locked (no direct root login). Anaconda still requires the Root
# password spoke to be "completed" in non-interactive mode, so this line must
# be present even though we disable the account.
rootpw --lock

# Live user is created at the END of %post (not here) so it is added AFTER the
# RPMs have populated /etc/skel — useradd -m then copies the FULL BookOS config
# (panel layout, widgets, theme, lockscreen toggle) into its home. Creating it
# here (the old `user` directive) ran before skel existed, which is why every
# skel write needed a manual /home/liveuser copy and why widgets/theme kept
# going missing. See the "Live user" block at the bottom of %post.

reboot --eject

# ── Repos ─────────────────────────────────────────────────────────────────
# Base install source — must be declared with `url` (not `repo`), or lorax
# errors: "repo can only be used within the url install method".
url --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
repo --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-$releasever&arch=$basearch
# BookOS apps (calc, clock, notepad, settings, store…) live in the store-files
# repo. They must be available AT INSTALL TIME — bookos-meta Requires them — so
# declare the repo here, not only in %post (which only configures the installed
# system). Without this anaconda errors "No match for argument: bookos-calc".
repo --name=bookos-apps --baseurl=https://bookos.es/store-files/
# BookOS OS repo is defined by the per-channel kickstart (stable/beta/dev.ks),
# not here, to avoid a duplicate "bookos" repo definition.

# ── Packages ──────────────────────────────────────────────────────────────
# --ignoremissing: skip a package that isn't found instead of aborting the
# whole build (safety net for optional/renamed packages across Fedora versions).
%packages --ignoremissing
@^kde-desktop-environment
@standard
@base-x
@hardware-support
@multimedia
kernel-modules-extra
# ── Languages ───────────────────────────────────────────────────────────────
# Ship English + Spanish so the installer and the live session can switch
# language (and KDE/apps show translated UI). langpacks-XX pull the matching
# glibc locale, hunspell dict, fonts and app translations. Add more lines
# (langpacks-fr, -pt, -de…) to bundle further languages.
langpacks-en
langpacks-es
glibc-langpack-en
glibc-langpack-es
# SELinux: `selinux --enforcing` makes anaconda run load_policy during install.
# Without these it dies: "No such file or directory: '/usr/sbin/load_policy'".
policycoreutils
selinux-policy-targeted
# Required by livemedia-creator to produce a bootable live ISO
dracut-live
dracut-config-generic
# ISO bootloader bits (lorax builds the El Torito BIOS + UEFI boot at compose
# time; these provide the grub2 modules it needs, mirroring Fedora's own live
# kickstarts). Without grub2-pc-modules: "cannot open .../i386-pc/moddep.lst".
grub2-pc-modules
grub2-efi-x64
grub2-efi-x64-cdboot
shim-x64
syslinux
# Anaconda ejecuta efibootmgr chrooteado en el destino al instalar el gestor
# de arranque; anaconda-install-env-deps 44.30 (F44) ya NO lo arrastra como
# dependencia dura → sin esto la instalación muere con
# "[Errno 2] No existe el fichero o el directorio: 'efibootmgr'".
efibootmgr

# Snapshot / rollback stack (btrfs) — lets BookOS Settings snapshot before
# every release upgrade and roll back from GRUB if something breaks.
# (No dnf snapper plugin: it isn't packaged on Fedora/dnf5; BookOS Settings
#  takes the snapshot itself in apply_bookos_release.)
snapper
inotify-tools

# Plymouth: el tema BookOS es ModuleName=script — sin este plugin el splash
# cae al spinner/texto de Fedora (bug #7).
plymouth-plugin-script

# BookOS umbrella package (Requires: pulls everything else)
bookos-meta
# Asistente de primer arranque (BookOS Welcome, C++/Qt6, estilo macOS Setup):
# idioma, teclado, Wi-Fi, cuenta (wheel), huella y tema. La página de cuentas
# del WebUI va oculta vía perfil. Verificado en el %post --erroronfail final.
# Sustituye al esqueleto bookos-oobe (rpm/bookos-oobe, ya no se incluye).
bookos-welcome
# OJO: --ignoremissing aplica a TODO el bloque, así que listar un paquete aquí
# NO hace que su ausencia aborte la build — se dropea en silencio igual. La
# verificación real está en el %post --erroronfail del final, que comprueba con
# rpm -q que los bookos-* críticos entraron. Ships the plasmoids into the live
# rootfs (/usr/share/plasma/plasmoids), which install-to-disk copies to disk.
bookos-widgets
bookos-settings
bookos-store
bookos-calc
bookos-clock
bookos-notepad
bookos-new
bookos-shell
bookos-branding
bookos-look-and-feel
bookos-desktop-defaults
# Temas e iconos: sin estos la LNF BookOS referencia temas inexistentes y el
# escritorio cae a Breeze (parte del bug "0.6 sale sin el look BookOS").
bookos-icons
bookos-plasma-theme
bookos-gtk-theme
# ServiceMenus (terminal / color de carpeta) + runners KRunner (acciones, clima).
bookos-desktop-integration
# Optional apps — substituted by build-iso.sh when "all apps" is requested.

# ── Samsung Galaxy Book hardware enablement ─────────────────────────────────
# Fingerprint: libfprint fork with the FMV ETU906AXX-E SPI sensor (Book5 Pro).
# It Provides/Obsoletes libfprint, so dnf installs it in place of the stock one.
libfprint-bookos
# Speakers: MAX98390 HDA DKMS module (Book4/5 Pro/Ultra). Hardware-guarded, so
# it no-ops on other machines. dkms + kernel-devel + akmods let it build and
# sign at compose time / on kernel updates; alsa-sof-firmware carries the DSM.
bookos-galaxybook-audio
dkms
kernel-devel
akmods
alsa-sof-firmware

# KDE essentials
sddm
plasma-workspace
dolphin
konsole
firefox

# ── BookOS debloat ──────────────────────────────────────────────────────────
# Apps/utilidades KDE sustituidas por las de BookOS o innecesarias para el
# modelo macOS. Solo LEAF packages (apps de hoja, nada de lo que dependa el
# stack) para no romper la resolución. dolphin/konsole se CONSERVAN (arriba).
# Ampliar tras validar que la ISO compone bien.
-plasma-discover              # -> bookos-store
-plasma-discover-notifier
-plasma-welcome                # asistente de bienvenida KDE
-plasma-browser-integration    # integración navegador (bloat)
-plasma-workspace-wallpapers   # solo wallpapers BookOS en el selector
# OJO: NO excluir plasma-lookandfeel-fedora / f44-backgrounds-* /
# desktop-backgrounds-compat: sddm y plasma-workspace los REQUIEREN y dnf
# aborta toda la instalación (build del 4-jul falló por esto). Sus wallpapers
# y global themes sobrantes se borran igualmente en el %post de abajo.
-kinfocenter                   # info del sistema
-khelpcenter                   # ayuda KDE
-plasma-firewall               # KCM -> cubierto por bookos-settings
-plasma-thunderbolt            # KCM -> cubierto por bookos-settings

# SSH server present but NOT auto-started (see `services` line above). Shipping
# the package means a user can enable remote access with one command, no install
# or network needed: `sudo systemctl enable --now sshd` (+ open the firewall:
# `sudo firewall-cmd --add-service=ssh --permanent && sudo firewall-cmd --reload`).
openssh-server

# Anaconda installer for live media install-to-disk
anaconda
anaconda-live
anaconda-install-env-deps

# NOTE: we DON'T exclude fedora-logos/generic-logos here. They provide
# `system-logos`, required by breeze-icon-theme and the whole KDE stack; while
# the bookos repo isn't yet pulled into the build, excluding them breaks the
# entire dependency tree. BookOS identity is applied in %post (os-release etc.).
# Once bookos-branding installs from the repo (it Provides system-logos and
# Conflicts fedora-logos), re-add the exclusions.
%end

# ── Post-install: branding overrides ──────────────────────────────────────
%post
# /etc/bookos-release identifies channel + version (read by Settings app)
cat > /etc/bookos-release <<'EOF'
NAME=BookOS
VERSION=0.6.1
CHANNEL=dev
INSTALLED=BookOS 0.6.1
EOF

# /etc/os-release rewrite (overrides Fedora identity)
cat > /etc/os-release <<'EOF'
NAME="BookOS"
PRETTY_NAME="BookOS 0.6.1 (dev)"
ID=bookos
ID_LIKE=fedora
VERSION="0.6.1"
VERSION_ID=0.6.1
ANSI_COLOR="0;38;2;10;132;255"
HOME_URL="https://bookos.es/"
DOCUMENTATION_URL="https://bookos.es/docs"
SUPPORT_URL="https://bookos.es/support"
BUG_REPORT_URL="https://bookos.es/bugs"
EOF
ln -sf /etc/os-release /usr/lib/os-release

# Hostname default (fallback; the model-detect service below overrides it on
# real Galaxy Book hardware so the installer shows e.g. "book5-pro").
echo "bookos" > /etc/hostname

# NOTE: the live user gets the FULL BookOS appearance automatically because it
# is created at the end of %post (useradd -m copies the finished /etc/skel). No
# manual /home/liveuser copies needed anymore.

# ── Model-based hostname ────────────────────────────────────────────────
# Derives the hostname from the Samsung DMI model code (book5-pro, book4-edge,
# …) so the installer's default — and thus the installed system — is named
# after the laptop. Runs once (stamp file); the live sets it before Anaconda,
# so the install inherits it. User renames in the installer still win.
cat > /usr/libexec/bookos-set-hostname <<'SH'
#!/bin/sh
STAMP=/var/lib/bookos/hostname-set
[ -f "$STAMP" ] && exit 0
code=$(cat /sys/class/dmi/id/product_name /sys/class/dmi/id/board_name 2>/dev/null | tr 'a-z' 'A-Z')
case "$code" in
  *QQHA*) h=book5-pro-360 ;;
  *XHA*)  h=book5-pro ;;
  *QHA*)  h=book5-360 ;;
  *XHD*)  h=book5 ;;
  *XGL*)  h=book4-ultra ;;
  *QKG*)  h=book4-edge ;;
  *QGK*)  case "$code" in *960*|*964*) h=book4-pro-360 ;; *) h=book4-360 ;; esac ;;
  *XGK*)  case "$code" in *940*|*944*|*960*) h=book4-pro ;; *) h=book4 ;; esac ;;
  *XGJ*)  h=book4 ;;
  *)      h="" ;;
esac
mkdir -p /var/lib/bookos
if [ -n "$h" ]; then
  # El unit corre con DefaultDependencies=no, antes de D-Bus → hostnamectl
  # normalmente falla ahí. El fallback escribe /etc/hostname Y aplica el
  # hostname al kernel para este boot (si no, el live seguiría como "bookos").
  hostnamectl set-hostname "$h" 2>/dev/null || {
    echo "$h" > /etc/hostname
    hostname "$h" 2>/dev/null || true
  }
fi
touch "$STAMP"
SH
chmod +x /usr/libexec/bookos-set-hostname

cat > /etc/systemd/system/bookos-hostname.service <<'UNIT'
[Unit]
Description=Set BookOS hostname from laptop model
DefaultDependencies=no
After=local-fs.target
Before=anaconda.service sddm.service display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/libexec/bookos-set-hostname
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
systemctl enable bookos-hostname.service 2>/dev/null || true

# ── Persistent BookOS repos on the installed system ─────────────────────────
# (The kickstart `repo` lines above are build-time only; these .repo files are
#  what stays on disk so the system can update after install.)
# dnf expands $releasever / $basearch at runtime, so the same file works on any
# Fedora base. The active channel is enabled; the others are present but off so
# BookOS Settings (set_update_channel) can switch between them.
mkdir -p /etc/yum.repos.d
cat > /etc/yum.repos.d/bookos-os.repo <<EOF
# BookOS system channels — bookos-meta + branding/widgets/themes (OS updates)
[bookos-stable]
name=BookOS (stable)
baseurl=https://bookos.es/repo/fedora/\$releasever/\$basearch/stable/
enabled=$([ "dev" = "stable" ] && echo 1 || echo 0)
gpgcheck=1
gpgkey=https://bookos.es/api/pubkey.php?type=gpg
metadata_expire=6h
skip_if_unavailable=True

[bookos-beta]
name=BookOS (beta)
baseurl=https://bookos.es/repo/fedora/\$releasever/\$basearch/beta/
enabled=$([ "dev" = "beta" ] && echo 1 || echo 0)
gpgcheck=1
gpgkey=https://bookos.es/api/pubkey.php?type=gpg
metadata_expire=6h
skip_if_unavailable=True

[bookos-dev]
name=BookOS (dev)
baseurl=https://bookos.es/repo/fedora/\$releasever/\$basearch/dev/
enabled=$([ "dev" = "dev" ] && echo 1 || echo 0)
gpgcheck=1
gpgkey=https://bookos.es/api/pubkey.php?type=gpg
metadata_expire=6h
skip_if_unavailable=True
EOF

# Store apps repo (bookos-store / dnf install bookos-*)
cat > /etc/yum.repos.d/bookos.repo <<EOF
[bookos]
name=BookOS Apps
baseurl=https://bookos.es/store-files/
enabled=1
gpgcheck=1
gpgkey=https://bookos.es/api/pubkey.php?type=gpg
metadata_expire=300
skip_if_unavailable=True
EOF
# gpgcheck=1: packages MUST be GPG-signed. REQUIREMENT before publishing a
# release: sign every RPM (`rpmsign --addsign *.rpm` with the BookOS key) and
# import the public key on build/publish. The gpgkey= above points dnf at the
# public key endpoint so first install/upgrade imports it automatically.
# Unsigned packages now FAIL to install on devices (this is the point) — keep
# the publish pipeline signing or updates break.

# SDDM default theme (assuming bookos-branding installs theme files)
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/bookos-theme.conf <<'EOF'
[Theme]
Current=bookos
EOF

# Live session auto-login: boot STRAIGHT to the BookOS desktop, no SDDM prompt.
# (The liveuser password is cleared in the "Live user" block at the end of %post;
#  here we only write the SDDM autologin config.) Pick Wayland plasma if present,
# else X11. zz- prefix so it wins over any other drop-in.
LIVE_SESSION=plasma
[ -f /usr/share/wayland-sessions/plasma.desktop ] || LIVE_SESSION=plasmax11
cat > /etc/sddm.conf.d/zz-live-autologin.conf <<EOF
[Autologin]
User=liveuser
Session=$LIVE_SESSION
Relogin=true
EOF

# ── BookOS lockscreen ───────────────────────────────────────────────────
# Replicates bookos-settings' install_lockscreen_theme: overwrite the Plasma
# shell lockscreen with the staged BookOS QML so the live session AND fresh
# installs show the BookOS lockscreen out of the box (instead of plain Breeze),
# without the user having to flip the toggle in BookOS Settings.
LS_SRC=/usr/share/bookos-settings/lockscreen
LS_DEST=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen
if [ -d "$LS_SRC" ] && [ -d "$LS_DEST" ]; then
    mkdir -p "$LS_DEST/.backup"
    for f in MainBlock.qml LockScreenUi.qml BookBar.qml MediaControls.qml; do
        [ -f "$LS_DEST/$f" ] && cp -f "$LS_DEST/$f" "$LS_DEST/.backup/$f" 2>/dev/null || true
        [ -f "$LS_SRC/$f" ]  && cp -f "$LS_SRC/$f"  "$LS_DEST/$f"        2>/dev/null || true
    done
    touch "$LS_DEST/.bookos-installed"
fi

# ── Installer launcher on the live desktop ──────────────────────────────
# Without livesys-scripts nothing places the "Install to Hard Drive" icon on
# the live user's desktop. Copy anaconda's launcher there (and to /etc/skel so
# it survives the liveuser home copy), marked trusted so Plasma runs it.
for LAUNCH in /usr/share/applications/liveinst.desktop /usr/share/applications/anaconda.desktop; do
    [ -f "$LAUNCH" ] || continue
    # The stock launcher ships Fedora's icon — rebrand it (system-wide, so the
    # app menu / launchpad show BookOS too, and the Desktop copy inherits it).
    sed -i 's|^Icon=.*|Icon=/usr/share/pixmaps/bookos-install.svg|' "$LAUNCH" 2>/dev/null || true
    DESK=/etc/skel/Desktop
    mkdir -p "$DESK"
    cp -f "$LAUNCH" "$DESK/" 2>/dev/null || true
    chmod +x "$DESK/$(basename "$LAUNCH")" 2>/dev/null || true
    # KDE: mark executable desktop files as trusted to skip the warning
    kwriteconfig6 --file "$DESK/$(basename "$LAUNCH")" --group "Desktop Entry" --key "X-KDE-AuthorizeExecution" "true" 2>/dev/null || true
done

# ── Keyboard backlight toggle (Fn+F9) ──────────────────────────────────────
# Samsung Galaxy Book exposes the keyboard backlight as an LED class device.
# Writing its `brightness` needs root, so Fn+F9 / the Control Station button do
# nothing for a normal user. Ship a cycler script, make the sysfs node writable
# by the `video` group via udev, and bind it to Fn+F9 for new users.
cat > /usr/libexec/bookos-kbd-backlight <<'SH'
#!/bin/sh
# Cycle the keyboard backlight one step (wraps to 0 at max).
LED=$(ls -d /sys/class/leds/*kbd_backlight 2>/dev/null | head -1)
[ -n "$LED" ] || exit 0
MAX=$(cat "$LED/max_brightness")
CUR=$(cat "$LED/brightness")
if [ "$CUR" -ge "$MAX" ]; then NEXT=0; else NEXT=$((CUR + 1)); fi
echo "$NEXT" > "$LED/brightness"
SH
chmod +x /usr/libexec/bookos-kbd-backlight
# Compat: the Control Station widget calls `bash ~/.toggle-luz.sh`.
cat > /etc/skel/.toggle-luz.sh <<'SH'
#!/bin/sh
exec /usr/libexec/bookos-kbd-backlight
SH
chmod +x /etc/skel/.toggle-luz.sh

# udev: make the kbd backlight node writable without root. `uaccess` grants the
# user of the active graphical session a write ACL (covers the installer-created
# user regardless of group); the chgrp/chmod to `video` is a fallback for the
# pre-created liveuser. Re-applied on hotplug.
cat > /etc/udev/rules.d/90-bookos-kbd-backlight.rules <<'EOF'
ACTION=="add|change", SUBSYSTEM=="leds", KERNEL=="*kbd_backlight", \
  TAG+="uaccess", \
  RUN+="/bin/chgrp video /sys/class/leds/%k/brightness", \
  RUN+="/bin/chmod g+w /sys/class/leds/%k/brightness"
EOF

# Bind Fn+F9 to the cycler for new users. Fn+F9 emits KEY_KBDILLUMTOGGLE,
# which reaches Qt as "Keyboard Light On/Off". Two things are needed:
#  1) unbind powerdevil's own "Toggle Keyboard Backlight" (a plain on/off) —
#     it claims the key first and kglobalaccel refuses duplicate bindings,
#     which is why the cycler never fired;
#  2) register the launcher under [services] (the group kglobalaccel actually
#     reads for .desktop command shortcuts; _launch there is a single field).
mkdir -p /etc/skel/.config
cat >> /etc/skel/.config/kglobalshortcutsrc <<'EOF'

[org_kde_powerdevil]
Toggle Keyboard Backlight=none,Keyboard Light On/Off,Toggle Keyboard Backlight

[services][bookos-kbd-backlight.desktop]
_launch=Keyboard Light On/Off

[services][bookos-terminal.desktop]
_launch=Ctrl+Alt+T

[services][org.kde.konsole.desktop]
_launch=none

[services][bookos-settings.desktop]
_launch=Meta+I

[services][systemsettings.desktop]
_launch=none

# Alt+Tab = switcher BookOS (iconos) · Meta+Tab = previsualizaciones
# (por defecto ambos atajos disparan el mismo "Walk Through Windows")
[kwin]
Walk Through Windows=Alt+Tab,Alt+Tab\tMeta+Tab,Recorrer las ventanas
Walk Through Windows (Reverse)=Alt+Shift+Tab,Alt+Shift+Tab\tMeta+Shift+Tab,Recorrer las ventanas (hacia atrás)
Walk Through Windows Alternative=Meta+Tab,none,Recorrer las ventanas de modo alternativo
Walk Through Windows Alternative (Reverse)=Meta+Shift+Tab,none,Recorrer las ventanas de modo alternativo (hacia atrás)
EOF

# Terminal por defecto (Dolphin "Abrir terminal", kioclient exec…):
# el wrapper prefiere bookos-shell y cae a konsole si no está.
mkdir -p /etc/skel/.config
if ! grep -q "TerminalApplication" /etc/skel/.config/kdeglobals 2>/dev/null; then
    printf '\n[General]\nTerminalApplication=bookos-open-terminal.sh\nTerminalService=bookos-terminal.desktop\n' >> /etc/skel/.config/kdeglobals
fi
mkdir -p /etc/skel/.local/share/applications
cat > /etc/skel/.local/share/applications/bookos-kbd-backlight.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Keyboard Backlight
Exec=/usr/libexec/bookos-kbd-backlight
NoDisplay=true
X-KDE-GlobalAccel-CommandShortcut=true
EOF

# Plymouth (boot splash) — branding RPM should install /usr/share/plymouth/themes/bookos
plymouth-set-default-theme bookos -R || true

# GRUB dice "BookOS", no "Fedora", en el menú y los entries generados.
if [ -f /etc/default/grub ]; then
    grep -q '^GRUB_DISTRIBUTOR=' /etc/default/grub \
        && sed -i 's|^GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR="BookOS"|' /etc/default/grub \
        || echo 'GRUB_DISTRIBUTOR="BookOS"' >> /etc/default/grub
fi

# ── FIX instalador: /var + arranque del sistema instalado ───────────────────
# Dos bugs de instalación, corregidos con la mecánica REAL de Anaconda
# (verificada contra pyanaconda: grub2.py::write_defaults abre /etc/default/grub
# del destino con "w+" — lo REESCRIBE —, y anaconda.py::appendPostScripts corre
# incondicionalmente los fragmentos de /usr/share/anaconda/post-scripts/*ks):
#
# 1) /var: el perfil bookos.conf trae `must_not_be_on_root = /var` junto a
#    default_scheme=BTRFS (que jamás crea /var aparte) → el comprobador de
#    almacenamiento aborta SIEMPRE ("Su /var debe estar en una partición
#    separada"). Anaconda lee el perfil DEL ENTORNO LIVE al arrancar liveinst,
#    así que parchearlo aquí arregla la instalación aunque el RPM
#    bookos-branding venga sin corregir.
# 2) "No aparece GRUB / no sale BookOS": editar /etc/default/grub del live NO
#    sirve (Anaconda lo reescribe de cero en el destino). Lo que sí gobierna el
#    destino es (a) el perfil: menu_auto_hide=True hace que Anaconda marque
#    grubenv con menu_auto_hide=1 boot_success=1 → menú oculto para siempre; y
#    (b) la entrada NVRAM UEFI, que el firmware Samsung a veces ignora o pierde
#    → el portátil ni lista BookOS. Se corrige vía perfil + post-script.
python3 - <<'PYEOF'
import configparser, os
for p in ("/etc/anaconda/profile.d/bookos.conf",
          "/usr/share/anaconda/profile.d/bookos.conf",
          "/usr/share/anaconda/product.d/bookos.conf"):
    if not os.path.isfile(p):
        continue
    c = configparser.RawConfigParser(strict=False)
    c.optionxform = str
    c.read(p, encoding="utf-8")
    if c.has_section("Storage Constraints"):
        c.set("Storage Constraints", "must_not_be_on_root", "")  # (1) /var libre
    if not c.has_section("Bootloader"):
        c.add_section("Bootloader")
    c.set("Bootloader", "menu_auto_hide", "False")   # (2a) menú GRUB visible
    c.set("Bootloader", "efi_dir", "fedora")         # (2b) shim/grub reales viven en EFI/fedora
    # (3) Ocultas TODAS las páginas que BookOS Welcome ya pregunta en el primer
    # arranque: idioma (ese screen incluye el teclado), cuentas y red (Wi-Fi).
    # Queda visible solo fecha/hora (Welcome no tiene página de zona horaria).
    # Mismo mecanismo y misma lista (menos date-time) que Fedora Workstation.
    if not c.has_section("User Interface"):
        c.add_section("User Interface")
    c.set("User Interface", "hidden_webui_pages",
          "anaconda-screen-language anaconda-screen-accounts anaconda-screen-network")
    with open(p, "w", encoding="utf-8") as f:
        c.write(f)
    print("perfil anaconda parcheado: " + p)
PYEOF
# Cinturón extra por si python fallara (cubre el caso una-línea del perfil):
for _p in /etc/anaconda/profile.d/bookos.conf \
          /usr/share/anaconda/profile.d/bookos.conf \
          /usr/share/anaconda/product.d/bookos.conf; do
    [ -f "$_p" ] && sed -i 's/^\([[:space:]]*must_not_be_on_root[[:space:]]*=\).*/\1/' "$_p" || true
done
grep -rn "must_not_be_on_root\|menu_auto_hide\|efi_dir" /etc/anaconda /usr/share/anaconda/profile.d /usr/share/anaconda/product.d 2>/dev/null || true

# Fragmento post-install que Anaconda ejecuta chrooteado EN EL SISTEMA
# INSTALADO al final de cada instalación (también las live). Aquí sí persisten
# los cambios: corre DESPUÉS de que Anaconda escriba /etc/default/grub, el
# grub.cfg y la entrada NVRAM. Se genera con printf porque una línea que
# empiece por %post/%end dentro de ESTE %post rompería el parseo de
# pykickstart del kickstart de la ISO.
mkdir -p /usr/share/anaconda/post-scripts
{
    printf '%s\n' '%post'
    cat <<'FRAGEOF'
# BookOS: garantizar que el sistema instalado arranca y muestra GRUB.
set_kv() {
    if grep -q "^$1=" /etc/default/grub 2>/dev/null; then
        sed -i "s|^$1=.*|$1=$2|" /etc/default/grub
    else
        echo "$1=$2" >> /etc/default/grub
    fi
}
if [ -f /etc/default/grub ]; then
    set_kv GRUB_TIMEOUT 5
    set_kv GRUB_TIMEOUT_STYLE menu
    set_kv GRUB_DISTRIBUTOR '"BookOS"'
fi
# Sin auto-ocultado del menú (si el perfil o un resto previo lo marcó, fuera).
grub2-editenv - unset menu_auto_hide 2>/dev/null || true

# UEFI: ruta de arranque de RESPALDO \EFI\BOOT\BOOTX64.EFI en la ESP. Algunos
# firmware (Samsung incluido) ignoran o pierden la entrada NVRAM tras updates
# de Windows o reset de BIOS y el equipo "se queda sin GRUB". Con la ruta de
# respaldo el firmware siempre encuentra algo arrancable en el disco.
if [ -d /sys/firmware/efi ] && [ -d /boot/efi/EFI ]; then
    if [ -f /boot/efi/EFI/fedora/shimx64.efi ] && [ ! -f /boot/efi/EFI/BOOT/BOOTX64.EFI ]; then
        mkdir -p /boot/efi/EFI/BOOT
        cp /boot/efi/EFI/fedora/shimx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI 2>/dev/null || true
        cp /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/grubx64.efi  2>/dev/null || true
        cp /boot/efi/EFI/fedora/mmx64.efi   /boot/efi/EFI/BOOT/mmx64.efi    2>/dev/null || true
    fi
    # Y si no quedó NINGUNA entrada NVRAM nuestra, créala apuntando al shim.
    if command -v efibootmgr >/dev/null 2>&1 && ! efibootmgr 2>/dev/null | grep -qiE 'BookOS|Fedora'; then
        ESP="$(findmnt -no SOURCE /boot/efi 2>/dev/null)"
        if [ -n "$ESP" ]; then
            PARTNUM="$(cat /sys/class/block/$(basename "$ESP")/partition 2>/dev/null)"
            PARENT="/dev/$(lsblk -no PKNAME "$ESP" 2>/dev/null | head -n1)"
            [ -n "$PARTNUM" ] && [ -b "$PARENT" ] && \
                efibootmgr -c -d "$PARENT" -p "$PARTNUM" -L "BookOS" \
                    -l '\EFI\fedora\shimx64.efi' 2>/dev/null || true
        fi
    fi
fi
# Regenera la config para aplicar timeout/estilo (grub-btrfs/BLS incluidos).
grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
FRAGEOF
    printf '%s\n' '%end'
} > /usr/share/anaconda/post-scripts/zz-bookos-boot.ks

# Cinturón FINAL (verificado 2026-07-06 contra una instalación real rota): si
# el post-script de arriba no llegara a ejecutarse, Anaconda deja grubenv con
# menu_auto_hide=1 → el GRUB instalado salta el menú para siempre. Como una
# instalación live copia este rootfs tal cual al disco, esta unidad viaja al
# sistema instalado y lo corrige en su primer arranque. No corre en la sesión
# live (rd.live.image) y se desactiva sola tras aplicarse.
cat > /usr/local/sbin/bookos-grub-firstboot <<'EOF'
#!/bin/sh
# BookOS: menú GRUB visible en el sistema instalado (deshace menu_auto_hide=1).
grub2-editenv - unset menu_auto_hide 2>/dev/null || exit 1
touch /var/lib/bookos-grub-firstboot.done
EOF
chmod 755 /usr/local/sbin/bookos-grub-firstboot
cat > /etc/systemd/system/bookos-grub-firstboot.service <<'EOF'
[Unit]
Description=BookOS: asegurar menu GRUB visible en el primer arranque instalado
ConditionKernelCommandLine=!rd.live.image
ConditionPathExists=!/var/lib/bookos-grub-firstboot.done
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/bookos-grub-firstboot

[Install]
WantedBy=multi-user.target
EOF
mkdir -p /etc/systemd/system/multi-user.target.wants
systemctl enable bookos-grub-firstboot.service 2>/dev/null || \
    ln -sf /etc/systemd/system/bookos-grub-firstboot.service \
        /etc/systemd/system/multi-user.target.wants/bookos-grub-firstboot.service

# ── FIX instalador: limpiar los restos de la sesión LIVE en el sistema ──────
# liveuser se crea con useradd DENTRO de esta imagen (no en runtime como hace
# livesys-scripts en Fedora), y la instalación live copia el rootfs TAL CUAL al
# disco. Resultado en el sistema instalado: sigue existiendo liveuser sin
# contraseña, zz-live-autologin.conf hace que SDDM entre directo a liveuser
# (Relogin=true) ignorando al usuario creado en Anaconda, y el icono
# "Instalar en el disco duro" reaparece en cada escritorio nuevo vía /etc/skel.
# Un solo script hace la limpieza; se ejecuta por DOS vías (igual que el fix
# de GRUB de arriba): el post-script de Anaconda chrooteado en el destino y,
# de respaldo, una unidad firstboot que no corre en live (rd.live.image) y se
# desactiva sola. liveuser solo se borra si Anaconda creó otro usuario real;
# si no, se bloquea (passwd -l) para que nunca quede una cuenta sin contraseña.
cat > /usr/local/sbin/bookos-live-cleanup <<'EOF'
#!/bin/sh
# BookOS: retirar autologin/liveuser/lanzador del instalador tras instalar.
rm -f /etc/sddm.conf.d/zz-live-autologin.conf
rm -f /etc/skel/Desktop/liveinst.desktop /etc/skel/Desktop/anaconda.desktop
rmdir /etc/skel/Desktop 2>/dev/null || true
for d in /home/*/Desktop; do
    rm -f "$d/liveinst.desktop" "$d/anaconda.desktop" 2>/dev/null || true
done
if id liveuser >/dev/null 2>&1; then
    OTHER=$(awk -F: '$3>=1000 && $3<65534 && $1!="liveuser"{print $1; exit}' /etc/passwd)
    if [ -n "$OTHER" ]; then
        userdel -r liveuser 2>/dev/null || userdel liveuser 2>/dev/null || true
        rm -rf /home/liveuser
    else
        passwd -l liveuser 2>/dev/null || true
    fi
fi
touch /var/lib/bookos-live-cleanup.done
EOF
chmod 755 /usr/local/sbin/bookos-live-cleanup
# Vía 1: post-script de Anaconda (corre chrooteado en el sistema instalado,
# donde el script ya existe porque viaja con la copia del rootfs). Generado
# con printf por el mismo hazard %post/%end que zz-bookos-boot.ks.
{
    printf '%s\n' '%post'
    printf '%s\n' '/usr/local/sbin/bookos-live-cleanup || true'
    printf '%s\n' '%end'
} > /usr/share/anaconda/post-scripts/zz-bookos-live-cleanup.ks
# Vía 2 (respaldo): primer arranque instalado, ANTES del display manager para
# que SDDM nunca llegue a autologuear a liveuser.
cat > /etc/systemd/system/bookos-live-cleanup.service <<'EOF'
[Unit]
Description=BookOS: limpiar liveuser/autologin en el primer arranque instalado
ConditionKernelCommandLine=!rd.live.image
ConditionPathExists=!/var/lib/bookos-live-cleanup.done
After=local-fs.target
Before=sddm.service display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/bookos-live-cleanup

[Install]
WantedBy=multi-user.target
EOF
systemctl enable bookos-live-cleanup.service 2>/dev/null || \
    ln -sf /etc/systemd/system/bookos-live-cleanup.service \
        /etc/systemd/system/multi-user.target.wants/bookos-live-cleanup.service

# ── Galaxy Book speakers: pre-build the DKMS module into the image ──────────
# Build against the kernel shipped in the image (not the build host's running
# kernel) so the live session and fresh installs have working speakers without
# a first-boot compile. dkms.service still rebuilds on future kernel updates.
for KVER in $(ls /lib/modules 2>/dev/null); do
    [ -e "/lib/modules/$KVER/build" ] || continue
    dkms install -m max98390-hda -v 1.0 -k "$KVER" 2>/dev/null || true
done
systemctl enable dkms.service 2>/dev/null || true

# ── Default wallpaper ───────────────────────────────────────────────────────
# The captured layout may point at a developer path (file:///home/evelyn/...).
# Repoint any such reference in the shipped layout to a packaged wallpaper so
# the desktop isn't black on a fresh boot. Prefers blue_dark.png.
WP=/usr/share/backgrounds/bookos/Light/blue.png
[ -f "$WP" ] || WP="$(ls /usr/share/backgrounds/bookos/Light/*.png /usr/share/backgrounds/bookos/*.png 2>/dev/null | head -1)"
if [ -n "$WP" ]; then
    f=/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc
    [ -f "$f" ] && sed -i -E "s#file://[^,\"]*(fondo\.png|/home/[^,\"]*\.(png|jpg|jpeg))#file://$WP#g" "$f" 2>/dev/null || true
fi

# ── Idioma: forzar español de forma explícita ───────────────────────────────
# La directiva `lang` de kickstart no siempre llega a la sesión live (livesys
# puede pisar locale.conf) — se vio la ISO del 4-jul en inglés pese a lang es_ES.
echo 'LANG=es_ES.UTF-8' > /etc/locale.conf
mkdir -p /etc/skel/.config
cat > /etc/skel/.config/plasma-localerc <<'EOF2'
[Formats]
LANG=es_ES.UTF-8

[Translations]
LANGUAGE=es:en_US
EOF2

# ── FIX arranque: dracut 108 + systemd 259 pierde systemd-sysroot-fstab-check ─
# En systemd 259 /usr/lib/systemd/systemd-sysroot-fstab-check pasó a ser un
# SYMLINK a system-generators/systemd-fstab-generator. dracut-install (dracut
# 108, fc44) resuelve el symlink e instala SOLO el destino, nunca el symlink,
# así que el initramfs se queda sin el path que ejecuta
# initrd-parse-etc.service (ExecStart sin "-") → 203/EXEC → OnFailure=
# emergency.target → "Entering emergency mode" nada más montar /sysroot.
# Afecta al initrd del live (lorax) Y a los initramfs del sistema instalado
# (kernel updates), por eso el módulo se queda instalado en la imagen.
# Módulo dracut que recrea el symlink a mano dentro del initramfs:
mkdir -p /usr/lib/dracut/modules.d/99bookos-fstab-check
cat > /usr/lib/dracut/modules.d/99bookos-fstab-check/module-setup.sh <<'EOF'
#!/bin/bash
# Workaround dracut 108 + systemd 259: reinstala el symlink
# systemd-sysroot-fstab-check que dracut-install resuelve y omite.
check() { return 0; }
depends() { echo systemd; }
install() {
    inst "$systemdutildir"/system-generators/systemd-fstab-generator
    ln -sf system-generators/systemd-fstab-generator \
        "$initdir$systemdutildir"/systemd-sysroot-fstab-check
}
EOF
chmod 0755 /usr/lib/dracut/modules.d/99bookos-fstab-check/module-setup.sh

# ── Arranque más rápido ─────────────────────────────────────────────────────
# NetworkManager-wait-online bloquea network-online.target hasta tener red
# (~5-30s en portátil sin cable). Nada del escritorio lo necesita.
systemctl disable NetworkManager-wait-online.service 2>/dev/null || true
# El journal en disco crece sin límite razonable en un portátil.
mkdir -p /etc/systemd/journald.conf.d
printf '[Journal]\nSystemMaxUse=200M\n' > /etc/systemd/journald.conf.d/bookos.conf

# Solo wallpapers BookOS en el selector: borra los stock que queden (Next de
# plasma-workspace, restos de Fedora). El default BookOS se aplica en first-login.
for w in /usr/share/wallpapers/*; do
    case "$(basename "$w")" in BookOS-*) ;; *) rm -rf "$w";; esac
done

# Global themes: solo BookOS-Dark/BookOS-Light + los Breeze esenciales
# (org.kde.breeze.desktop es el fallback de Plasma — NO quitarlo).
for t in /usr/share/plasma/look-and-feel/*; do
    case "$(basename "$t")" in
        BookOS-*|org.kde.breeze.desktop|org.kde.breezedark.desktop) ;;
        *) rm -rf "$t";;
    esac
done

# Update icon cache after BookOS icons installed
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
kbuildsycoca6 --noincremental 2>/dev/null || true

# ── First-login applet-cache rebuild ────────────────────────────────────────
# The %post kbuildsycoca6 above runs as ROOT, so it builds /root's cache — not
# the live/installed user's. On a fresh boot plasmashell loads the shipped
# panel layout (plasma-org.kde.plasma.desktop-appletsrc) before the user's
# KPackage/sycoca index knows about the just-installed bookos-* plasmoids,
# giving "Error loading Applet: package bookos-menu does not exist". Rebuild the
# per-user cache on first login and restart plasmashell once, then self-delete.
mkdir -p /etc/skel/.config/autostart /usr/libexec /etc/bookos
# #6: default global look is a single editable file, NOT hardcoded in the script.
# Branding/look packages (or an admin) can change it to "BookOS-Dark", etc.
echo "BookOS-Light" > /etc/bookos/default-look
cat > /usr/libexec/bookos-first-login-refresh <<'SH'
#!/bin/sh
STAMP="$HOME/.config/.bookos-applet-refresh-done"
[ -f "$STAMP" ] && { rm -f "$HOME/.config/autostart/bookos-first-login-refresh.desktop"; exit 0; }
kbuildsycoca6 --noincremental 2>/dev/null || true
# Apply the BookOS global look-and-feel so Plasma cascades its colors/icons/
# style/decoration (otherwise it falls back to Breeze). Theme name read from
# /etc/bookos/default-look — no hardcoded name here.
LOOK="$(cat /etc/bookos/default-look 2>/dev/null)"; [ -n "$LOOK" ] || LOOK="BookOS-Light"
plasma-apply-lookandfeel -a "$LOOK" 2>/dev/null || true
# Wallpaper isn't part of the LnF cascade; set it explicitly, Light/Dark aware.
case "$LOOK" in *Dark*) WPDIR=Dark;; *) WPDIR=Light;; esac
WP="/usr/share/backgrounds/bookos/$WPDIR/blue.png"
[ -f "$WP" ] || WP="$(ls /usr/share/backgrounds/bookos/$WPDIR/*.png /usr/share/backgrounds/bookos/*.png 2>/dev/null | head -1)"
[ -n "$WP" ] && plasma-apply-wallpaperimage "$WP" 2>/dev/null || true
touch "$STAMP"
# Restart plasmashell so it re-reads the applet list with the rebuilt cache.
(sleep 2; kquitapp6 plasmashell 2>/dev/null; kstart plasmashell 2>/dev/null || plasmashell --replace 2>/dev/null &) >/dev/null 2>&1 &
rm -f "$HOME/.config/autostart/bookos-first-login-refresh.desktop"
SH
chmod +x /usr/libexec/bookos-first-login-refresh
cat > /etc/skel/.config/autostart/bookos-first-login-refresh.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=BookOS first-login refresh
Exec=/usr/libexec/bookos-first-login-refresh
X-KDE-autostart-phase=2
NoDisplay=true
EOF

# ── No "package bookos-menu does not exist" on the panel ─────────────────────
# Complements the autostart above: this user service rebuilds the KDE sycoca/
# KPackage index BEFORE plasmashell paints (Plasma 6 boots the session via
# systemd), so the first boot never flashes the broken-applet error. The
# autostart then applies theme/wallpaper inside the session.
mkdir -p /etc/skel/.config/systemd/user/plasma-workspace.target.wants
cat > /etc/skel/.config/systemd/user/bookos-sycoca.service <<'UNIT'
[Unit]
Description=Rebuild KDE sycoca so BookOS plasmoids are known before the panel loads
Before=plasma-plasmashell.service
PartOf=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/bin/kbuildsycoca6 --noincremental

[Install]
WantedBy=plasma-workspace.target
UNIT
ln -sf ../bookos-sycoca.service \
    /etc/skel/.config/systemd/user/plasma-workspace.target.wants/bookos-sycoca.service
# (No liveuser seeding: liveuser is created via useradd -m at the end of %post,
#  which copies this finished /etc/skel.)

# ── Theme the Anaconda WebUI installer (guaranteed: runs after every package
# is installed, unlike the RPM %post which may run before anaconda-webui). ──
THEME=/usr/share/anaconda/bookos/theme
if [ -f "$THEME/anaconda-webui-bookos.css" ]; then
  for idx in $(find /usr/share/cockpit/anaconda-webui /usr/share/anaconda -name index.html -path '*anaconda-webui*' 2>/dev/null); do
    d=$(dirname "$idx")
    cp -f "$THEME/anaconda-webui-bookos.css" "$d/bookos.css" || true
    # logo referenced by the CSS (url("bookos-logo.svg")) must sit beside it
    cp -f /usr/share/anaconda/bookos/pixmaps/bookos-logo.svg "$d/bookos-logo.svg" 2>/dev/null || true
    grep -q bookos.css "$idx" || sed -i 's#</head>#<link rel="stylesheet" href="bookos.css">\n</head>#' "$idx" || true
  done
fi
[ -f "$THEME/userChrome.css" ] && for fx in /usr/share/anaconda/firefox-theme/live/chrome /usr/share/anaconda/firefox-theme/default/chrome; do mkdir -p "$fx" && cp -f "$THEME/userChrome.css" "$fx/userChrome.css"; done 2>/dev/null || true

# Snapper: create the root config so pre/post snapshots work out of the box.
# (|| true: harmless if the subvolume layout already has it.)
snapper -c root create-config / 2>/dev/null || true
# Regenerate GRUB so grub-btrfs adds the "BookOS snapshots" submenu.
grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
systemctl enable grub-btrfsd 2>/dev/null || true

# Default to the graphical target + SDDM (the `services` line can't enable a
# display-manager that isn't installed at parse time; do it here instead).
systemctl set-default graphical.target 2>/dev/null || true
systemctl enable sddm.service 2>/dev/null || true

# ── Live user (created LAST, after /etc/skel is fully populated) ─────────────
# Doing this here — not via the kickstart `user` directive — means useradd -m
# copies the FINISHED /etc/skel (panel layout, widgets, theme, autostart, sycoca
# service, lockscreen toggle) into the live home in one shot. No per-file
# /home/liveuser copies, and nothing can be silently missed. Password cleared so
# SDDM autologin (zz-live-autologin.conf above) drops straight to the desktop.
if ! id liveuser >/dev/null 2>&1; then
    useradd -m -G wheel,audio,video -c "Live User" liveuser
fi
passwd -d liveuser 2>/dev/null || true

# Cleanup
dnf clean all
%end

# ── Verificación: los bookos-* críticos DE VERDAD entraron ──────────────────
# %packages lleva --ignoremissing (red de seguridad para paquetes opcionales),
# lo que también dropea en silencio un bookos-* sin publicar. Este bloque
# convierte esa ausencia en error de build ruidoso (--erroronfail aborta lorax).
%post --erroronfail
for p in bookos-meta bookos-branding bookos-widgets bookos-look-and-feel bookos-new bookos-shell \
         bookos-desktop-defaults bookos-desktop-integration bookos-settings \
         bookos-store bookos-welcome; do
    rpm -q "$p" >/dev/null 2>&1 || { echo "✗ paquete BookOS crítico ausente: $p (¿sin publicar en el repo?)"; exit 1; }
done
%end
repo --name=bookos --baseurl=https://bookos.es/repo/fedora/44/x86_64/dev/ --cost=10
