# Quickstart Validation Guide: Enable Bluetooth Connectivity on Desktop-PC

**Branch**: `010-enable-desktop-bluetooth` | **Date**: 2026-10-13 | **Spec**: [spec.md](spec.md)

This guide provides runnable step-by-step validation procedures to verify that the Bluetooth subsystem is correctly configured, evaluated, and isolated on `desktop-pc`.

---

## Prerequisites

1. Working copy of `my-nixos-configurations` on branch `010-enable-desktop-bluetooth`.
2. Nix with Flakes enabled (`nix-command flakes`).
3. `just` task runner installed.

---

## Scenario 1: Verify Evaluated NixOS Bluetooth Options on `desktop-pc`

Verify that `hardware.bluetooth` and `services.blueman` options evaluate to enabled states with expected configuration attributes on `desktop-pc`.

```bash
# 1. Verify Bluetooth core enablement
nix eval .#nixosConfigurations.desktop-pc.config.hardware.bluetooth.enable

# 2. Verify power on boot
nix eval .#nixosConfigurations.desktop-pc.config.hardware.bluetooth.powerOnBoot

# 3. Verify experimental mode (battery reporting)
nix eval .#nixosConfigurations.desktop-pc.config.hardware.bluetooth.settings.General.Experimental

# 4. Verify controller auto-enable policy
nix eval .#nixosConfigurations.desktop-pc.config.hardware.bluetooth.settings.Policy.AutoEnable

# 5. Verify Blueman management service enablement
nix eval .#nixosConfigurations.desktop-pc.config.services.blueman.enable
```

**Expected Outcome**:

- All five commands return `true`.

---

## Scenario 2: Verify Headless Server Isolation on `homelab`

Verify that headless server configurations (such as `homelab`) remain unburdened by Bluetooth services.

```bash
# 1. Verify Bluetooth is disabled on homelab
nix eval .#nixosConfigurations.homelab.config.hardware.bluetooth.enable

# 2. Verify Blueman is disabled on homelab
nix eval .#nixosConfigurations.homelab.config.services.blueman.enable
```

**Expected Outcome**:

- Both commands return `false`.

---

## Scenario 3: Verify Clean System Build & Derivation Evaluation

Verify that the `desktop-pc` top-level system derivation evaluates without warnings or failures.

```bash
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath
```

**Expected Outcome**:

- Outputs a valid `.drv` path in `/nix/store/`.
- Stderr contains zero warnings or errors.

---

## Scenario 4: Verify Formatting & Static Analysis Quality Gates

Ensure that the new `modules/services/bluetooth.nix` and updated `modules/hosts/desktop-pc.nix` adhere to repository code hygiene and formatting rules.

```bash
# 1. Run alejandra formatting
just fmt

# 2. Run static analysis (statix) and dead code detection (deadnix)
just lint
```

**Expected Outcome**:

- `just fmt` passes cleanly with no diff.
- `just lint` completes with exit code 0 and zero warnings.

---

## Scenario 5: Run Pre-Commit Checks & Flake Integrity

Run all isolated pre-commit checks to confirm flake integrity.

```bash
just check
```

**Expected Outcome**:

- All git-hooks checks pass with exit code 0.

---

## Scenario 6: Interactive Peripheral Pairing Validation (Post-Activation)

After safe system profile activation (`just test configuration="desktop-pc"`), verify runtime Bluetooth operation.

```bash
# 1. Check systemd Bluetooth service status
systemctl status bluetooth

# 2. Inspect controller status via CLI
bluetoothctl show

# 3. Scan for nearby devices
bluetoothctl scan on

# 4. Pair, trust, and connect a test peripheral (MAC: XX:XX:XX:XX:XX:XX)
bluetoothctl pair XX:XX:XX:XX:XX:XX
bluetoothctl trust XX:XX:XX:XX:XX:XX
bluetoothctl connect XX:XX:XX:XX:XX:XX

# 5. Verify audio sink presence (for audio devices) via WirePlumber
wpctl status
```

**Expected Outcome**:

- `bluetooth.service` is active and running.
- `bluetoothctl show` indicates `Powered: yes`.
- Nearby devices are discovered with names.
- Paired audio device appears as an available Sinks node in `wpctl status`.
