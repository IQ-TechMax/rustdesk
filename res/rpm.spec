Name:       rustdesk
Version:    1.4.2
Release:    0
Summary:    RPM package
License:    GPL-3.0
URL:        https://rustdesk.com
Vendor:     rustdesk <info@rustdesk.com>
Requires:   gtk3 libxcb libxdo libXfixes alsa-lib libva2 pam gstreamer1-plugins-base
Recommends: libayatana-appindicator-gtk3

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
install -m 755 $HBB/target/release/rustdesk %{buildroot}/usr/bin/rustdesk
install $HBB/libsciter-gtk.so %{buildroot}/usr/share/xconnect/libsciter-gtk.so
install $HBB/res/xconnect.service %{buildroot}/usr/share/xconnect/files/
install $HBB/res/128x128@2x.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/rustdesk.png
install $HBB/res/scalable.svg %{buildroot}/usr/share/icons/hicolor/scalable/apps/rustdesk.svg
install $HBB/res/xconnect.desktop %{buildroot}/usr/share/xconnect/files/
install $HBB/res/xconnect-link.desktop %{buildroot}/usr/share/xconnect/files/

%files
/usr/bin/rustdesk
/usr/share/xconnect/libsciter-gtk.so
/usr/share/xconnect/files/xconnect.service
/usr/share/icons/hicolor/256x256/apps/rustdesk.png
/usr/share/icons/hicolor/scalable/apps/rustdesk.svg
/usr/share/xconnect/files/xconnect.desktop
/usr/share/xconnect/files/xconnect-link.desktop
/usr/share/xconnect/files/__pycache__/*

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
    systemctl stop rustdesk || true
  ;;
esac

%post
cp /usr/share/xconnect/files/xconnect.service /etc/systemd/system/xconnect.service
cp /usr/share/xconnect/files/xconnect.desktop /usr/share/applications/
cp /usr/share/xconnect/files/xconnect-link.desktop /usr/share/applications/
systemctl daemon-reload
systemctl enable rustdesk
systemctl start rustdesk
update-desktop-database

%preun
case "$1" in
  0)
    # for uninstall
    systemctl stop rustdesk || true
    systemctl disable rustdesk || true
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
    update-desktop-database
  ;;
  1)
    # for upgrade
  ;;
esac
