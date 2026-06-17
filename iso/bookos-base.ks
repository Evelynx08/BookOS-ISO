# BookOS — kickstart base (shared by stable/beta/dev)
# Builds live ISO that includes BookOS branding + bookos-meta + KDE Plasma.

lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts='us'
timezone UTC
selinux --enforcing
firewall --enabled --service=mdns,ssh
network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=NetworkManager,sshd,bluetooth,sddm

bootloader --location=mbr --append="rhgb quiet rd.live.image"
zerombr
clearpart --all --initlabel
autopart --type=btrfs

# Live user
user --name=liveuser --groups=wheel,audio,video --gecos="Live User"

reboot --eject

# ── Repos ─────────────────────────────────────────────────────────────────
repo --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
repo --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-$releasever&arch=$basearch
# BookOS repo is defined by the per-channel kickstart (stable/beta/dev.ks),
# not here, to avoid a duplicate "bookos" repo definition.

# ── Packages ──────────────────────────────────────────────────────────────
%packages
@^kde-desktop-environment
@standard
@base-x
@hardware-support
@multimedia
kernel-modules-extra
# Required by livemedia-creator to produce a bootable live ISO
dracut-live
dracut-config-generic

# Snapshot / rollback stack (btrfs) — lets BookOS Settings snapshot before
# every release upgrade and roll back from GRUB if something breaks.
snapper
python3-dnf-plugin-snapper
grub-btrfs
inotify-tools

# BookOS umbrella package (Requires: pulls everything else)
bookos-meta
bookos-settings
bookos-store
bookos-calc
bookos-clock
bookos-notepad
bookos-branding
bookos-wallpapers
bookos-look-and-feel
# Optional apps — substituted by build-iso.sh when "all apps" is requested.
__BOOKOS_OPTIONAL_APPS__

# KDE essentials
sddm
plasma-workspace
dolphin
konsole
firefox

# Anaconda installer for live media install-to-disk
anaconda
anaconda-live
anaconda-install-env-deps

-fedora-logos
-fedora-release
-fedora-release-common
-fedora-release-kde
-generic-logos
-generic-release
%end

# ── Post-install: branding overrides ──────────────────────────────────────
%post
# /etc/bookos-release identifies channel + version (read by Settings app)
cat > /etc/bookos-release <<'EOF'
NAME=__BOOKOS_NAME__
VERSION=__BOOKOS_VERSION__
CHANNEL=__BOOKOS_CHANNEL__
INSTALLED=__BOOKOS_NAME__ __BOOKOS_VERSION__
EOF

# /etc/os-release rewrite (overrides Fedora identity)
cat > /etc/os-release <<'EOF'
NAME="__BOOKOS_NAME__"
PRETTY_NAME="__BOOKOS_NAME__ __BOOKOS_VERSION__ (__BOOKOS_CHANNEL__)"
ID=bookos
ID_LIKE=fedora
VERSION="__BOOKOS_VERSION__"
VERSION_ID=__BOOKOS_VERSION__
ANSI_COLOR="0;38;2;10;132;255"
HOME_URL="https://bookos.es/"
DOCUMENTATION_URL="https://bookos.es/docs"
SUPPORT_URL="https://bookos.es/support"
BUG_REPORT_URL="https://bookos.es/bugs"
EOF
ln -sf /etc/os-release /usr/lib/os-release

# Hostname default (fallback; the model-detect service below overrides it on
# real Galaxy Book hardware so the installer shows e.g. "book5-pro").
echo "bookos" > /etc/hostname

# Ensure the live user also boots into the BookOS desktop (new users get it
# from /etc/skel; the pre-created liveuser needs an explicit copy).
if [ -f /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc ] && [ -d /home/liveuser ]; then
    mkdir -p /home/liveuser/.config
    cp /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc /home/liveuser/.config/
    chown -R liveuser:liveuser /home/liveuser/.config 2>/dev/null || true
fi

# ── Model-based hostname ────────────────────────────────────────────────
# Derives the hostname from the Samsung DMI model code (book5-pro, book4-edge,
# …) so the installer's default — and thus the installed system — is named
# after the laptop. Runs once (stamp file); the live sets it before Anaconda,
# so the install inherits it. User renames in the installer still win.
cat > /usr/libexec/bookos-set-hostname <<'SH'
#!/bin/sh
STAMP=/var/lib/bookos/hostname-set
[ -f "$STAMP" ] && exit 0
code=$(cat /sys/class/dmi/id/product_name /sys/class/dmi/id/board_name 2>/dev/null | tr 'a-z' 'A-Z')
case "$code" in
  *QQHA*) h=book5-pro-360 ;;
  *XHA*)  h=book5-pro ;;
  *QHA*)  h=book5-360 ;;
  *XHD*)  h=book5 ;;
  *XGL*)  h=book4-ultra ;;
  *QKG*)  h=book4-edge ;;
  *QGK*)  case "$code" in *960*|*964*) h=book4-pro-360 ;; *) h=book4-360 ;; esac ;;
  *XGK*)  case "$code" in *940*|*944*|*960*) h=book4-pro ;; *) h=book4 ;; esac ;;
  *XGJ*)  h=book4 ;;
  *)      h="" ;;
esac
mkdir -p /var/lib/bookos
if [ -n "$h" ]; then
  hostnamectl set-hostname "$h" 2>/dev/null || echo "$h" > /etc/hostname
fi
touch "$STAMP"
SH
chmod +x /usr/libexec/bookos-set-hostname

cat > /etc/systemd/system/bookos-hostname.service <<'UNIT'
[Unit]
Description=Set BookOS hostname from laptop model
DefaultDependencies=no
After=local-fs.target
Before=anaconda.service sddm.service display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/libexec/bookos-set-hostname
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
systemctl enable bookos-hostname.service 2>/dev/null || true

# ── Persistent BookOS repos on the installed system ─────────────────────────
# (The kickstart `repo` lines above are build-time only; these .repo files are
#  what stays on disk so the system can update after install.)
# dnf expands $releasever / $basearch at runtime, so the same file works on any
# Fedora base. The active channel is enabled; the others are present but off so
# BookOS Settings (set_update_channel) can switch between them.
mkdir -p /etc/yum.repos.d
cat > /etc/yum.repos.d/bookos-os.repo <<EOF
# BookOS system channels — bookos-meta + branding/widgets/themes (OS updates)
[bookos-stable]
name=BookOS (stable)
baseurl=https://bookos.es/repo/fedora/\$releasever/\$basearch/stable/
enabled=$([ "__BOOKOS_CHANNEL__" = "stable" ] && echo 1 || echo 0)
gpgcheck=0
gpgkey=https://bookos.es/api/pubkey.php?type=gpg
metadata_expire=6h
skip_if_unavailable=True

[bookos-beta]
name=BookOS (beta)
baseurl=https://bookos.es/repo/fedora/\$releasever/\$basearch/beta/
enabled=$([ "__BOOKOS_CHANNEL__" = "beta" ] && echo 1 || echo 0)
gpgcheck=0
gpgkey=https://bookos.es/api/pubkey.php?type=gpg
metadata_expire=6h
skip_if_unavailable=True

[bookos-dev]
name=BookOS (dev)
baseurl=https://bookos.es/repo/fedora/\$releasever/\$basearch/dev/
enabled=$([ "__BOOKOS_CHANNEL__" = "dev" ] && echo 1 || echo 0)
gpgcheck=0
gpgkey=https://bookos.es/api/pubkey.php?type=gpg
metadata_expire=6h
skip_if_unavailable=True
EOF

# Store apps repo (bookos-store / dnf install bookos-*)
cat > /etc/yum.repos.d/bookos.repo <<EOF
[bookos]
name=BookOS Apps
baseurl=https://bookos.es/store-files/
enabled=1
gpgcheck=0
gpgkey=https://bookos.es/api/pubkey.php?type=gpg
metadata_expire=300
skip_if_unavailable=True
EOF
# NOTE: gpgcheck=0 until the repos are GPG-signed (build-repo.sh with
# BOOKOS_GPG_KEY). Once signed, flip the gpgcheck lines to 1 — the gpgkey is
# already pointed at the public key endpoint.

# SDDM default theme (assuming bookos-branding installs theme files)
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/bookos-theme.conf <<'EOF'
[Theme]
Current=bookos
CursorTheme=Apple-cursors
EOF

# Plymouth (boot splash) — branding RPM should install /usr/share/plymouth/themes/bookos
plymouth-set-default-theme bookos -R || true

# Update icon cache after BookOS icons installed
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
kbuildsycoca6 --noincremental 2>/dev/null || true

# ── Theme the Anaconda WebUI installer (guaranteed: runs after every package
# is installed, unlike the RPM %post which may run before anaconda-webui). ──
THEME=/usr/share/anaconda/bookos/theme
if [ -f "$THEME/anaconda-webui-bookos.css" ]; then
  for idx in $(find /usr/share/cockpit/anaconda-webui /usr/share/anaconda -name index.html -path '*anaconda-webui*' 2>/dev/null); do
    d=$(dirname "$idx")
    cp -f "$THEME/anaconda-webui-bookos.css" "$d/bookos.css" || true
    # logo referenced by the CSS (url("bookos-logo.svg")) must sit beside it
    cp -f /usr/share/anaconda/bookos/pixmaps/bookos-logo.svg "$d/bookos-logo.svg" 2>/dev/null || true
    grep -q bookos.css "$idx" || sed -i 's#</head>#<link rel="stylesheet" href="bookos.css">\n</head>#' "$idx" || true
  done
fi
[ -f "$THEME/userChrome.css" ] && for fx in /usr/share/anaconda/firefox-theme/live/chrome /usr/share/anaconda/firefox-theme/default/chrome; do mkdir -p "$fx" && cp -f "$THEME/userChrome.css" "$fx/userChrome.css"; done 2>/dev/null || true

# Snapper: create the root config so pre/post snapshots work out of the box.
# (|| true: harmless if the subvolume layout already has it.)
snapper -c root create-config / 2>/dev/null || true
# Regenerate GRUB so grub-btrfs adds the "BookOS snapshots" submenu.
grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
systemctl enable grub-btrfsd 2>/dev/null || true

# Cleanup
dnf clean all
%end
