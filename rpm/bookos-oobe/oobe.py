#!/usr/bin/python3
"""BookOS OOBE — host QML del asistente de primer arranque.

Corre como root (lo lanza bookos-oobe-session dentro de cage/kwin_wayland),
así que puede crear el usuario directamente con useradd/chpasswd.
"""
import re
import subprocess
import sys

from PyQt6.QtCore import QObject, QUrl, pyqtSlot
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine

QML = "/usr/share/bookos-oobe/Main.qml"


class Backend(QObject):
    @pyqtSlot(str, str, str, str, result=str)
    def createUser(self, fullname, username, password, hostname):
        """Crea el usuario; devuelve "" si todo bien o el error a mostrar."""
        username = username.strip()
        fullname = fullname.strip()
        if not re.fullmatch(r"[a-z_][a-z0-9_-]{0,31}", username):
            return "Usuario no válido: minúsculas, números y guiones, sin espacios."
        if subprocess.run(["id", username], capture_output=True).returncode == 0:
            return "Ese nombre de usuario ya existe."
        if len(password) < 1:
            return "La contraseña no puede estar vacía."
        r = subprocess.run(
            ["useradd", "-m", "-G", "wheel,audio,video", "-c", fullname, username],
            capture_output=True, text=True,
        )
        if r.returncode != 0:
            return "useradd: " + (r.stderr.strip() or "error desconocido")
        r = subprocess.run(
            ["chpasswd"], input=f"{username}:{password}",
            capture_output=True, text=True,
        )
        if r.returncode != 0:
            subprocess.run(["userdel", "-r", username], capture_output=True)
            return "chpasswd: " + (r.stderr.strip() or "error desconocido")
        hn = re.sub(r"[^A-Za-z0-9-]+", "-", hostname).strip("-")[:63] or "bookos"
        try:
            with open("/etc/hostname", "w", encoding="utf-8") as f:
                f.write(hn + "\n")
        except OSError:
            pass
        subprocess.run(["hostnamectl", "set-hostname", hn], capture_output=True)
        return ""


def main():
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    backend = Backend()
    engine.rootContext().setContextProperty("backend", backend)
    engine.load(QUrl.fromLocalFile(QML))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
