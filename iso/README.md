# BookOS ISO build

## Quick start

```bash
# Build stable 1.0
sudo ./build-iso.sh stable 1.0

# Beta
sudo ./build-iso.sh beta 1.1-rc.1

# Dev
sudo ./build-iso.sh dev 1.2-dev.42
```

Output: `bookos-<version>-<channel>-x86_64.iso` in current dir (or `$OUTDIR`).

## Dependencies (host)

```bash
sudo dnf install lorax-lmc-novirt pykickstart fedora-kickstarts
```

## Branding workflow

To change BookOS look:

1. Edit `bookos-branding` RPM contents (logos, wallpapers, sddm theme, plymouth).
2. Bump `bookos-branding.spec` Version.
3. Bump `bookos-meta.spec` `Requires: bookos-branding = NEW`.
4. Build both RPMs:
   ```bash
   rpmbuild -ba bookos-branding.spec
   rpmbuild -ba bookos-meta.spec
   ```
5. Push to channel repo:
   ```bash
   scp *.rpm bookos.es:/var/www/bookos/repo/fedora/41/x86_64/<channel>/
   ssh bookos.es 'createrepo_c /var/www/bookos/repo/fedora/41/x86_64/<channel>/'
   ```
6. Rebuild ISO (picks up new RPM automatically via the channel repo).

## Branding files needed

`bookos-branding-1.0.tar.gz` should contain:

```
bookos-branding-1.0/
├── logos/
│   ├── bookos.svg
│   ├── bookos.png
│   └── bookos-symbolic.svg
├── wallpapers/
│   ├── default-dark.png
│   └── default-light.png
├── sddm-theme/        (copied from BookOS-Settings/src-tauri/extra/sddm-theme)
├── plymouth-theme/    (Plymouth .plymouth + script + images)
└── lockscreen/        (copied from BookOS-Settings/src-tauri/extra/lockscreen)
```

## Channels = repo URLs

| Channel | URL                                                         |
|---------|-------------------------------------------------------------|
| stable  | https://bookos.es/repo/fedora/41/x86_64/stable/             |
| beta    | https://bookos.es/repo/fedora/41/x86_64/beta/               |
| dev     | https://bookos.es/repo/fedora/41/x86_64/dev/                |

Channel switching at runtime is handled by BookOS Settings (`set_update_channel`):
it rewrites `/etc/yum.repos.d/bookos-*.repo` priorities so the chosen channel
becomes active for the next `dnf upgrade bookos-meta`.

## Signing

If `/etc/bookos/minisign.key` exists, `build-iso.sh` produces `.iso.minisig`.
Distribute alongside ISO. Client verifies before booting.
