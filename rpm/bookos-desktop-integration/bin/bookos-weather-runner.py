#!/usr/bin/env python3
"""BookOS Weather KRunner plugin — 'clima <ciudad>' / 'tiempo <ciudad>' / 'weather <city>'.
Implementa org.kde.krunner1 (Plasma 6). Datos de wttr.in (sin API key), con caché 10 min.
"""
import sys, time, urllib.request, urllib.parse
import dbus, dbus.service, dbus.mainloop.glib
from gi.repository import GLib

BUS_NAME = "org.bookos.Weather"
OBJ_PATH = "/bookos/Weather"
TRIGGERS = ("clima ", "tiempo ", "weather ")
_cache = {}   # ciudad -> (texto, epoch)
CACHE_TTL = 600

def fetch(city: str) -> str:
    key = city.lower()
    now = time.time()
    if key in _cache and now - _cache[key][1] < CACHE_TTL:
        return _cache[key][0]
    try:
        url = "https://wttr.in/%s?format=%%l:+%%c+%%t+(sensación+%%f),+%%h,+viento+%%w&m" % urllib.parse.quote(city)
        req = urllib.request.Request(url, headers={"User-Agent": "curl/8"})
        txt = urllib.request.urlopen(req, timeout=3).read().decode("utf-8", "replace").strip()
        if txt and "Unknown location" not in txt:
            _cache[key] = (txt, now)
            return txt
    except Exception:
        pass
    return ""

def parse_city(q: str):
    ql = q.lower()
    for t in TRIGGERS:
        if ql.startswith(t):
            return q[len(t):].strip()
    return None


class WeatherRunner(dbus.service.Object):
    @dbus.service.method("org.kde.krunner1", in_signature="s", out_signature="a(sssida{sv})")
    def Match(self, query: str):
        city = parse_city(query.strip())
        if not city or len(city) < 2:
            return []
        info = fetch(city)
        if not info:
            return [(dbus.String("weather:"+city), dbus.String("Clima: ciudad no encontrada o sin red"),
                     dbus.String("weather-none-available"), dbus.Int32(30), dbus.Double(0.5),
                     dbus.Dictionary({}, signature="sv"))]
        return [(dbus.String("weather:"+city), dbus.String(info),
                 dbus.String("weather-clear"), dbus.Int32(100), dbus.Double(1.0),
                 dbus.Dictionary({"subtext": dbus.String("Pulsa para el pronóstico completo")}, signature="sv"))]

    @dbus.service.method("org.kde.krunner1", in_signature="ss", out_signature="")
    def Run(self, match_id: str, action_id: str):
        city = match_id.split(":", 1)[1] if ":" in match_id else ""
        import subprocess
        subprocess.Popen(["xdg-open", "https://wttr.in/%s" % urllib.parse.quote(city)])

    @dbus.service.method("org.kde.krunner1", in_signature="", out_signature="a(sss)")
    def Actions(self): return []

    @dbus.service.method("org.kde.krunner1", in_signature="", out_signature="")
    def Teardown(self): pass


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    try:
        bus_name = dbus.service.BusName(BUS_NAME, bus=bus, allow_replacement=True, replace_existing=True)
    except dbus.exceptions.NameExistsException:
        sys.exit(0)
    runner = WeatherRunner(bus, OBJ_PATH)
    GLib.MainLoop().run()

if __name__ == "__main__":
    main()
