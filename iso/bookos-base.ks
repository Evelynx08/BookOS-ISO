# BookOS — kickstart base (shared by stable/beta/dev)
# Builds live ISO that includes BookOS branding + bookos-meta + KDE Plasma.

# --addsupport adds extra installed locales so the Anaconda installer language
# spoke offers them (not just en_US). Spanish here; add more comma-separated.
lang en_US.UTF-8 --addsupport=es_ES.UTF-8
keyboard --vckeymap=us --xlayouts='us'
timezone UTC
selinux --enforcing
# SSH is intentionally NOT enabled by default: a consumer laptop OS shouldn't
# ship a listening sshd / open firewall port on every install. Users who want
# remote access enable it themselves (systemctl enable --now sshd + open port).
firewall --enabled --service=mdns
network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=NetworkManager,bluetooth

bootloader --location=mbr --append="rhgb quiet rd.live.image ibt=off intel_pstate=passive nowatchdog nvme_core.default_ps_max_latency_us=5500 pcie_aspm=force pcie_aspm.policy=powersupersave workqueue.power_efficient=1 xe.enable_psr=1"
# Live image rootfs sizing for livemedia-creator. This is the SIZE OF THE LIVE
# IMAGE being built, not the installed system — Anaconda chooses the target
# disk layout at install time (Fedora's automatic install defaults to btrfs,
# which is what we want for snapshots).
part / --size=20000 --fstype="ext4"

# Root account locked (no direct root login). Anaconda still requires the Root
# password spoke to be "completed" in non-interactive mode, so this line must
# be present even though we disable the account.
rootpw --lock

# Live user is created at the END of %post (not here) so it is added AFTER the
# RPMs have populated /etc/skel — useradd -m then copies the FULL BookOS config
# (panel layout, widgets, theme, lockscreen toggle) into its home. Creating it
# here (the old `user` directive) ran before skel existed, which is why every
# skel write needed a manual /home/liveuser copy and why widgets/theme kept
# going missing. See the "Live user" block at the bottom of %post.

reboot --eject

# ── Repos ─────────────────────────────────────────────────────────────────
# Base install source — must be declared with `url` (not `repo`), or lorax
# errors: "repo can only be used within the url install method".
url --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
repo --name=rpmfusion-free --mirrorlist=https://mirrors.rpmfusion.org/metalink?repo=free-fedora-$releasever&arch=$basearch
# BookOS apps (calc, clock, notepad, settings, store…) live in the store-files
# repo. They must be available AT INSTALL TIME — bookos-meta Requires them — so
# declare the repo here, not only in %post (which only configures the installed
# system). Without this anaconda errors "No match for argument: bookos-calc".
repo --name=bookos-apps --baseurl=https://bookos.es/store-files/
# BookOS OS repo is defined by the per-channel kickstart (stable/beta/dev.ks),
# not here, to avoid a duplicate "bookos" repo definition.

# ── Packages ──────────────────────────────────────────────────────────────
# --ignoremissing: skip a package that isn't found instead of aborting the
# whole build (safety net for optional/renamed packages across Fedora versions).
%packages --ignoremissing
@^kde-desktop-environment
@standard
@base-x
@hardware-support
@multimedia
kernel-modules-extra
# ── Languages ───────────────────────────────────────────────────────────────
# Ship English + Spanish so the installer and the live session can switch
# language (and KDE/apps show translated UI). langpacks-XX pull the matching
# glibc locale, hunspell dict, fonts and app translations. Add more lines
# (langpacks-fr, -pt, -de…) to bundle further languages.
langpacks-en
langpacks-es
glibc-langpack-en
glibc-langpack-es
# SELinux: `selinux --enforcing` makes anaconda run load_policy during install.
# Without these it dies: "No such file or directory: '/usr/sbin/load_policy'".
policycoreutils
selinux-policy-targeted
# Required by livemedia-creator to produce a bootable live ISO
dracut-live
dracut-config-generic
# ISO bootloader bits (lorax builds the El Torito BIOS + UEFI boot at compose
# time; these provide the grub2 modules it needs, mirroring Fedora's own live
# kickstarts). Without grub2-pc-modules: "cannot open .../i386-pc/moddep.lst".
grub2-pc-modules
grub2-efi-x64
grub2-efi-x64-cdboot
shim-x64
syslinux

# Snapshot / rollback stack (btrfs) — lets BookOS Settings snapshot before
# every release upgrade and roll back from GRUB if something breaks.
# (No dnf snapper plugin: it isn't packaged on Fedora/dnf5; BookOS Settings
#  takes the snapshot itself in apply_bookos_release.)
snapper
inotify-tools

# BookOS umbrella package (Requires: pulls everything else)
bookos-meta
# Listed explicitly (not only via bookos-meta Requires) so a missing/unpublished
# bookos-widgets aborts the build loudly instead of being silently dropped by
# --ignoremissing. Ships the plasmoids into the live rootfs (/usr/share/plasma/
# plasmoids), which install-to-disk then copies to the device.
bookos-widgets
bookos-settings
bookos-store
bookos-calc
bookos-clock
bookos-notepad
bookos-branding
bookos-look-and-feel
bookos-desktop-defaults
# Optional apps — substituted by build-iso.sh when "all apps" is requested.
__BOOKOS_OPTIONAL_APPS__

# ── Samsung Galaxy Book hardware enablement ─────────────────────────────────
# Fingerprint: libfprint fork with the FMV ETU906AXX-E SPI sensor (Book5 Pro).
# It Provides/Obsoletes libfprint, so dnf installs it in place of the stock one.
libfprint-bookos
# Speakers: MAX98390 HDA DKMS module (Book4/5 Pro/Ultra). Hardware-guarded, so
# it no-ops on other machines. dkms + kernel-devel + akmods let it build and
# sign at compose time / on kernel updates; alsa-sof-firmware carries the DSM.
bookos-galaxybook-audio
dkms
kernel-devel
akmods
alsa-sof-firmware

# KDE essentials
sddm
plasma-workspace
dolphin
konsole
firefox

# SSH server present but NOT auto-started (see `services` line above). Shipping
# the package means a user can enable remote access with one command, no install
# or network needed: `sudo systemctl enable --now sshd` (+ open the firewall:
# `sudo firewall-cmd --add-service=ssh --permanent && sudo firewall-cmd --reload`).
openssh-server

# Anaconda installer for live media install-to-disk
anaconda
anaconda-live
anaconda-install-env-deps

# NOTE: we DON'T exclude fedora-logos/generic-logos here. They provide
# `system-logos`, required by breeze-icon-theme and the whole KDE stack; while
# the bookos repo isn't yet pulled into the build, excluding them breaks the
# entire dependency tree. BookOS identity is applied in %post (os-release etc.).
# Once bookos-branding installs from the repo (it Provides system-logos and
# Conflicts fedora-logos), re-add the exclusions.
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

# NOTE: the live user gets the FULL BookOS appearance automatically because it
# is created at the end of %post (useradd -m copies the finished /etc/skel). No
# manual /home/liveuser copies needed anymore.

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
gpgcheck=1
gpgkey=https://bookos.es/api/pubkey.php?type=gpg
metadata_expire=6h
skip_if_unavailable=True

[bookos-beta]
name=BookOS (beta)
baseurl=https://bookos.es/repo/fedora/\$releasever/\$basearch/beta/
enabled=$([ "__BOOKOS_CHANNEL__" = "beta" ] && echo 1 || echo 0)
gpgcheck=1
gpgkey=https://bookos.es/api/pubkey.php?type=gpg
metadata_expire=6h
skip_if_unavailable=True

[bookos-dev]
name=BookOS (dev)
baseurl=https://bookos.es/repo/fedora/\$releasever/\$basearch/dev/
enabled=$([ "__BOOKOS_CHANNEL__" = "dev" ] && echo 1 || echo 0)
gpgcheck=1
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
gpgcheck=1
gpgkey=https://bookos.es/api/pubkey.php?type=gpg
metadata_expire=300
skip_if_unavailable=True
EOF
# gpgcheck=1: packages MUST be GPG-signed. REQUIREMENT before publishing a
# release: sign every RPM (`rpmsign --addsign *.rpm` with the BookOS key) and
# import the public key on build/publish. The gpgkey= above points dnf at the
# public key endpoint so first install/upgrade imports it automatically.
# Unsigned packages now FAIL to install on devices (this is the point) — keep
# the publish pipeline signing or updates break.

# SDDM default theme (assuming bookos-branding installs theme files)
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/bookos-theme.conf <<'EOF'
[Theme]
Current=bookos
EOF

# Live session auto-login: boot STRAIGHT to the BookOS desktop, no SDDM prompt.
# (The liveuser password is cleared in the "Live user" block at the end of %post;
#  here we only write the SDDM autologin config.) Pick Wayland plasma if present,
# else X11. zz- prefix so it wins over any other drop-in.
LIVE_SESSION=plasma
[ -f /usr/share/wayland-sessions/plasma.desktop ] || LIVE_SESSION=plasmax11
cat > /etc/sddm.conf.d/zz-live-autologin.conf <<EOF
[Autologin]
User=liveuser
Session=$LIVE_SESSION
Relogin=true
EOF

# ── BookOS lockscreen ───────────────────────────────────────────────────
# Replicates bookos-settings' install_lockscreen_theme: overwrite the Plasma
# shell lockscreen with the staged BookOS QML so the live session AND fresh
# installs show the BookOS lockscreen out of the box (instead of plain Breeze),
# without the user having to flip the toggle in BookOS Settings.
LS_SRC=/usr/share/bookos-settings/lockscreen
LS_DEST=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen
if [ -d "$LS_SRC" ] && [ -d "$LS_DEST" ]; then
    mkdir -p "$LS_DEST/.backup"
    for f in MainBlock.qml LockScreenUi.qml BookBar.qml MediaControls.qml; do
        [ -f "$LS_DEST/$f" ] && cp -f "$LS_DEST/$f" "$LS_DEST/.backup/$f" 2>/dev/null || true
        [ -f "$LS_SRC/$f" ]  && cp -f "$LS_SRC/$f"  "$LS_DEST/$f"        2>/dev/null || true
    done
    touch "$LS_DEST/.bookos-installed"
fi

# ── Installer launcher on the live desktop ──────────────────────────────
# Without livesys-scripts nothing places the "Install to Hard Drive" icon on
# the live user's desktop. Copy anaconda's launcher there (and to /etc/skel so
# it survives the liveuser home copy), marked trusted so Plasma runs it.
for LAUNCH in /usr/share/applications/liveinst.desktop /usr/share/applications/anaconda.desktop; do
    [ -f "$LAUNCH" ] || continue
    DESK=/etc/skel/Desktop
    mkdir -p "$DESK"
    cp -f "$LAUNCH" "$DESK/" 2>/dev/null || true
    chmod +x "$DESK/$(basename "$LAUNCH")" 2>/dev/null || true
    # KDE: mark executable desktop files as trusted to skip the warning
    kwriteconfig6 --file "$DESK/$(basename "$LAUNCH")" --group "Desktop Entry" --key "X-KDE-AuthorizeExecution" "true" 2>/dev/null || true
done

# ── Keyboard backlight toggle (Fn+F9) ──────────────────────────────────────
# Samsung Galaxy Book exposes the keyboard backlight as an LED class device.
# Writing its `brightness` needs root, so Fn+F9 / the Control Station button do
# nothing for a normal user. Ship a cycler script, make the sysfs node writable
# by the `video` group via udev, and bind it to Fn+F9 for new users.
cat > /usr/libexec/bookos-kbd-backlight <<'SH'
#!/bin/sh
# Cycle the keyboard backlight one step (wraps to 0 at max).
LED=$(ls -d /sys/class/leds/*kbd_backlight 2>/dev/null | head -1)
[ -n "$LED" ] || exit 0
MAX=$(cat "$LED/max_brightness")
CUR=$(cat "$LED/brightness")
if [ "$CUR" -ge "$MAX" ]; then NEXT=0; else NEXT=$((CUR + 1)); fi
echo "$NEXT" > "$LED/brightness"
SH
chmod +x /usr/libexec/bookos-kbd-backlight
# Compat: the Control Station widget calls `bash ~/.toggle-luz.sh`.
cat > /etc/skel/.toggle-luz.sh <<'SH'
#!/bin/sh
exec /usr/libexec/bookos-kbd-backlight
SH
chmod +x /etc/skel/.toggle-luz.sh

# udev: make the kbd backlight node writable without root. `uaccess` grants the
# user of the active graphical session a write ACL (covers the installer-created
# user regardless of group); the chgrp/chmod to `video` is a fallback for the
# pre-created liveuser. Re-applied on hotplug.
cat > /etc/udev/rules.d/90-bookos-kbd-backlight.rules <<'EOF'
ACTION=="add|change", SUBSYSTEM=="leds", KERNEL=="*kbd_backlight", \
  TAG+="uaccess", \
  RUN+="/bin/chgrp video /sys/class/leds/%k/brightness", \
  RUN+="/bin/chmod g+w /sys/class/leds/%k/brightness"
EOF

# Bind Fn+F9 to the cycler for new users. Fn+F9 emits KEY_KBDILLUMTOGGLE; if
# powerdevil already handles it natively this is harmless (duplicate trigger),
# and it guarantees a working binding when it doesn't.
mkdir -p /etc/skel/.config
cat >> /etc/skel/.config/kglobalshortcutsrc <<'EOF'

[bookos-kbd-backlight.desktop]
_k_friendly_name=Keyboard backlight
_launch=Keyboard Backlight Up,none,/usr/libexec/bookos-kbd-backlight
EOF
mkdir -p /etc/skel/.local/share/applications
cat > /etc/skel/.local/share/applications/bookos-kbd-backlight.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Keyboard Backlight
Exec=/usr/libexec/bookos-kbd-backlight
NoDisplay=true
X-KDE-GlobalAccel-CommandShortcut=true
EOF

# Plymouth (boot splash) — branding RPM should install /usr/share/plymouth/themes/bookos
plymouth-set-default-theme bookos -R || true

# ── Galaxy Book speakers: pre-build the DKMS module into the image ──────────
# Build against the kernel shipped in the image (not the build host's running
# kernel) so the live session and fresh installs have working speakers without
# a first-boot compile. dkms.service still rebuilds on future kernel updates.
for KVER in $(ls /lib/modules 2>/dev/null); do
    [ -e "/lib/modules/$KVER/build" ] || continue
    dkms install -m max98390-hda -v 1.0 -k "$KVER" 2>/dev/null || true
done
systemctl enable dkms.service 2>/dev/null || true

# ── Default wallpaper ───────────────────────────────────────────────────────
# The captured layout may point at a developer path (file:///home/evelyn/...).
# Repoint any such reference in the shipped layout to a packaged wallpaper so
# the desktop isn't black on a fresh boot. Prefers blue_dark.png.
WP=/usr/share/backgrounds/bookos/Light/blue.png
[ -f "$WP" ] || WP="$(ls /usr/share/backgrounds/bookos/Light/*.png /usr/share/backgrounds/bookos/*.png 2>/dev/null | head -1)"
if [ -n "$WP" ]; then
    f=/etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc
    [ -f "$f" ] && sed -i -E "s#file://[^,\"]*(fondo\.png|/home/[^,\"]*\.(png|jpg|jpeg))#file://$WP#g" "$f" 2>/dev/null || true
fi

# Update icon cache after BookOS icons installed
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
kbuildsycoca6 --noincremental 2>/dev/null || true

# ── First-login applet-cache rebuild ────────────────────────────────────────
# The %post kbuildsycoca6 above runs as ROOT, so it builds /root's cache — not
# the live/installed user's. On a fresh boot plasmashell loads the shipped
# panel layout (plasma-org.kde.plasma.desktop-appletsrc) before the user's
# KPackage/sycoca index knows about the just-installed bookos-* plasmoids,
# giving "Error loading Applet: package bookos-menu does not exist". Rebuild the
# per-user cache on first login and restart plasmashell once, then self-delete.
mkdir -p /etc/skel/.config/autostart /usr/libexec /etc/bookos
# #6: default global look is a single editable file, NOT hardcoded in the script.
# Branding/look packages (or an admin) can change it to "BookOS Dark", etc.
echo "BookOS Light" > /etc/bookos/default-look
cat > /usr/libexec/bookos-first-login-refresh <<'SH'
#!/bin/sh
STAMP="$HOME/.config/.bookos-applet-refresh-done"
[ -f "$STAMP" ] && { rm -f "$HOME/.config/autostart/bookos-first-login-refresh.desktop"; exit 0; }
kbuildsycoca6 --noincremental 2>/dev/null || true
# Apply the BookOS global look-and-feel so Plasma cascades its colors/icons/
# style/decoration (otherwise it falls back to Breeze). Theme name read from
# /etc/bookos/default-look — no hardcoded name here.
LOOK="$(cat /etc/bookos/default-look 2>/dev/null)"; [ -n "$LOOK" ] || LOOK="BookOS Light"
plasma-apply-lookandfeel -a "$LOOK" 2>/dev/null || true
# Wallpaper isn't part of the LnF cascade; set it explicitly, Light/Dark aware.
case "$LOOK" in *Dark*) WPDIR=Dark;; *) WPDIR=Light;; esac
WP="/usr/share/backgrounds/bookos/$WPDIR/blue.png"
[ -f "$WP" ] || WP="$(ls /usr/share/backgrounds/bookos/$WPDIR/*.png /usr/share/backgrounds/bookos/*.png 2>/dev/null | head -1)"
[ -n "$WP" ] && plasma-apply-wallpaperimage "$WP" 2>/dev/null || true
touch "$STAMP"
# Restart plasmashell so it re-reads the applet list with the rebuilt cache.
(sleep 2; kquitapp6 plasmashell 2>/dev/null; kstart plasmashell 2>/dev/null || plasmashell --replace 2>/dev/null &) >/dev/null 2>&1 &
rm -f "$HOME/.config/autostart/bookos-first-login-refresh.desktop"
SH
chmod +x /usr/libexec/bookos-first-login-refresh
cat > /etc/skel/.config/autostart/bookos-first-login-refresh.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=BookOS first-login refresh
Exec=/usr/libexec/bookos-first-login-refresh
X-KDE-autostart-phase=2
NoDisplay=true
EOF

# ── No "package bookos-menu does not exist" on the panel ─────────────────────
# Complements the autostart above: this user service rebuilds the KDE sycoca/
# KPackage index BEFORE plasmashell paints (Plasma 6 boots the session via
# systemd), so the first boot never flashes the broken-applet error. The
# autostart then applies theme/wallpaper inside the session.
mkdir -p /etc/skel/.config/systemd/user/plasma-workspace.target.wants
cat > /etc/skel/.config/systemd/user/bookos-sycoca.service <<'UNIT'
[Unit]
Description=Rebuild KDE sycoca so BookOS plasmoids are known before the panel loads
Before=plasma-plasmashell.service
PartOf=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/bin/kbuildsycoca6 --noincremental

[Install]
WantedBy=plasma-workspace.target
UNIT
ln -sf ../bookos-sycoca.service \
    /etc/skel/.config/systemd/user/plasma-workspace.target.wants/bookos-sycoca.service
# (No liveuser seeding: liveuser is created via useradd -m at the end of %post,
#  which copies this finished /etc/skel.)

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

# Default to the graphical target + SDDM (the `services` line can't enable a
# display-manager that isn't installed at parse time; do it here instead).
systemctl set-default graphical.target 2>/dev/null || true
systemctl enable sddm.service 2>/dev/null || true

# ── Live user (created LAST, after /etc/skel is fully populated) ─────────────
# Doing this here — not via the kickstart `user` directive — means useradd -m
# copies the FINISHED /etc/skel (panel layout, widgets, theme, autostart, sycoca
# service, lockscreen toggle) into the live home in one shot. No per-file
# /home/liveuser copies, and nothing can be silently missed. Password cleared so
# SDDM autologin (zz-live-autologin.conf above) drops straight to the desktop.
if ! id liveuser >/dev/null 2>&1; then
    useradd -m -G wheel,audio,video -c "Live User" liveuser
fi
passwd -d liveuser 2>/dev/null || true

# Cleanup
dnf clean all
%end
