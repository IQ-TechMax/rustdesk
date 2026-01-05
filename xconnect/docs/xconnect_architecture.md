# XConnect Architecture & Custom Features

## Overview

XConnect is a fork of RustDesk customized for smart classroom environments where teachers and administrators connect to Linux-based projectors.

---

## Network Topology

```
                    LOCAL NETWORK                          │  INTERNET
                                                           │
  ┌──────────────────┐       UDP Broadcast                 │
  │  Teacher         │ ─────────────────────────┐          │
  │  (Android)       │                          │          │
  │                  │ ◄── TCP Response ──┐     │          │
  └──────────────────┘                    │     │          │
                                          │     ▼          │
  ┌──────────────────┐                 ┌──┴────────────┐   │  ┌─────────────────┐
  │  System Admin    │ ─── UDP ──────► │   PROJECTOR   │   │  │  Remote Support │
  │  (Windows)       │                 │   (Linux)     │◄──┼──│  (Windows/Web)  │
  │                  │ ◄── TCP ─────── │               │   │  │  via RustDesk   │
  └──────────────────┘                 └───────────────┘   │  │  Servers        │
                                              │            │  └─────────────────┘
                                              │            │          │
                                              │            │          │
                                              │            │  ┌─────────────────┐
                                              │            │  │ Your Web Server │
                                              └────────────┼─►│ (Stores MAC,    │
                                                           │  │  ID, Password)  │
                                                           │  └─────────────────┘
```

---

## Connection Modes

| Mode | Direction | Initiator | Description |
|------|-----------|-----------|-------------|
| **xCtrl** | Client → Projector | Client sends TCP | Control projector's mouse/keyboard (no screen) |
| **xCtrlView** | Client → Projector | Client sends TCP | Control projector with screen view |
| **xBoard** | Projector → Client | Client sends "TC" (Take Control) | Projector controls client, opens whiteboard |
| **xCast** | Projector → Client | Client sends "TC" (Take Control) | Projector controls client device |

### Available by Platform

| Platform | xCtrl | xCtrlView | xBoard | xCast |
|----------|-------|-----------|--------|-------|
| Android (Teacher) | ✓ | ✓ | ✓ | ✓ |
| Windows (Admin) | ✗ | ✓ | ✗ | ✓ |
| Remote Support | Standard RustDesk | | | |

---

## Port Configuration

| Port | Purpose | Used By |
|------|---------|---------|
| **64546** | UDP broadcast + TCP discovery | All platforms |
| **12345** | RustDesk direct IP access | Config override (OPTION_DIRECT_ACCESS_PORT) |

**Important:** Port 64546 must match across:
- `flutter/lib/models/device_discovery_model.dart` (line 91)
- `flutter/lib/utils/xconnect_tcp_manager.dart` (line 7)
- `flutter/lib/linux_tcp_listener/tcp_listener.dart` (linux_build)

---

## Discovery Protocol

```
1. Client (Android/Windows) broadcasts UDP every 2 seconds
   ┌─────────────────────────────────────────────┐
   │  UDP Broadcast: "XConnect Discovery"        │
   │  Destination: 255.255.255.255:PORT          │
   └─────────────────────────────────────────────┘
                          │
                          ▼
2. Projector receives UDP, responds with TCP
   ┌─────────────────────────────────────────────┐
   │  TCP Response to sender's IP                │
   │  Contains: Projector info for UI list       │
   └─────────────────────────────────────────────┘
                          │
                          ▼
3. Client shows projector in UI list
4. User clicks projector → Direct IP connection
```

---

## Branch Structure

| Branch | Platform | Purpose |
|--------|----------|---------|
| `linux_build` | Linux | Projector code (server/responder) |
| `windows_android_build` | Android/Windows | Client code (broadcaster/controller) |

---

## Custom Code Locations

### windows_android_build (Client)
- UDP broadcaster
- xConnectOptions UI widgets
- TCP manager for connection orchestration
- Connection mode logic (xBoard, xCast, xCtrl, xCtrlView)

### linux_build (Projector)
- UDP listener
- TCP responder
- ID/Password sync to web server
- Take Control (TC) handler
