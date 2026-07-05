#!/usr/bin/env python3
"""BookOS Live States — broker central (bus de sesión).

Las apps publican su "estado en vivo" (música, batería, rutina, timer…) aquí;
el lockscreen (isla dinámica) y cualquier otro consumidor los lee/observa.

Interfaz org.bookos.LiveStates1 en org.bookos.LiveStates /bookos/LiveStates:
  Publish(s id, s json, b sticky)   crea/actualiza estado. sticky=false → se
                                    limpia solo cuando la app se desconecta del bus.
  Remove(s id)                      elimina estado.
  GetStates() -> a{ss}              id → json de todos los estados vivos.
  señal StateChanged(s id, s json)
  señal StateRemoved(s id)

JSON por tipo (campo común "type"):
  music   {type, player, title, artist, artUrl, playing, position, length, color}
  battery {type, level, plugged, minsToFull}
  routine {type, name, started, finish, objective}
"""
import json
import dbus, dbus.service, dbus.mainloop.glib
from gi.repository import GLib

BUS_NAME = "org.bookos.LiveStates"
OBJ_PATH = "/bookos/LiveStates"
IFACE = "org.bookos.LiveStates1"


class Broker(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, OBJ_PATH)
        self.states = {}   # id -> json str
        self.owners = {}   # id -> unique bus name (solo estados no-sticky)
        bus.add_signal_receiver(self._owner_changed, "NameOwnerChanged",
                                "org.freedesktop.DBus", "org.freedesktop.DBus")

    @dbus.service.method(IFACE, in_signature="ssb", out_signature="", sender_keyword="sender")
    def Publish(self, state_id, payload, sticky, sender=None):
        json.loads(payload)          # valida; lanza excepción D-Bus si no es JSON
        self.states[str(state_id)] = str(payload)
        if sticky:
            self.owners.pop(str(state_id), None)
        else:
            self.owners[str(state_id)] = str(sender)
        self.StateChanged(state_id, payload)

    @dbus.service.method(IFACE, in_signature="s", out_signature="")
    def Remove(self, state_id):
        sid = str(state_id)
        if self.states.pop(sid, None) is not None:
            self.owners.pop(sid, None)
            self.StateRemoved(sid)

    @dbus.service.method(IFACE, in_signature="", out_signature="a{ss}")
    def GetStates(self):
        return self.states

    @dbus.service.signal(IFACE, signature="ss")
    def StateChanged(self, state_id, payload):
        pass

    @dbus.service.signal(IFACE, signature="s")
    def StateRemoved(self, state_id):
        pass

    # la app se fue del bus → sus estados no-sticky mueren (nada de zombis)
    def _owner_changed(self, name, old, new):
        if str(new) != "":
            return
        for sid, owner in list(self.owners.items()):
            if owner == str(old):
                self.states.pop(sid, None)
                self.owners.pop(sid, None)
                self.StateRemoved(sid)


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName(BUS_NAME, bus)   # guardar la ref (si no, se libera el nombre)
    broker = Broker(bus)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
