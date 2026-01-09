Name:       xconnect
Version:    1.4.2
Release:    0
Summary:    RPM package
License:    GPL-3.0
URL:        https://xconnect.app
Vendor:     XConnect <info@xconnect.app>
Requires:   gtk3 libxcb1 xdotool libXfixes3 alsa-utils libXtst6 libva2 pam gstreamer-plugins-base gstreamer-plugin-pipewire
Recommends: libayatana-appindicator3-1

# https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/

%description
The best open-source remote desktop client software, written in Rust.

%prep
# we have no source, so nothing here

%build
# we have no source, so nothing here

%global __python %{__python3}

%install
mkdir -p %{buildroot}/usr/bin/
mkdir -p %{buildroot}/usr/share/xconnect/
mkdir -p %{buildroot}/usr/share/xconnect/files/
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps/
mkdir -p %{buildroot}/usr/share/icons/hicolor/scalable/apps/
install -m 755 $HBB/target/release/xconnect %{buildroot}/usr/bin/xconnect
install $HBB/libsciter-gtk.so %{buildroot}/usr/share/xconnect/libsciter-gtk.so
install $HBB/res/xconnect.service %{buildroot}/usr/share/xconnect/files/
install $HBB/res/128x128@2x.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/xconnect.png
install $HBB/res/scalable.svg %{buildroot}/usr/share/icons/hicolor/scalable/apps/xconnect.svg
install $HBB/res/xconnect.desktop %{buildroot}/usr/share/xconnect/files/
install $HBB/res/xconnect-link.desktop %{buildroot}/usr/share/xconnect/files/
install -Dm 644 $HBB/res/xconnect.desktop -t "%{buildroot}/etc/xdg/autostart"

%files
/usr/bin/xconnect
/usr/share/xconnect/libsciter-gtk.so
/usr/share/xconnect/files/xconnect.service
/usr/share/icons/hicolor/256x256/apps/xconnect.png
/usr/share/icons/hicolor/scalable/apps/xconnect.svg
/usr/share/xconnect/files/xconnect.desktop
/usr/share/xconnect/files/xconnect-link.desktop
/etc/xdg/autostart/xconnect.desktop

%changelog
# let's skip this for now

%pre
# can do something for centos7
case "$1" in
  1)
    # for install
  ;;
  2)
    # for upgrade
    systemctl stop xconnect || true
  ;;
esac

%post
cp /usr/share/xconnect/files/xconnect.service /etc/systemd/system/xconnect.service
cp /usr/share/xconnect/files/xconnect.desktop /usr/share/applications/
cp /usr/share/xconnect/files/xconnect-link.desktop /usr/share/applications/
systemctl daemon-reload
systemctl enable xconnect
systemctl start xconnect
update-desktop-database

%preun
case "$1" in
  0)
    # for uninstall
    systemctl stop xconnect || true
    systemctl disable xconnect || true
    rm /etc/systemd/system/xconnect.service || true
  ;;
  1)
    # for upgrade
  ;;
esac

%postun
case "$1" in
  0)
    # for uninstall
    rm /usr/share/applications/xconnect.desktop || true
    rm /usr/share/applications/xconnect-link.desktop || true
    rm /etc/xdg/autostart/xconnect.desktop || true
    update-desktop-database
  ;;
  1)
    # for upgrade
  ;;
esac
