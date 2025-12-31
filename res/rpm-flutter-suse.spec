Name:       rustdesk
Version:    1.4.2
Release:    0
Summary:    RPM package
License:    GPL-3.0
URL:        https://rustdesk.com
Vendor:     rustdesk <info@rustdesk.com>
Requires:   gtk3 libxcb1 xdotool libXfixes3 alsa-utils libXtst6 libva2 pam gstreamer-plugins-base gstreamer-plugin-pipewire
Recommends: libayatana-appindicator3-1
Provides:   libdesktop_drop_plugin.so()(64bit), libdesktop_multi_window_plugin.so()(64bit), libfile_selector_linux_plugin.so()(64bit), libflutter_custom_cursor_plugin.so()(64bit), libflutter_linux_gtk.so()(64bit), libscreen_retriever_plugin.so()(64bit), libtray_manager_plugin.so()(64bit), liburl_launcher_linux_plugin.so()(64bit), libwindow_manager_plugin.so()(64bit), libwindow_size_plugin.so()(64bit), libtexture_rgba_renderer_plugin.so()(64bit)

# https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/

%description
The best open-source remote desktop client software, written in Rust.

%prep
# we have no source, so nothing here

%build
# we have no source, so nothing here

# %global __python %{__python3}

%install

mkdir -p "%{buildroot}/usr/share/xconnect" && cp -r ${HBB}/flutter/build/linux/x64/release/bundle/* -t "%{buildroot}/usr/share/xconnect"
mkdir -p "%{buildroot}/usr/bin"
install -Dm 644 $HBB/res/xconnect.service -t "%{buildroot}/usr/share/xconnect/files"
install -Dm 644 $HBB/res/xconnect.desktop -t "%{buildroot}/usr/share/xconnect/files"
install -Dm 644 $HBB/res/xconnect-link.desktop -t "%{buildroot}/usr/share/xconnect/files"
install -Dm 644 $HBB/res/128x128@2x.png "%{buildroot}/usr/share/icons/hicolor/256x256/apps/rustdesk.png"
install -Dm 644 $HBB/res/scalable.svg "%{buildroot}/usr/share/icons/hicolor/scalable/apps/rustdesk.svg"

%files
/usr/share/xconnect/*
/usr/share/xconnect/files/xconnect.service
/usr/share/icons/hicolor/256x256/apps/rustdesk.png
/usr/share/icons/hicolor/scalable/apps/rustdesk.svg
/usr/share/xconnect/files/xconnect.desktop
/usr/share/xconnect/files/xconnect-link.desktop

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
ln -sf /usr/share/xconnect/rustdesk /usr/bin/rustdesk
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
    rm /usr/bin/rustdesk || true
    rmdir /usr/lib/rustdesk || true
    rmdir /usr/local/rustdesk || true
    rmdir /usr/share/xconnect || true
    rm /usr/share/applications/xconnect.desktop || true
    rm /usr/share/applications/xconnect-link.desktop || true
    update-desktop-database
  ;;
  1)
    # for upgrade
    rmdir /usr/lib/rustdesk || true
    rmdir /usr/local/rustdesk || true
  ;;
esac
