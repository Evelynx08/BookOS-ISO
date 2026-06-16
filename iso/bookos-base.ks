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
# BookOS repo — overridden in stable/beta/dev kickstarts.
repo --name=bookos --baseurl=https://bookos.es/repo/fedora/$releasever/$basearch/stable/

# ── Packages ──────────────────────────────────────────────────────────────
%packages
@^kde-desktop-environment
@standard
@base-x
@hardware-support
@multimedia
kernel-modules-extra

# BookOS umbrella package (Requires: pulls everything else)
bookos-meta
bookos-settings
bookos-store
bookos-calc
bookos-clock
bookos-notepad
bookos-branding
bookos-wallpapers

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
NAME=BookOS
VERSION=__BOOKOS_VERSION__
CHANNEL=__BOOKOS_CHANNEL__
INSTALLED=BookOS __BOOKOS_VERSION__
EOF

# /etc/os-release rewrite (overrides Fedora identity)
cat > /etc/os-release <<'EOF'
NAME="BookOS"
PRETTY_NAME="BookOS __BOOKOS_VERSION__ (__BOOKOS_CHANNEL__)"
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

# Hostname default
echo "bookos" > /etc/hostname

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

# Cleanup
dnf clean all
%end
