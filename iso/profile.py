#!/usr/bin/env python3
"""Render and validate the BookOS kickstart without composing an image."""
import argparse
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent


def render(channel="dev", name="BookOS", version="0.6.2", release="44", apps=()):
    if channel not in ("dev", "beta", "stable"):
        raise ValueError("Invalid channel")
    if not re.fullmatch(r"[A-Za-z0-9 ._-]+", name):
        raise ValueError("OS name must contain only letters, digits, spaces, '.', '_' or '-'")
    if not re.fullmatch(r"[A-Za-z0-9._-]+", version) or not release.isdigit():
        raise ValueError("Invalid version or Fedora release")
    if any(not re.fullmatch(r"[A-Za-z0-9+._-]+", app) for app in apps):
        raise ValueError("Invalid optional package name")
    raw = (HERE / f"bookos-{channel}.ks").read_text()
    raw = re.sub(r"^%include bookos-base.ks$", lambda _: (HERE / "bookos-base.ks").read_text(), raw, flags=re.M)
    replacements = {
        "__BOOKOS_NAME__": name, "__BOOKOS_VERSION__": version,
        "__BOOKOS_CHANNEL__": channel, "__RELEASEVER__": release,
        "__BASEARCH__": "x86_64", "__BOOKOS_OPTIONAL_APPS__": "\n".join(apps),
        "__BOOKOS_BOOT_FINALIZE__": (HERE / "files/bookos-boot-finalize.sh").read_text().rstrip(),
    }
    for key, value in replacements.items():
        raw = raw.replace(key, value)
    if re.search(r"__(?:BOOKOS_\w+|RELEASEVER|BASEARCH)__", raw):
        raise ValueError("Unresolved kickstart placeholder")
    return raw


def validate(raw):
    from pykickstart.parser import KickstartParser
    from pykickstart.version import makeVersion
    parser = KickstartParser(makeVersion("F44"))
    parser.readKickstartFromString(raw)
    for script in parser.handler.scripts:
        if script.interp in ("/bin/sh", "/bin/bash", "/usr/bin/bash"):
            subprocess.run(["bash", "-n"], input=script.script, text=True, check=True)
    return parser.handler


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--channel", default="dev")
    p.add_argument("--name", default="BookOS")
    p.add_argument("--version", default="0.6.2")
    p.add_argument("--release", default="44")
    p.add_argument("--apps", nargs="*", default=[])
    p.add_argument("--check", action="store_true")
    args = p.parse_args()
    output = render(args.channel, args.name, args.version, args.release, args.apps)
    handler = validate(output)
    if args.check:
        print(f"Valid {args.channel} profile: {len(handler.packages.packageList)} explicit packages, {len(handler.scripts)} scripts")
    else:
        print(output, end="")
