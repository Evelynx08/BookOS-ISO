#!/usr/bin/env bash
# sanitize-layout.sh — make a Plasma look-and-feel layout.js shippable.
#
# The panel layout the dev sees lives in the RUNNING plasmashell, not on disk
# (Plasma only flushes panel geometry on logout), and whatever IS on disk is
# full of developer-only absolute paths (file:///home/evelyn/…). Copying that
# straight into the look bundle is why ISO panels kept coming out wrong /
# with a broken menu button and black wallpaper.
#
# This script rewrites a layout.js in place so it is reproducible on a fresh
# install: dev paths → packaged paths, dead custom button image → default icon,
# and floating panels turned on (dumpCurrentLayoutJS doesn't serialise that).
#
#   bash sanitize-layout.sh <layout.js> [more.js …]
set -euo pipefail

for f in "$@"; do
    [ -f "$f" ] || { echo "  ⚠ no existe: $f" >&2; continue; }

    # Wallpaper → packaged default. The per-user wallpaper is re-applied
    # Light/Dark-aware at first login (bookos-first-login-refresh), so any valid
    # packaged image here is fine; this just stops the layout shipping a black
    # desktop from a missing /home path.
    sed -i -E 's#("Image":[[:space:]]*")file://[^"]*(")#\1file:///usr/share/backgrounds/bookos/Light/blue.png\2#g' "$f"
    sed -i -E 's#("SlidePaths":[[:space:]]*")[^"]*(")#\1/usr/share/backgrounds/bookos/,/usr/share/wallpapers/\2#g' "$f"

    # Dead custom menu-button image (panel-black.svg no longer exists): drop the
    # override so the launcher falls back to its themed default icon.
    sed -i -E 's#("customButtonImage":[[:space:]]*")[^"]*(")#\1\2#g' "$f"
    sed -i -E 's#("useCustomButtonImage":[[:space:]]*")true(")#\1false\2#g' "$f"

    # Any other applet icon pointing at a dev path → a guaranteed-present icon.
    sed -i -E 's#("icon":[[:space:]]*")/home/[^"]*(")#\1start-here-kde\2#g' "$f"

    # Plugin ids: the dev desktop runs the plasmoids under their original long
    # ids (~/.local), but collect-widgets.sh ships them renamed to short
    # bookos-* ids. A captured layout must reference the SHIPPED ids or every
    # BookOS widget shows "package … does not exist" on the ISO.
    sed -i \
        -e 's/"com\.bookos\.launchpad"/"bookos-launchpad"/g' \
        -e 's/"com\.bookos\.menu"/"bookos-menu"/g' \
        -e 's/"com\.bookos\.bookbar"/"bookos-bookbar"/g' \
        -e 's/"com\.bookos\.win11menu"/"bookos-win11menu"/g' \
        -e 's/"com\.mi\.widget\.bateria"/"bookos-battery"/g' \
        -e 's/"KdeControlStation"/"bookos-controlstation"/g' \
        "$f"

    # Floating panels (dumpCurrentLayoutJS doesn't emit "floating"). The BookOS
    # design: bottom dock floats, top bar does not. Key off each panel's
    # "location" line, unless floating is already present.
    if ! grep -q '"floating"' "$f"; then
        sed -i -E 's#^([[:space:]]*)("location":[[:space:]]*"bottom",)#\1\2\n\1"floating": true,#g' "$f"
        sed -i -E 's#^([[:space:]]*)("location":[[:space:]]*"top",)#\1\2\n\1"floating": false,#g' "$f"
    fi

    echo "  + sanitizado: $f"
done
