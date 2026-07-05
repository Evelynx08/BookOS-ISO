#!/usr/bin/env python3
"""BookOS Live States — puente MPRIS → broker.

Observa TODOS los reproductores MPRIS del bus de sesión (Spotify, Elisa, mpv,
navegador…) y publica un live state "music.<player>" por cada uno. Así el
lockscreen pinta el pager de música con el pill vertical (una tarjeta por app
sonando) sin que las apps de música tengan que saber nada de BookOS.

Estado publicado:
  music.<player> {type:"music", player, title, artist, artUrl,
                  playing, position, length, canGoNext, canGoPrevious}

Los controles del lockscreen llaman de vuelta a MPRIS estándar
(org.mpris.MediaPlayer2.Player Play/Pause/Next/Previous del player).
"""
import json
import dbus, dbus.mainloop.glib
from gi.repository import GLib

MPRIS_PREFIX = "org.mpris.MediaPlayer2."
PLAYER_IFACE = "org.mpris.MediaPlayer2.Player"
PROPS_IFACE = "org.freedesktop.DBus.Properties"

BROKER = ("org.bookos.LiveStates", "/bookos/LiveStates", "org.bookos.LiveStates1")


class MediaBridge:
    def __init__(self, bus):
        self.bus = bus
        self.players = {}   # bus name -> señal conectada
        bus.add_signal_receiver(self._owner_changed, "NameOwnerChanged",
                                "org.freedesktop.DBus", "org.freedesktop.DBus")
        for name in bus.list_names():
            if str(name).startswith(MPRIS_PREFIX):
                self._attach(str(name))
        GLib.timeout_add_seconds(5, self._tick)   # posición mientras suena

    def _broker(self):
        return dbus.Interface(self.bus.get_object(BROKER[0], BROKER[1]), BROKER[2])

    def _state_id(self, name):
        return "music." + name[len(MPRIS_PREFIX):]

    def _attach(self, name):
        if name in self.players:
            return
        match = self.bus.add_signal_receiver(
            lambda iface, changed, inval, n=name: self._publish(n),
            "PropertiesChanged", PROPS_IFACE, name, "/org/mpris/MediaPlayer2")
        self.players[name] = match
        self._publish(name)

    def _detach(self, name):
        match = self.players.pop(name, None)
        if match:
            match.remove()
        try:
            self._broker().Remove(self._state_id(name))
        except dbus.DBusException:
            pass

    def _owner_changed(self, name, old, new):
        name = str(name)
        if not name.startswith(MPRIS_PREFIX):
            return
        if str(new) != "":
            self._attach(name)
        else:
            self._detach(name)

    def _publish(self, name):
        try:
            obj = self.bus.get_object(name, "/org/mpris/MediaPlayer2")
            props = dbus.Interface(obj, PROPS_IFACE)
            p = props.GetAll(PLAYER_IFACE)
            meta = p.get("Metadata", {})
            state = {
                "type": "music",
                "player": name[len(MPRIS_PREFIX):],
                "title": str(meta.get("xesam:title", "")),
                "artist": ", ".join(str(a) for a in meta.get("xesam:artist", [])),
                "artUrl": str(meta.get("mpris:artUrl", "")),
                "playing": str(p.get("PlaybackStatus", "")) == "Playing",
                "position": int(p.get("Position", 0)) // 1000000,
                "length": int(meta.get("mpris:length", 0)) // 1000000,
                "canGoNext": bool(p.get("CanGoNext", False)),
                "canGoPrevious": bool(p.get("CanGoPrevious", False)),
            }
            self._broker().Publish(self._state_id(name), json.dumps(state), False)
        except dbus.DBusException:
            pass   # player o broker desaparecieron a mitad; NameOwnerChanged limpia

    def _tick(self):
        for name in list(self.players):
            self._publish(name)
        return True


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    MediaBridge(bus)
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
