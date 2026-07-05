#!/usr/bin/env python3
"""BookOS Live States — puente UPower → broker.

Publica el live state "battery": nivel, enchufado y minutos hasta llenar
(UPower ya respeta charge_control_end_threshold, así que "lleno" = el límite
BookOS del 80% cuando está activo).

  battery {type:"battery", level, plugged, minsToFull}
"""
import json
import dbus, dbus.mainloop.glib
from gi.repository import GLib

UPOWER = "org.freedesktop.UPower"
DEVICE = "/org/freedesktop/UPower/devices/DisplayDevice"
DEV_IFACE = "org.freedesktop.UPower.Device"
PROPS_IFACE = "org.freedesktop.DBus.Properties"
CHARGING_STATES = (1, 4)   # 1 charging, 4 fully-charged

BROKER = ("org.bookos.LiveStates", "/bookos/LiveStates", "org.bookos.LiveStates1")


class BatteryBridge:
    def __init__(self, session_bus, system_bus):
        self.session = session_bus
        self.device = dbus.Interface(system_bus.get_object(UPOWER, DEVICE), PROPS_IFACE)
        system_bus.add_signal_receiver(lambda *a: self.publish(), "PropertiesChanged",
                                       PROPS_IFACE, UPOWER, DEVICE)
        self.publish()

    def publish(self):
        try:
            p = self.device.GetAll(DEV_IFACE)
            state = {
                "type": "battery",
                "level": int(p.get("Percentage", 0)),
                "plugged": int(p.get("State", 0)) in CHARGING_STATES,
                "minsToFull": int(p.get("TimeToFull", 0)) // 60,
            }
            iface = dbus.Interface(self.session.get_object(BROKER[0], BROKER[1]), BROKER[2])
            iface.Publish("battery", json.dumps(state), False)
        except dbus.DBusException:
            pass


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    BatteryBridge(dbus.SessionBus(), dbus.SystemBus())
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()
