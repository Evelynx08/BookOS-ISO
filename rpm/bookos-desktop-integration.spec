Name:           bookos-desktop-integration
Version:        0.6.1
# Release (no Version) sube con los añadidos: bookos-meta pinea `= %%{version}`.
Release:        8%{?dist}
Summary:        BookOS desktop integration — ServiceMenus (terminal, folder colors), KRunner plugins (system actions, weather), Live States
License:        GPL-3.0
URL:            https://bookos.es/
BuildArch:      noarch
# Tarball topdir bookos-desktop-integration-%%{version}/ with:
#   bin/  servicemenus/  krunner-dbusplugins/  dbus-services/  livestates/
Source0:        %{name}-%{version}.tar.gz

# Runners are Python D-Bus services implementing org.kde.krunner1.
Requires:       python3-dbus
Requires:       python3-gobject
# Terminal ServiceMenu prefers bookos-shell, falls back to konsole.
Requires:       bookos-shell
# Folder colors reuse Papirus folder-<color> icons (already pulled by bookos-icons).
Requires:       papirus-icon-theme
# Touchpad gestures daemon (bundled upstream script) reads events via
# `libinput debug-events` and fires KWin shortcuts through gdbus (glib2).
Requires:       libinput-utils
# Soft deps used by the system-actions runner at runtime.
Recommends:     NetworkManager
Recommends:     bluez
Recommends:     power-profiles-daemon
Recommends:     spectacle

%description
BookOS integration bits that live on top of Plasma without forking it:

 * ServiceMenus (right-click on a folder in Dolphin / on the desktop):
     - "Abrir terminal aquí"  -> bookos-shell or konsole in that folder
     - "Color de carpeta"     -> writes .directory Icon=folder-<color> (Papirus)
 * KRunner plugins (D-Bus, org.kde.krunner1), D-Bus-activated on demand:
     - org.bookos.Actions  -> wifi/bluetooth/power-profile/do-not-disturb/lock/
                              screenshot/suspend/logout
     - org.bookos.Weather  -> "clima/tiempo/weather <city>" via wttr.in
 * Live States (org.bookos.LiveStates): apps publish live status (music,
   battery, routine, timer) to a session D-Bus broker; the lockscreen dynamic
   island consumes it. Ships the broker (D-Bus-activated), the MPRIS and
   UPower bridges (systemd user units), the bookos-livestate CLI and the
   Python publisher lib.

Pulled by bookos-meta so it tracks the release version.

%prep
%setup -q

%install
# helper scripts + runners
install -dm755 %{buildroot}%{_bindir}
install -m755 bin/bookos-open-terminal.sh   %{buildroot}%{_bindir}/bookos-open-terminal.sh
install -m755 bin/bookos-folder-color.sh    %{buildroot}%{_bindir}/bookos-folder-color.sh
install -m755 bin/bookos-actions-runner.py  %{buildroot}%{_bindir}/bookos-actions-runner.py
install -m755 bin/bookos-weather-runner.py  %{buildroot}%{_bindir}/bookos-weather-runner.py

# Dolphin / FolderView ServiceMenus
install -dm755 %{buildroot}%{_datadir}/kio/servicemenus
install -m644 servicemenus/*.desktop        %{buildroot}%{_datadir}/kio/servicemenus/

# KRunner D-Bus plugins
install -dm755 %{buildroot}%{_datadir}/krunner/dbusplugins
install -m644 krunner-dbusplugins/*.desktop %{buildroot}%{_datadir}/krunner/dbusplugins/

# D-Bus activation for the runners
install -dm755 %{buildroot}%{_datadir}/dbus-1/services
install -m644 dbus-services/*.service       %{buildroot}%{_datadir}/dbus-1/services/

# Live States: broker + puentes en /usr/lib/bookos (los .service ya apuntan ahí)
install -dm755 %{buildroot}%{_prefix}/lib/bookos
install -m755 livestates/bookos-livestates-broker.py %{buildroot}%{_prefix}/lib/bookos/
install -m755 livestates/bookos-livestate-media.py   %{buildroot}%{_prefix}/lib/bookos/
install -m755 livestates/bookos-livestate-battery.py %{buildroot}%{_prefix}/lib/bookos/
install -m644 livestates/livestate.py                %{buildroot}%{_prefix}/lib/bookos/
install -m755 livestates/bookos-livestate            %{buildroot}%{_bindir}/bookos-livestate
# activación D-Bus del broker + units de usuario de los puentes
install -m644 livestates/org.bookos.LiveStates.service %{buildroot}%{_datadir}/dbus-1/services/
install -dm755 %{buildroot}%{_prefix}/lib/systemd/user
install -m644 livestates/bookos-livestate-media.service   %{buildroot}%{_prefix}/lib/systemd/user/
install -m644 livestates/bookos-livestate-battery.service %{buildroot}%{_prefix}/lib/systemd/user/

# Serial de la máquina legible para el widget "Acerca de este PC" (bookos-menu)
install -Dm644 tmpfiles/bookos-serial.conf %{buildroot}%{_prefix}/lib/tmpfiles.d/bookos-serial.conf

# Apps por defecto BookOS: terminal wrapper (Ctrl+Alt+T) + mimeapps del sistema
install -Dm644 applications/bookos-terminal.desktop %{buildroot}%{_datadir}/applications/bookos-terminal.desktop
install -Dm644 xdg/mimeapps.list %{buildroot}/etc/xdg/mimeapps.list

# WebKitGTK/Wayland: sin esto las apps Tauri mueren con "Error 71" (DMABUF)
install -Dm644 environment/60-bookos-webkit.conf %{buildroot}%{_prefix}/lib/environment.d/60-bookos-webkit.conf
install -dm755 %{buildroot}/etc/profile.d
printf 'export WEBKIT_DISABLE_DMABUF_RENDERER=1\n' > %{buildroot}/etc/profile.d/bookos-webkit.sh

# Gestos de touchpad: libinput-gestures (upstream, GPLv3) + config BookOS
# (3 dedos abajo=MinimizeAll, 3 arriba=Exposé, 4 arriba=Overview,
#  pellizco 4 dedos=launcher) + autostart + acceso evdev por uaccess.
install -Dm755 gestures/libinput-gestures %{buildroot}%{_bindir}/libinput-gestures
install -Dm644 gestures/libinput-gestures.conf %{buildroot}/etc/skel/.config/libinput-gestures.conf
install -Dm644 gestures/libinput-gestures.desktop %{buildroot}/etc/skel/.config/autostart/libinput-gestures.desktop
install -Dm644 gestures/70-bookos-input-uaccess.rules %{buildroot}%{_prefix}/lib/udev/rules.d/70-bookos-input-uaccess.rules
# Fallback de sistema: libinput-gestures lee ~/.config y si no, /etc.
install -Dm644 gestures/libinput-gestures.conf %{buildroot}/etc/libinput-gestures.conf

# Limpieza de restos live (liveuser/autologin) en instalaciones EXISTENTES:
# unidad firstboot que llega vía dnf update; no corre en la sesión live
# (ConditionKernelCommandLine=!rd.live.image) y se marca hecha en /var/lib.
install -Dm755 cleanup/bookos-live-cleanup %{buildroot}%{_libexecdir}/bookos-live-cleanup
install -Dm644 cleanup/bookos-live-cleanup.service %{buildroot}%{_prefix}/lib/systemd/system/bookos-live-cleanup.service

%post
# Aplica ya la regla del serial (en el arranque la aplica systemd-tmpfiles-setup).
systemd-tmpfiles --create bookos-serial.conf >/dev/null 2>&1 || :
# Habilita los puentes para todas las sesiones gráficas (equivale a un preset).
systemctl --global enable bookos-livestate-media.service bookos-livestate-battery.service >/dev/null 2>&1 || :

# ── Reparación de instalaciones EXISTENTES (llega vía dnf update) ────────────
# 1) Gestos: /etc/skel solo aplica a usuarios NUEVOS. Usuarios ya creados
#    tienen el conf roto con qdbus6 (no existe en Fedora) o ni siquiera tienen
#    conf/autostart (instalados antes de 0.6.1-4). Se repara cada home; solo se
#    sobreescribe un conf si contiene qdbus6 (respeta personalizaciones).
for h in /home/*; do
    [ -d "$h/.config" ] || continue
    conf="$h/.config/libinput-gestures.conf"
    if [ ! -f "$conf" ] || grep -q qdbus6 "$conf" 2>/dev/null; then
        install -m644 /etc/libinput-gestures.conf "$conf" 2>/dev/null || :
        chown --reference="$h/.config" "$conf" 2>/dev/null || :
    fi
    auto="$h/.config/autostart/libinput-gestures.desktop"
    if [ ! -f "$auto" ]; then
        install -Dm644 /etc/skel/.config/autostart/libinput-gestures.desktop "$auto" 2>/dev/null || :
        chown --reference="$h/.config" "$h/.config/autostart" "$auto" 2>/dev/null || :
    fi
done
# 2) Limpieza live firstboot: enable manual (los presets la dejarían apagada).
#    En el compose de la ISO es no-op hasta el siguiente arranque instalado.
mkdir -p /etc/systemd/system/multi-user.target.wants
ln -sf %{_prefix}/lib/systemd/system/bookos-live-cleanup.service \
    /etc/systemd/system/multi-user.target.wants/bookos-live-cleanup.service 2>/dev/null || :

%postun
if [ $1 -eq 0 ]; then
    systemctl --global disable bookos-livestate-media.service bookos-livestate-battery.service >/dev/null 2>&1 || :
fi

%files
%{_prefix}/lib/environment.d/60-bookos-webkit.conf
/etc/profile.d/bookos-webkit.sh
%{_bindir}/bookos-open-terminal.sh
%{_bindir}/bookos-folder-color.sh
%{_bindir}/bookos-actions-runner.py
%{_bindir}/bookos-weather-runner.py
%{_datadir}/kio/servicemenus/bookos-open-terminal.desktop
%{_datadir}/kio/servicemenus/bookos-folder-color.desktop
%{_datadir}/krunner/dbusplugins/bookos-actions-krunner.desktop
%{_datadir}/krunner/dbusplugins/bookos-weather-krunner.desktop
%{_datadir}/dbus-1/services/org.bookos.Actions.service
%{_datadir}/dbus-1/services/org.bookos.Weather.service
%{_bindir}/bookos-livestate
%dir %{_prefix}/lib/bookos
%{_prefix}/lib/bookos/bookos-livestates-broker.py
%{_prefix}/lib/bookos/bookos-livestate-media.py
%{_prefix}/lib/bookos/bookos-livestate-battery.py
%{_prefix}/lib/bookos/livestate.py
%{_datadir}/dbus-1/services/org.bookos.LiveStates.service
%{_prefix}/lib/systemd/user/bookos-livestate-media.service
%{_prefix}/lib/systemd/user/bookos-livestate-battery.service
%{_prefix}/lib/tmpfiles.d/bookos-serial.conf
%{_bindir}/libinput-gestures
/etc/skel/.config/libinput-gestures.conf
/etc/skel/.config/autostart/libinput-gestures.desktop
%{_prefix}/lib/udev/rules.d/70-bookos-input-uaccess.rules
/etc/libinput-gestures.conf
%{_libexecdir}/bookos-live-cleanup
%{_prefix}/lib/systemd/system/bookos-live-cleanup.service
%{_datadir}/applications/bookos-terminal.desktop
%config(noreplace) /etc/xdg/mimeapps.list
%changelog
* Tue Jul 07 2026 BookOS <packages@bookos.es> - 0.6.1-7
- Gestos touchpad: qdbus6 (binario Arch, inexistente en Fedora) → gdbus call
- %%post repara homes existentes (conf qdbus6 o ausente) + conf fallback en /etc
- Limpieza liveuser/autologin post-instalación como unidad firstboot (viaja vía update)
* Sun Jul 05 2026 BookOS <packages@bookos.es> - 0.6.1-6
- WEBKIT_DISABLE_DMABUF_RENDERER=1 global: las apps Tauri crasheaban en Wayland (Error 71)
* Sat Jul 04 2026 BookOS <packages@bookos.es> - 0.6.1-5
- Apps por defecto: mimeapps.list (notepad/viewer), bookos-terminal.desktop
- KRunner: runners acciones/clima habilitados por defecto (EnabledByDefault)
* Sat Jul 04 2026 BookOS <packages@bookos.es> - 0.6.1-4
- Gestos de touchpad: libinput-gestures + config BookOS + autostart + udev uaccess
* Fri Jul 03 2026 BookOS <packages@bookos.es> - 0.6.1-3
- tmpfiles.d: DMI product_serial legible (0444) para el serial en "Acerca de este PC"
* Thu Jul 02 2026 BookOS <packages@bookos.es> - 0.6.1-2
- Live States: broker org.bookos.LiveStates + puentes MPRIS/UPower + CLI + lib
* Wed Jul 01 2026 BookOS <packages@bookos.es> - 0.6.1-1
- Initial: terminal + folder-color ServiceMenus; KRunner actions + weather runners
