#!/usr/bin/env bash
# Build current app sources against Fedora 44, without modifying sibling repos.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
SOURCES="$(dirname "$ROOT")"
WORK="${APP_WORK:-$ROOT/.build/apps}"
mkdir -p "$WORK"
podman run --replace --rm --name bookos-app-build-0.6.2 --security-opt label=disable \
    -v "$SOURCES":/sources:ro -v "$WORK":/work \
    registry.fedoraproject.org/fedora:44 \
    bash /sources/BookOS-ISO/iso/build-apps-fedora.sh "$@"
# Only import after every app succeeds and the manifest has been verified.
python3 "$HERE/app-catalog.py" verify "$WORK/repo"
DEST="$ROOT/.build/package-check/repo"
mkdir -p "$DEST"
python3 - "$WORK/repo" "$DEST" <<'PY'
import json, shutil, sys
from pathlib import Path
src, dst = map(Path, sys.argv[1:])
entries = json.loads((src / 'bookos-apps.json').read_text())
for entry in entries:
    # Delete only artifacts previously recorded by this builder.
    old_manifest = dst / 'bookos-apps.json'
    if old_manifest.exists():
        for old in json.loads(old_manifest.read_text()):
            if old['name'] == entry['name'] and Path(old['file']).name == old['file']:
                (dst / old['file']).unlink(missing_ok=True)
    shutil.copy2(src / entry['file'], dst / entry['file'])
shutil.copy2(src / 'bookos-apps.json', dst / 'bookos-apps.json')
PY
printf 'Fresh application RPMs: %s\n' "$DEST"
