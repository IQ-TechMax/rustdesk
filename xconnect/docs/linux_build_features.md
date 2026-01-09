# linux_build Branch - Complete File Changes

> [!CAUTION]
> **UNCOMMITTED SUBMODULE CHANGES**
> `libs/hbb_common/src/config.rs` changes are NOT committed!
> User has ADDITIONAL linux-specific settings in config.rs.
> See: [hbb_common_submodule_guide.md](./hbb_common_submodule_guide.md)

**Branch:** linux_build (Projector/Linux)  
**Base Version:** 1.4.2 (upstream master at 1.4.4)  
**Total Changed Files:** 101

---

## Summary by Category

| Category | Count | Notes |
|----------|-------|-------|
| Flutter Dart | 17 | Fewer than Android (no device discovery UI) |
| Rust src/ | 12 | More Rust mods than Android |
| Android Native | 18 | Rename only |
| Packaging | 23 | Desktop files, services |

---

## 🔴 UNIQUE to linux_build (Not in windows_android_build)

### flutter/lib/linux_tcp_listener/tcp_listener.dart (198 lines)
**Projector-side TCP Server - Handles client requests**

| Action | Handler | Description |
|--------|---------|-------------|
| `TC` | Lines 100-120 | Receives "Take Control" → calls `connect()` to client |
| `GC_REQUEST` | Lines 124-161 | Client wants to control projector → sends back IP/port/password |
| `CLOSE_CONNECTION` | Lines 164-170 | Closes remote connection window |

### flutter/lib/network_monitor.dart (121 lines)
**Sends projector session info to remote support API**

- API: `https://web.xwall.io/public/api/updateRemoteDetails`
- Sends: `serialnumber`, `sessionid`, `password`, `status: online`
- Receives: `deviceName` → stored via `bind.setXConnectDeviceName()`
- Triggers on network connectivity changes

### Additional Dependencies (pubspec.yaml)
```yaml
connectivity_plus: ^5.0.2   # Network change detection
device_info_plus: ^9.1.0    # Get device serial number for xwall.io API
```

### Rust Source Changes (12 files)
| File | Purpose |
|------|---------|
| `src/main.rs` | Entry point modifications |
| `src/service.rs` | Service logic |
| `src/common.rs` | Common utilities |
| `src/flutter_ffi.rs` | FFI bindings - **UNIQUE: get/set_x_connect_device_name** |
| `src/auth_2fa.rs` | 2FA |
| `src/clipboard.rs` | Clipboard |
| `src/platform/macos.rs` | macOS |
| `src/platform/privileges_scripts/*` | macOS scripts |

### Desktop/Service Files
| File | Purpose |
|------|---------|
| `flutter/lib/desktop/pages/desktop_home_page.dart` | Uses `xConnect-Logo.png` |
| `res/xconnect.desktop` | Linux desktop entry + **AUTOSTART** (installed to `/etc/xdg/autostart/`) |
| `res/xconnect-link.desktop` | Desktop shortcut (NEW) |
| `res/xconnect.service` | systemd service (NEW) |
| `res/rustdesk.desktop` | Modified |
| `res/rustdesk-link.desktop` | Modified |

### Autostart on Session Login (NEW - 2026-01-09)
XConnect automatically starts when user logs in:
- `xconnect.desktop` copied to `/etc/xdg/autostart/` during package installation
- Contains `X-GNOME-Autostart-enabled=true`
- Packaging scripts updated: `build.py`, `PKGBUILD`, all RPM specs, `DEBIAN/prerm`

### Reduced Initial Window Size (NEW - 2026-01-09)
Main window starts at 300x200 pixels for splash screen display:
- Set in `flutter/lib/main.dart` (skips `restoreWindowPosition` on Linux)
- Window is centered on screen

### flutter/lib/main.dart (275 lines added - SIGNIFICANT)
**Linux projector-specific initialization:**

```dart
// Line 47-49 - SHARED_PORT constant
final int SHARED_PORT = 64546;

// In _AppState class - TcpListener initialization
TcpListener? _tcpListener;
_tcpListener = TcpListener(port: SHARED_PORT);
_tcpListener?.start();

// NetworkMonitor initialization
NetworkMonitor.startNetworkMonitoring(currentSessionId, currentPassword, deviceId);

// UDP Discovery listener (lines 697-758)
// Binds to UDP:64546, responds via TCP:64546
```

### flutter/lib/desktop/pages/desktop_home_page.dart
**Different from windows_android_build:**
- Uses `xConnectBackground.png` (matches windows_android_build)
- Has splash screen for projector mode
- Displays device info from xwall.io API

---

## Projector Protocol Implementation

### TC Flow (Projector receives, initiates connection to client)
```
Client sends: {action: "TC", ip, port, password}
  → tcp_listener.dart receives on port XCONNECT_PORT
    → connect(context, "$ip:$port", password)
      → Opens fullscreen remote connection to client
```

### GC Flow (Client requests control, projector responds)
```
Client sends: {action: "GC_REQUEST", transaction_id}
  → tcp_listener.dart receives
    → Gets local IP, password from gFFI.serverModel
      → Responds: {action: "GC_RESPONSE", ip, port, password, ack: "GC_ACK"}
```

### Remote Support Registration
```
On network connected:
  → network_monitor.dart sends POST to xwall.io API
    → {serialnumber, sessionid, password, status: online}
      → API returns deviceName → stored locally
```

---

## libs/hbb_common/src/config.rs (UNCOMMITTED)

### Shared with windows_android_build:
```rust
// Line 46 - macOS org
pub static ref ORG: RwLock<String> = RwLock::new("com.xconnect".to_owned());

// Line 61 - App name
pub static ref APP_NAME: RwLock<String> = RwLock::new("XConnect".to_owned());

// Lines 66-71 - Default settings for direct IP access
pub static ref OVERWRITE_SETTINGS: RwLock<HashMap<String, String>> = {
    let mut map = HashMap::new();
    map.insert(keys::OPTION_DIRECT_SERVER.to_owned(), "Y".to_owned());
    map.insert(keys::OPTION_DIRECT_ACCESS_PORT.to_owned(), "12345".to_owned());
    RwLock::new(map)
};
```

### 🔴 UNIQUE to linux_build (Projector):
```rust
// Line 183 - NEW FIELD in Config struct
// Stores device name received from xwall.io API
pub struct Config {
    pub id: String,
    pub x_connect_device_name: String,  // <-- NEW LINE
    enc_id: String,
    password: String,
    // ...
}
```

This field is:
- Set by `bind.setXConnectDeviceName()` in `network_monitor.dart`
- Read by `bind.getXConnectDeviceName()` in `main.dart` (line 729)
- Received from xwall.io API response (`deviceName` field)
- Used to identify the projector in the remote support system

**Rust FFI functions (src/flutter_ffi.rs):**
```rust
// Lines 2797-2805
pub fn get_x_connect_device_name() -> String {
    config.x_connect_device_name.clone()
}

pub fn set_x_connect_device_name(value: String) {
    config.x_connect_device_name = value;
}
```

---

## Files Shared with windows_android_build

Both branches have:
- All rename changes (Cargo.toml, build.py, etc.)
- Flutter common changes (common.dart, models/, etc.)
- Android rename (com.xconnect.app)
- Packaging (res/*, flatpak/*)
- `libs/portable/app_metadata.toml` (timestamp metadata)
- `assets/xConnect-Logo.png` (55KB) - **Renamed to match v2**
- `assets/xConnect-Icon.png` (23KB) - **Renamed to match v2**
- `assets/xConnectBackground.png` (PNG) - **Standardized across branches**

---

## Merge Conflict Risk

| File | Risk | Notes |
|------|------|-------|
| `tcp_listener.dart` | 🟢 LOW | 100% new file |
| `network_monitor.dart` | 🟢 LOW | 100% new file |
| `src/*.rs` | 🔴 HIGH | Core Rust changes |
| `res/xconnect.*` | 🟢 LOW | New files |
| `desktop_home_page.dart` | 🟡 MEDIUM | Different from Android version |

---

## Sync Checklist for linux_build

- [ ] Use LLM with llm_sync_guide.md for conflict resolution
- [ ] Preserve tcp_listener.dart (100% custom)
- [ ] Preserve network_monitor.dart (100% custom)
- [ ] Merge src/*.rs carefully
- [ ] Preserve xconnect.service, xconnect.desktop
- [ ] Apply config.rs changes from local machine
- [ ] Test TC flow (client → projector)
- [ ] Test GC flow (projector → client)
- [ ] Test xwall.io API registration
