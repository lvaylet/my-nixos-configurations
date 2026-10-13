# Data Model: Enable Bluetooth Connectivity on Desktop-PC

**Branch**: `010-enable-desktop-bluetooth` | **Date**: 2026-10-13 | **Spec**: [spec.md](spec.md)

This document formalizes the entities, configuration schemas, attributes, relationships, and state lifecycles for the Bluetooth subsystem on `desktop-pc`.

---

## 1. Entities & Configuration Schemas

### Entity 1: Bluetooth Feature Module (`modules/services/bluetooth.nix`)

Represents the dendritic feature module declaring the declarative NixOS system configuration for BlueZ and Blueman.

| Scope | Option / Attribute | Type | Purpose |
| --- | --- | --- | --- |
| **Dendritic Identification** | `flake.modules.services.bluetooth` | Attrset `{ nixos }` | Exported module discovered via `import-tree ./modules` |
| **BlueZ Core Daemon** | `nixos.hardware.bluetooth.enable` | `bool` (`true`) | Installs BlueZ, enables `bluetooth.service`, sets D-Bus configuration |
| | `nixos.hardware.bluetooth.powerOnBoot` | `bool` (`true`) | Powers on default adapter during system boot |
| | `nixos.hardware.bluetooth.settings.General.Experimental` | `bool` (`true`) | Enables GATT battery reporting and experimental features |
| | `nixos.hardware.bluetooth.settings.Policy.AutoEnable` | `bool` (`true`) | Automatically powers on hot-plugged/detected controllers |
| **Desktop Manager** | `nixos.services.blueman.enable` | `bool` (`true`) | Installs Blueman GTK manager, applet, D-Bus mechanism, and polkit policies |

---

### Entity 2: Host Feature Composition (`modules/hosts/desktop-pc.nix`)

Represents the composition of enabled feature modules for the `desktop-pc` machine target.

| Attribute | Schema Type | Target Value | Validation Rule |
| --- | --- | --- | --- |
| `features` | `listOf flakeModule` | Includes `services.bluetooth` | Composed in `desktop-pc.nix`; absent in `homelab.nix` |
| `hardware` | `path` | `./_hardware/desktop-pc.nix` | Hardware definition providing PCI/USB bus controllers |

---

### Entity 3: Bluetooth Controller (Physical / Logical Adapter)

Represents the local wireless radio hardware detected on `desktop-pc` (managed via BlueZ `hci0`, etc.).

| Property | Type | Description |
| --- | --- | --- |
| `Address` | `string` (MAC) | Physical Bluetooth MAC address of the local adapter |
| `Name` | `string` | Local friendly name (defaults to system hostname or BlueZ default) |
| `Powered` | `boolean` | Current power state of the radio (`true` when active) |
| `Discoverable` | `boolean` | Whether nearby devices can discover this controller |
| `Pairable` | `boolean` | Whether incoming pairing requests are permitted |
| `Discovering` | `boolean` | Whether actively scanning for nearby Bluetooth peripherals |

---

### Entity 4: Paired Peripheral (Remote Device)

Represents an external wireless device (headset, keyboard, mouse) that has paired with the host.

| Property | Type | Description |
| --- | --- | --- |
| `Address` | `string` (MAC) | Unique MAC address of the remote peripheral |
| `Name` | `string` | Human-readable peripheral name advertised by the device |
| `Icon` | `string` | Device category icon (e.g., `audio-headset`, `input-keyboard`, `input-mouse`) |
| `Paired` | `boolean` | Whether cryptographic link keys exist between device and host |
| `Trusted` | `boolean` | Whether the device is permitted to automatically reconnect |
| `Connected` | `boolean` | Active radio connection state |
| `BatteryPercentage` | `integer (0-100)` (Optional) | Battery percentage reported via GATT Battery Service |
| `UUIDs` | `listOf string` | Service UUIDs advertised (e.g., A2DP Sink, AVRCP, HFP, HID) |

---

### Entity 5: Audio Endpoint (PipeWire / WirePlumber Sink/Source)

Represents a dynamic audio stream destination or input node representing a connected Bluetooth audio device.

| Property | Type | Description |
| --- | --- | --- |
| `NodeID` | `integer` | Dynamic WirePlumber / PipeWire audio node ID |
| `MediaClass` | `string` | `Audio/Sink` (speakers/headphones) or `Audio/Source` (microphone) |
| `DeviceAPI` | `string` | `bluez5` |
| `ActiveProfile` | `string` | Active audio profile (`a2dp-sink`, `headset-head-unit`) |
| `Volume` | `float (0.0 - 1.0+)` | Output volume level controlled via desktop audio |
| `Muted` | `boolean` | Audio mute state |

---

### Entity 6: Persistent State Storage (`/var/lib/bluetooth`)

Represents the filesystem persistence of BlueZ cryptographic keys and device configurations.

| Path | Ownership | Permissions | Purpose |
| --- | --- | --- | --- |
| `/var/lib/bluetooth/<adapter-mac>/` | `root:root` | `0700` | Adapter settings and paired device directories |
| `/var/lib/bluetooth/<adapter-mac>/<device-mac>/info` | `root:root` | `0600` | Device link key, trust status, name, and supported UUIDs |

---

## 2. State Lifecycles & State Transitions

### Bluetooth Controller State Lifecycle

```text
[ Uninitialized / Offline ]
            │
            ▼ (System Boot / Module Active)
    [ Initializing ]
            │
            ▼ (powerOnBoot = true)
     [ Powered / Idle ] ◄────────────────────────┐
       │              ▲                          │
       │ (Start Scan) │ (Stop Scan / Timeout)    │ (Disconnect / Idle)
       ▼              │                          │
   [ Scanning / Discovering ]                    │
       │                                         │
       ▼ (Initiate Connection / Pair)            │
   [ Connected / Active ] ───────────────────────┘
```

### Peripheral Pairing Lifecycle

```text
  [ Unknown / Nearby ]
            │
            ▼ (Initiate Scan)
      [ Discovered ]
            │
            ▼ (Request Pair & Authenticate)
      [ Pairing ]
            │
            ▼ (Pair Succeeded & Mark Trusted)
  [ Trusted & Paired ] ◄─────────────────────────┐
            │                                    │
            ▼ (Connect Link)                     │ (Disconnect / Out of Range)
   [ Connected (Active) ]                        │
            │                                    │
            ▼ (Expose Audio Sink / HID Input)    │
   [ Operational Peripheral ] ───────────────────┘
```
