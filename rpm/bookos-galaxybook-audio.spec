Name:           bookos-galaxybook-audio
Version:        1.0
Release:        1%{?dist}
Summary:        Samsung Galaxy Book4/5 speaker support (MAX98390 HDA, DKMS)
# Vendored from Andycodeman/samsung-galaxy-book-linux-fixes (speaker-fix).
License:        GPL-2.0-only
URL:            https://github.com/Andycodeman/samsung-galaxy-book-linux-fixes
BuildArch:      noarch
# Produced by collect-galaxybook-fixes.sh into ~/rpmbuild/SOURCES.
Source0:        %{name}-%{version}.tar.gz

# DKMS builds the module against the running kernel; the i2c-setup service wires
# up the 4 MAX98390 amps; SOF firmware carries the DSM blobs.
Requires:       dkms
Requires:       alsa-sof-firmware
Requires(post): dkms
# Pulled so DKMS can compile on first boot / kernel updates without network.
Requires:       gcc
Requires:       make

%global dkms_name max98390-hda
%global dkms_ver  1.0

%description
Out-of-tree MAX98390 HDA codec driver (DKMS) that brings working speakers to
the Samsung Galaxy Book4/Book5 Pro and Ultra, whose 4 Maxim MAX98390 I2C
amplifiers are not yet driven by the mainline kernel. Includes the I2C device
setup service and an upstream-watcher that self-disables once the kernel gains
native support. Hardware-guarded: the services no-op on machines without the
MAX98390 amps, so the package is safe to ship in the generic image.

%prep
%autosetup -n %{name}-%{version}

%install
# DKMS module source → /usr/src/<name>-<ver> (standard DKMS layout).
SRC=%{buildroot}/usr/src/%{dkms_name}-%{dkms_ver}
install -dm755 "$SRC/src"
install -m644 src/*.c src/*.h "$SRC/src/"
install -m644 src/Makefile    "$SRC/src/"
install -m644 dkms.conf        "$SRC/"

# Helper scripts → /usr/local/sbin (path baked into the .service ExecStart).
install -dm755 %{buildroot}/usr/local/sbin
install -m755 max98390-hda-i2c-setup.sh      %{buildroot}/usr/local/sbin/
install -m755 max98390-hda-check-upstream.sh %{buildroot}/usr/local/sbin/

# Systemd units (ship under /usr/lib, enabled via the systemd scriptlets).
install -dm755 %{buildroot}%{_unitdir}
install -m644 max98390-hda-i2c-setup.service      %{buildroot}%{_unitdir}/
install -m644 max98390-hda-check-upstream.service %{buildroot}%{_unitdir}/

# Autoload the codec module at boot.
install -dm755 %{buildroot}/etc/modules-load.d
cat > %{buildroot}/etc/modules-load.d/%{dkms_name}.conf <<'EOF'
snd-hda-scodec-max98390
snd-hda-scodec-max98390-i2c
EOF

# Sign the DKMS module with the akmods key so it loads under Secure Boot
# (no-op if Secure Boot is off; the key still needs MOK enrollment once).
install -dm755 %{buildroot}/etc/dkms/framework.conf.d
cat > %{buildroot}/etc/dkms/framework.conf.d/akmods-keys.conf <<'EOF'
mok_signing_key="/etc/pki/akmods/private/private_key.priv"
mok_certificate="/etc/pki/akmods/certs/public_key.der"
sign_tool="/usr/lib/akmods/akmods-keygen"
EOF

%files
/usr/src/%{dkms_name}-%{dkms_ver}/
/usr/local/sbin/max98390-hda-i2c-setup.sh
/usr/local/sbin/max98390-hda-check-upstream.sh
%{_unitdir}/max98390-hda-i2c-setup.service
%{_unitdir}/max98390-hda-check-upstream.service
/etc/modules-load.d/%{dkms_name}.conf
%config(noreplace) /etc/dkms/framework.conf.d/akmods-keys.conf

%post
%systemd_post max98390-hda-i2c-setup.service max98390-hda-check-upstream.service
# Register the module and build for every installed kernel that has headers.
# (|| true: during ISO compose the target kernel isn't running; the kickstart
#  %post and dkms.service handle the actual compile against the image kernel.)
dkms add -m %{dkms_name} -v %{dkms_ver} 2>/dev/null || true
for KVER in $(ls /lib/modules 2>/dev/null); do
    [ -e "/lib/modules/$KVER/build" ] && \
        dkms install -m %{dkms_name} -v %{dkms_ver} -k "$KVER" 2>/dev/null || true
done

%preun
%systemd_preun max98390-hda-i2c-setup.service max98390-hda-check-upstream.service
if [ "$1" = 0 ]; then
    dkms remove -m %{dkms_name} -v %{dkms_ver} --all 2>/dev/null || true
fi

%postun
%systemd_postun max98390-hda-i2c-setup.service max98390-hda-check-upstream.service

%changelog
* Fri Jun 19 2026 BookOS <packages@bookos.es> - 1.0-1
- Initial: MAX98390 HDA speaker DKMS for Galaxy Book4/5 (vendored upstream)
