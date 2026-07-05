#!/usr/bin/env python3
"""BookOS Actions KRunner plugin — acciones rápidas de sistema (estilo Spotlight).
Implementa org.kde.krunner1 (Plasma 6) por D-Bus.
Escribe 'wifi', 'bluetooth', 'no molestar', 'rendimiento', 'bloquear', etc.
"""
import sys, os, subprocess
import dbus, dbus.service, dbus.mainloop.glib
from gi.repository import GLib

BUS_NAME = "org.bookos.Actions"
OBJ_PATH = "/bookos/Actions"
NOTIFY_RC = os.path.expanduser("~/.config/plasmanotifyrc")

def run(cmd):
    try: subprocess.Popen(cmd)
    except Exception: pass

def set_dnd(enable: bool):
    # No molestar de Plasma vía plasmanotifyrc [DoNotDisturb] Until
    until = "2099-01-01T00:00:00" if enable else "2000-01-01T00:00:00"
    run(["kwriteconfig6", "--file", "plasmanotifyrc",
         "--group", "DoNotDisturb", "--key", "Until", until])

# id, etiqueta, icono, palabras clave, función
ACTIONS = [
    ("wifi-on",   "Wi-Fi: Encender",        "network-wireless",        ["wifi","wi-fi","red"],               lambda: run(["nmcli","radio","wifi","on"])),
    ("wifi-off",  "Wi-Fi: Apagar",          "network-wireless-offline",["wifi","wi-fi","red"],               lambda: run(["nmcli","radio","wifi","off"])),
    ("bt-on",     "Bluetooth: Encender",    "network-bluetooth",       ["bluetooth","bt"],                   lambda: run(["bluetoothctl","power","on"])),
    ("bt-off",    "Bluetooth: Apagar",      "network-bluetooth-inactive",["bluetooth","bt"],                 lambda: run(["bluetoothctl","power","off"])),
    ("pp-saver",  "Energía: Ahorro",        "battery-profile-powersave",["energia","energía","ahorro","bateria","batería","power"], lambda: run(["powerprofilesctl","set","power-saver"])),
    ("pp-balanced","Energía: Equilibrado",  "battery-profile-balanced",["energia","energía","equilibrado","balance","power"], lambda: run(["powerprofilesctl","set","balanced"])),
    ("pp-perf",   "Energía: Rendimiento",   "battery-profile-performance",["energia","energía","rendimiento","performance","power"], lambda: run(["powerprofilesctl","set","performance"])),
    ("dnd-on",    "No molestar: Activar",   "notifications-disabled",  ["no molestar","silencio","dnd","notificaciones"], lambda: set_dnd(True)),
    ("dnd-off",   "No molestar: Desactivar","notifications",           ["no molestar","silencio","dnd","notificaciones"], lambda: set_dnd(False)),
    ("lock",      "Bloquear pantalla",      "system-lock-screen",      ["bloquear","lock","bloqueo"],         lambda: run(["loginctl","lock-session"])),
    ("shot",      "Captura de pantalla",    "spectacle",               ["captura","screenshot","pantalla"],  lambda: run(["spectacle","-r"])),
    ("suspend",   "Suspender",              "system-suspend",          ["suspender","dormir","sleep"],       lambda: run(["systemctl","suspend"])),
    ("logout",    "Cerrar sesión",          "system-log-out",          ["cerrar sesion","cerrar sesión","logout","salir"], lambda: run(["qdbus6","org.kde.Shutdown","/Shutdown","logout"])),
]
_BY_ID = {a[0]: a for a in ACTIONS}


class ActionsRunner(dbus.service.Object):
    @dbus.service.method("org.kde.krunner1", in_signature="s", out_signature="a(sssida{sv})")
    def Match(self, query: str):
        q = query.strip().lower()
        if len(q) < 2:
            return []
        out = []
        for aid, label, icon, keywords, _ in ACTIONS:
            score = 0.0
            if any(q == k for k in keywords): score = 1.0
            elif any(q in k or k in q for k in keywords): score = 0.8
            elif q in label.lower(): score = 0.6
            if score > 0:
                mtype = 100 if score >= 1.0 else (50 if score >= 0.8 else 30)
                out.append((dbus.String(aid), dbus.String(label), dbus.String(icon),
                            dbus.Int32(mtype), dbus.Double(score),
                            dbus.Dictionary({"subtext": dbus.String("Acción de BookOS")}, signature="sv")))
        return out

    @dbus.service.method("org.kde.krunner1", in_signature="ss", out_signature="")
    def Run(self, match_id: str, action_id: str):
        a = _BY_ID.get(match_id)
        if a: a[4]()

    @dbus.service.method("org.kde.krunner1", in_signature="", out_signature="a(sss)")
    def Actions(self): return []

    @dbus.service.method("org.kde.krunner1", in_signature="", out_signature="")
    def Teardown(self): pass


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    try:
        # guardar la referencia: si se recolecta, se libera el nombre
        bus_name = dbus.service.BusName(BUS_NAME, bus=bus, allow_replacement=True, replace_existing=True)
    except dbus.exceptions.NameExistsException:
        sys.exit(0)
    runner = ActionsRunner(bus, OBJ_PATH)
    GLib.MainLoop().run()

if __name__ == "__main__":
    main()
