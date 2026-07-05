"""BookOS Live States — librería publisher para apps Python.

Uso:
    from livestate import LiveState
    st = LiveState("timer")                       # id único de la app
    st.update(type="timer", title="Pasta", remaining=300)
    ...
    st.remove()                                   # o deja morir el proceso:
                                                  # el broker limpia solo (no-sticky)
"""
import json
import dbus

BUS_NAME = "org.bookos.LiveStates"
OBJ_PATH = "/bookos/LiveStates"
IFACE = "org.bookos.LiveStates1"


class LiveState:
    def __init__(self, state_id: str, sticky: bool = False, bus=None):
        self.id = state_id
        self.sticky = sticky
        self._bus = bus or dbus.SessionBus()
        self._iface = None

    def _broker(self):
        if self._iface is None:
            obj = self._bus.get_object(BUS_NAME, OBJ_PATH)
            self._iface = dbus.Interface(obj, IFACE)
        return self._iface

    def update(self, **fields):
        self._broker().Publish(self.id, json.dumps(fields), self.sticky)

    def remove(self):
        try:
            self._broker().Remove(self.id)
        except dbus.DBusException:
            pass
