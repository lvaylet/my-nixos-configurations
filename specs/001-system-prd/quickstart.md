# Quickstart & Validation Guide: Core System PRD

**Feature**: `001-system-prd`
**Status**: Ready for Validation

## Overview

This guide provides step-by-step procedures to validate all core functional capabilities, quality gates, and multi-machine deployment workflows defined in the PRD.

---

## Prerequisites

- Operating System: Linux (NixOS or Linux with Nix installed and flakes enabled)
- Required Tools: `nix` (2.18+), `just`, `git`
- Access: Sudo permissions for switching NixOS generations

---

## Validation Scenarios

### Scenario 1: Quality Gate & Secret Scan Verification

Validate that all Nix expressions pass static analysis, formatting, and secret scanning hermetically.

```bash
# 1. Format all Nix files
just fmt

# 2. Run static analysis and dead-code detection
just lint

# 3. Execute hermetic sandboxed pre-commit checks
just check
```

**Expected Outcome**:

- All files format with zero syntax issues.
- `statix` and `deadnix` report 0 warnings or errors.
- `nix flake check` completes successfully, confirming zero unencrypted secrets or private keys in the tree.

---

### Scenario 2: Non-Switching Configuration Testing

Validate pending configuration changes on the current host without altering the default bootloader generation.

```bash
# Rebuild and activate configuration in current session
just test configuration="desktop-pc"
```

**Expected Outcome**:

- `nh os test` builds the target derivation and activates new services/environment settings in the running session.
- Bootloader default generation remains unchanged.

---

### Scenario 3: Live System Deployment & Rollback Readiness

Deploy the configuration permanently as a new generation and verify bootloader registration.

```bash
# 1. Build and switch to the new generation
just switch configuration="desktop-pc"

# 2. Check current generations
nh os list
```

**Expected Outcome**:

- System switches to the new generation.
- A new numbered entry is recorded in the `Limine` bootloader menu.
- Rebooting presents the new generation with previous generations accessible for <60s rollback.

---

### Scenario 4: Headless Server Configuration Verification

Evaluate and build the headless homelab server profile.

```bash
# Build the homelab configuration derivation without activating on current host
nh os build .#homelab
```

**Expected Outcome**:

- Derivation builds successfully with background services (Jellyfin, Home Automation, AdGuard Home) and headless configuration.

---

### Scenario 5: Rescue & Installation ISO Generation

Build the standalone minimal rescue ISO image.

```bash
just build-iso
```

**Expected Outcome**:

- A bootable `.iso` file is produced in `result/iso/*.iso` containing pre-authorized SSH keys and networking tools.

---

### Scenario 6: Storage Reclamation & Garbage Collection

Reclaim disk space by purging old generations according to the retention policy.

```bash
# 1. Clean old user generations, keeping at least 1
just clean keep="1"

# 2. Clean all profile generations and collect garbage
just clean-all keep="1"
```

**Expected Outcome**:

- Obsolete profile generations are deleted and unreferenced store paths in `/nix/store` are safely reclaimed.
