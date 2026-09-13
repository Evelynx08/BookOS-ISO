#!/usr/bin/env python3
"""Collect shipped icon packs and widget sources without reading the host desktop."""
import json
from pathlib import Path
import re
import shutil
import sys
import tarfile
import tempfile
import zipfile

root, sources = map(Path, sys.argv[1:])
project = root / 'BookOS-ISO'
sources.mkdir(parents=True, exist_ok=True)
version = re.search(r'^Version:\s+(\S+)', (project / 'rpm/bookos-icons.spec').read_text(), re.M)[1]
with tarfile.open(sources / f'bookos-icons-{version}.tar.gz', 'w:gz') as archive:
    for variant in ('Dark', 'Light', 'Tinted-Dark', 'Tinted-Light'):
        pack = root / 'Icons' / f'BookOS-Icon-Pack-{variant}'
        if not (pack / 'index.theme').is_file():
            raise SystemExit(f'Missing icon pack: {pack}')
        archive.add(pack, arcname=f'bookos-icons-{version}/{pack.name}')
# Prefer maintained standalone projects where they exist; otherwise use the
# checked-in BookOS-Widgets sources, never the developer's installed widgets.
standalone = {'bookos-launchpad': 'BookOS-Launchpad', 'bookos-menu': 'BookOS-Menu/com.bookos.menu',
              'bookos-win11menu': 'BookOS-Win11-Menu'}
widgets = re.findall(r'^Source\d+:\s+(\S+)\.plasmoid',
                     (project / 'rpm/bookos-widgets.spec').read_text(), re.M)
for widget in widgets:
    source = root / 'BookOS-Widgets' / widget
    if widget in standalone:
        source = root / standalone[widget]
    if not (source / 'metadata.json').is_file():
        raise SystemExit(f'Missing widget sources: {source}')
    with tempfile.TemporaryDirectory() as tmp:
        stage = Path(tmp)
        for name in ('contents', 'po', 'metadata.json', 'icon.svg'):
            item = source / name
            if item.is_dir():
                shutil.copytree(item, stage / name)
            elif item.is_file():
                shutil.copy2(item, stage / name)
        metadata = json.loads((stage / 'metadata.json').read_text())
        metadata['KPlugin']['Id'] = widget
        (stage / 'metadata.json').write_text(json.dumps(metadata, ensure_ascii=False))
        with zipfile.ZipFile(sources / f'{widget}.plasmoid', 'w', zipfile.ZIP_DEFLATED) as archive:
            for file in sorted(stage.rglob('*')):
                if file.is_file():
                    archive.write(file, file.relative_to(stage))
