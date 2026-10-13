# Technical Research: Enable Bluetooth Connectivity on Desktop-PC

**Branch**: `010-enable-desktop-bluetooth` | **Date**: 2026-10-13 | **Spec**: [spec.md](spec.md)

This document consolidates architectural research, technology decisions, integration patterns, and best practices for enabling Bluetooth connectivity on `desktop-pc` within the dendritic NixOS configuration.

---

## 1. Architectural Placement & Dendritic Domain Organization

### Decision

Place the Bluetooth configuration in a dedicated dendritic service module at `modules/services/bluetooth.nix` exposing `flake.modules.services.bluetooth`, and compose it into `modules/hosts/desktop-pc.nix` within its `features` list.

### Rationale

- **Constitution Alignment (Principle II)**: The repository enforces the Dendritic Pattern with four primary domains under `modules/`: `core/`, `desktop/`, `services/`, and `hosts/`.
- **System Daemons Domain**: The `services/` domain encapsulates hardware daemons, networking, and system services (e.g., `services.network`, `services.printing`, `services.ssd`). Bluetooth is fundamentally a system-wide radio hardware daemon (`bluez`) managed by systemd and D-Bus.
- **Selective Host Composition**: Placing Bluetooth in `modules/services/bluetooth.nix` allows clean host-level opt-in (`modules/hosts/desktop-pc.nix`) without burdening headless server targets (`modules/hosts/homelab.nix`) or minimal rescue targets (`modules/hosts/iso.nix`) with unnecessary wireless daemons or user utilities.
- **Zero-Boilerplate Discovery**: Files under `modules/` are discovered automatically via `import-tree ./modules`, requiring no manual import wiring in `flake.nix`.

### Alternatives Considered

- **Inlining in `modules/hosts/desktop-pc.nix` via `extraModules`**: Rejected because Constitution Principle II strictly forbids inline service definitions within host declarations.
- **Colocating in `modules/desktop/audio.nix` or `modules/services/network.nix`**: Rejected because Bluetooth encompasses more than audio (e.g., HID mice, keyboards, game controllers) and is functionally distinct from IP networking / NetworkManager. A modular single-responsibility file adheres better to dendritic principles.
- **Placing in `modules/desktop/bluetooth.nix`**: While Bluetooth on this machine serves desktop workflows, the underlying implementation is a system daemon (`bluez`) with D-Bus system bus policies, matching `modules/services/printing.nix` and `modules/services/network.nix`.

---

## 2. Core Bluetooth Subsystem & Controller Management

### Decision

Enable the BlueZ stack declaratively via `hardware.bluetooth.enable = true` and `hardware.bluetooth.powerOnBoot = true`, and configure BlueZ policy settings to enable experimental features and automatic controller powering:

```nix
hardware.bluetooth = {
  enable = true;
  powerOnBoot = true;
  settings = {
    General = {
      Experimental = true;
    };
    Policy = {
      AutoEnable = true;
    };
  };
};
```

### Rationale

- **Canonical NixOS Option**: `hardware.bluetooth.enable = true` is the official NixOS option that installs the `bluez` package, configures the `bluetooth.service` systemd unit, and installs necessary D-Bus permissions.
- **Startup Reliability (`powerOnBoot`)**: `powerOnBoot = true` ensures that the default Bluetooth adapter is powered on during boot without requiring the user to execute manual `rfkill unblock bluetooth` or `bluetoothctl power on` commands.
- **Battery Reporting (`General.Experimental = true`)**: BlueZ experimental mode enables the GATT Battery Service, allowing desktop environments, shell bars (Noctalia), and Bluetooth manager utilities to display the battery percentage of connected wireless headsets, mice, and keyboards.
- **Auto-Enable Policy (`Policy.AutoEnable = true`)**: Ensures controllers detected hot-plugged (such as USB Bluetooth adapters) or initialized after sleep/resume cycles are automatically switched to an active, powered state.

### Alternatives Considered

- **Omitting `settings.General.Experimental`**: Leaves wireless peripheral battery levels hidden from the user interface and desktop status bars.
- **Manual imperative controller management via CLI scripts**: Violates Constitution Principle I (Declarative & Hermetic Configuration).

---

## 3. Desktop Integration & Peripheral Management Utilities

### Decision

Enable Blueman via `services.blueman.enable = true` to provide graphical management utilities, desktop notifications, and polkit authorization rules, alongside standard BlueZ CLI utilities (`bluetoothctl`).

### Rationale

- **Complete Management Suite**: `services.blueman.enable = true` installs `blueman-manager` (full GTK management window), `blueman-applet` (system tray applet for quick connect/disconnect), and the `blueman-mechanism` D-Bus daemon.
- **Unprivileged User Control**: The NixOS Blueman module automatically provisions polkit policies that grant interactive users in the `wheel` group permission to scan, pair, trust, and connect devices without root password prompts.
- **CLI Accessibility**: Standard `bluetoothctl` is provided natively by `bluez` (via `hardware.bluetooth.enable`), satisfying power users and terminal workflows.
- **Wayland & Noctalia Compatibility**: `blueman-manager` runs natively under Wayland (Niri) using standard GTK3/Wayland backends, and `blueman-applet` integrates with system tray protocols.

### Alternatives Considered

- **CLI-Only Configuration (`bluez` alone without Blueman)**: Lacks graphical pairing dialogs, PIN confirmation popups, and desktop tray integration, degrading the workstation user experience.
- **Desktop-Environment-Specific Tools (GNOME Control Center / KDE Bluedevil)**: Heavily bloated with unwanted desktop dependencies incompatible with the lightweight Niri + Noctalia desktop stack.

---

## 4. Audio Routing Integration (PipeWire / WirePlumber)

### Decision

Rely on existing PipeWire and WirePlumber infrastructure in `modules/desktop/audio.nix` without additional configuration.

### Rationale

- **Native BlueZ Integration**: In NixOS, PipeWire's session manager WirePlumber natively detects when `hardware.bluetooth.enable = true` and enables SPA (Simple Plugin Architecture) BlueZ 5 audio plugins (`spa-bluez5`).
- **Codec & Profile Support**: WirePlumber automatically handles Bluetooth audio profiles (A2DP for high-fidelity audio playback, HFP/HSP for two-way headset voice communication) and auto-switches active audio endpoints to newly connected Bluetooth audio devices.
- **Existing Audio Configuration**: `modules/desktop/audio.nix` already configures PipeWire with RTKit and PulseAudio emulation (`services.pipewire.pulse.enable = true`), which Bluetooth audio clients consume seamlessly.

### Alternatives Considered

- **Adding custom WirePlumber Lua/JSON configuration files**: Unnecessary overhead; upstream NixOS and WirePlumber defaults correctly prioritize Bluetooth sinks and handle standard codecs (SBC, AAC, LDAC, aptX) out of the box.

---

## 5. Pairing Key Persistence & State Storage

### Decision

Leverage the default `/var/lib/bluetooth` directory, which is already registered in `modules/core/preservation.nix`.

### Rationale

- **Standard Storage Location**: BlueZ stores all adapter keys, remote device link keys, PINs, and device trust configurations under `/var/lib/bluetooth/<adapter-mac>/`.
- **Pre-existing Preservation**: `modules/core/preservation.nix` already specifies `/var/lib/bluetooth` under its persistent directory list, ensuring pairing data is preserved across system reboots on machines using ephemeral root filesystems.
- **Standard Root Ownership**: Directory permissions (`0700` owned by `root:root`) are managed directly by BlueZ and the systemd unit.

### Alternatives Considered

- **Custom state paths**: Deviates from upstream Linux standards and breaks third-party tools expecting `/var/lib/bluetooth`.
