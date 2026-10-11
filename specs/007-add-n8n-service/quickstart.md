# Quickstart Validation Guide: n8n Workflow Automation Service for Homelab

**Branch**: `007-add-n8n-service` | **Date**: 2026-10-11 | **Spec**: [spec.md](spec.md)

This guide provides step-by-step procedures to validate that the n8n automation service integration satisfies all requirements, contracts, and quality gates.

---

## Prerequisites

1. Working copy of `my-nixos-configurations` on branch `007-add-n8n-service`.
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
- All files format cleanly without modifications needed after `just fmt`.
- `deadnix` and `statix check` complete with exit code 0 and zero warnings.

---

## Scenario 2: Validate Flake Evaluation & Derivation Graphs

Ensure that adding the `n8n` service evaluates cleanly across all targets without regression.

```bash
# 1. Evaluate homelab system toplevel derivation
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath

# 2. Ensure existing desktop-pc target evaluates without regression
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath

# 3. Ensure iso target evaluates without regression
nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath
```

**Expected Outcome**:
- All three evaluation commands succeed, returning valid `.drv` store paths without evaluation errors.

---

## Scenario 3: Verify n8n Container & Environment Configuration

Inspect the evaluated container configuration for the n8n service on `homelab`.

```bash
# Verify container image
nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.n8n.image
# Expected output: "docker.io/n8nio/n8n:latest"

# Verify port bindings
nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.n8n.ports
# Expected output: [ "5678:5678" ]

# Verify timezone configuration
nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.n8n.environment.GENERIC_TIMEZONE
# Expected output: "Europe/Paris"

# Verify volume bindings
nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.n8n.volumes
# Expected output: [ "/var/lib/n8n:/home/node/.n8n" ]
```

**Expected Outcome**:
- All container attributes match the specification in [contracts/n8n-service-contract.md](contracts/n8n-service-contract.md).

---

## Scenario 4: Verify Firewall Configuration

Ensure TCP port 5678 is opened in the host firewall.

```bash
nix eval .#nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts
```

**Expected Outcome**:
- Output includes `5678` in the allowed TCP port list.

---

## Scenario 5: Verify Declarative State Preservation for n8n

Ensure `/var/lib/n8n` is preserved across reboots under `/persistent`.

```bash
nix eval .#nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories
```

**Expected Outcome**:
- Output contains an entry for `/var/lib/n8n` with user `1000`, group `1000`, and mode `0750`.

---

## Scenario 6: Run Repository Quality Check (Hermetic Sandbox)

Execute the full suite of automated pre-commit and flake checks in an isolated sandbox.

```bash
just check
```

**Expected Outcome**:
- All git hooks and flake check derivations succeed with exit code 0.
