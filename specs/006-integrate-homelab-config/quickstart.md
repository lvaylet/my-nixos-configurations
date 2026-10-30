# Quickstart Validation Guide: Homelab Configuration Integration

**Branch**: `006-integrate-homelab-config` | **Date**: 2026-10-10 | **Spec**: [spec.md](spec.md)

This guide provides step-by-step procedures to validate that the homelab configuration integration satisfies all requirements, contracts, and quality gates.

---

## Prerequisites

1. Working copy of `my-nixos-configurations` on branch `006-integrate-homelab-config`.
2. Nix with Flakes enabled (`nix-command flakes`).
3. `just` task runner installed.

---

## Scenario 1: Verify Code Formatting & Static Analysis

Verify that all newly created and updated Nix expressions adhere to formatting rules and contain zero unused bindings or lint issues.

```bash
# 1. Format Nix expressions with alejandra
just fmt

# 2. Check for dead code (unused bindings) and syntax lints
just lint
```

**Expected Outcome**:

- All files format cleanly without changes needed after `just fmt`.
- `deadnix` and `statix check` complete with exit code 0 and zero warnings.

---

## Scenario 2: Validate Flake Evaluation & Derivation Graphs

Ensure that adding `disko`, `preservation`, and the updated homelab modules evaluates cleanly across all targets.

```bash
# 1. Evaluate homelab system toplevel derivation
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath

# 2. Ensure existing desktop-pc target evaluates without regression
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath

# 3. Ensure iso target evaluates without regression
nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath
```

**Expected Outcome**:

- All three commands succeed, returning valid `.drv` store paths without evaluation errors.

---

## Scenario 3: Verify Disko Partitioning Specification

Verify that the Disko schema for homelab contains the expected partition definitions and ephemeral tmpfs root.

```bash
# Inspect the generated disko root filesystem mount configuration
nix eval .#nixosConfigurations.homelab.config.fileSystems."/".fsType
# Expected output: "tmpfs"

# Inspect the persistent subvolume mountpoint
nix eval .#nixosConfigurations.homelab.config.fileSystems."/persistent".mountpoint
# Expected output: "/persistent"

# Inspect the swap device configuration
nix eval .#nixosConfigurations.homelab.config.disko.devices.disk.main.content.partitions.swap.size
# Expected output: "4G"
```

**Expected Outcome**:

- Root filesystem is `tmpfs`.
- `/persistent` and `/nix` are mounted as btrfs subvolumes.
- Swap partition is configured with `4G`.

---

## Scenario 4: Verify Declarative State Preservation Entries

Verify that both system-wide and service-colocated preservation rules are populated on `homelab`.

```bash
# Check system preservation directories
nix eval .#nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories

# Check that service-specific paths (e.g. containers, jellyfin, filebrowser) are present in the list
nix eval --raw .#nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories | grep -E "containers|jellyfin|filebrowser|downloads"
```

**Expected Outcome**:

- Returns the full list of persistent directories including `/var/lib/containers`, `/var/lib/jellyfin`, `/var/lib/filebrowser`, `/data/downloads`, and `/data/media`.

---

## Scenario 5: Verify Homelab Services & Permissions

Verify that all expected services are enabled, legacy services are excluded, and multimedia permissions are enforced.

```bash
# Verify OCI containers
nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.filebrowser.image
# Expected output: "ghcr.io/gtsteffaniak/filebrowser:latest"

nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.homeassistant.image
# Expected output: "ghcr.io/home-assistant/home-assistant:2026.5.3"

nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.portainer.image
# Expected output: "docker.io/portainer/portainer-ce:lts"

# Verify native services
nix eval .#nixosConfigurations.homelab.config.services.jellyfin.enable
# Expected output: true

nix eval .#nixosConfigurations.homelab.config.services.qbittorrent.enable
# Expected output: true

nix eval .#nixosConfigurations.homelab.config.programs.nix-ld.enable
# Expected output: true

# Verify excluded services are disabled
nix eval .#nixosConfigurations.homelab.config.services.adguardhome.enable
# Expected output: false
```

**Expected Outcome**:

- All source repository services evaluate to `true` with their configured container images or native service options.
- Legacy services like `adguardhome` evaluate to `false`.

---

## Scenario 6: Run Repository Quality Check (Hermetic Sandbox)

Execute the full suite of automated pre-commit and flake checks in an isolated sandbox.

```bash
just check
```

**Expected Outcome**:

- All git hooks and flake check derivations succeed with exit code 0.
