# Contract: Host Provisioning Runbooks

**Feature Branch**: `040-reorganize-readme`

**Created**: 2026-11-03

**Target Directory**: `docs/hosts/`

---

## 1. `docs/hosts/macbook.md` Contract

- **Target Host**: `macbook-air-m4-15` (`aarch64-darwin`)
- **Breadcrumb Header**: `[← Back to README](../../README.md)`
- **Mandatory Sections**:
  1. **Overview & Shared Capabilities**:
     - System scope, parity with `desktop-pc` (Fish, Neovim, WezTerm, Ghostty, OpenCode, VS Code).
     - Platform separation (no Linux Wayland compositors or server daemons).
  2. **Initial Provisioning (First-Time Bootstrap)**:
     - Step 1: Install Command Line Tools & Nix (`xcode-select --install` and Determinate Nix Installer).
     - Step 2: Initialize `/etc/synthetic.conf` for `/run` (Bash and Fish variants with tab character requirements, `apfs.util -t`).
     - Step 3: Initial `nix-darwin` bootstrap and system activation (Bash and Fish variants).
  3. **Routine Maintenance & Daily Operations**:
     - Explanations and commands for `just build`, `just test`, `just switch`, and rollback via `sudo darwin-rebuild --rollback` (both Bash and Fish blocks).
  4. **Client Access to Homelab Services**:
     - Tailscale SSH keyless access (`tailscale ssh laurent@homelab`).
     - LAN SSH alias (`ssh homelab`).
     - Browser web endpoints on private tailnet.

---

## 2. `docs/hosts/homelab.md` Contract

- **Target Host**: `homelab` (`x86_64-linux`)
- **Breadcrumb Header**: `[← Back to README](../../README.md)`
- **Mandatory Sections**:
  1. **Overview & Impermanent Architecture**:
     - Mini PC hardware profile, ephemeral root on `tmpfs`, Btrfs subvolumes (`/persistent`, `/nix`).
     - Preservation mechanism via `github:nix-community/preservation`.
  2. **Initial Headless Bootstrap**:
     - Step 1: Build Custom Installer ISO with pre-baked SSH public keys (`just build-iso`).
     - Step 2: Flash and boot hardware.
     - Step 3: Remote installation via `nixos-anywhere` (`just install "${TARGET_IP}"` - Bash and Fish blocks).
  3. **Post-Installation & Subsequent Updates**:
     - First SSH login as `laurent` (Fish) or `root` (Bash).
     - Testing and switching updates locally on host (`just test`, `just switch`).
     - Testing and switching updates remotely over SSH (`just test homelab`, `just switch homelab` - Bash and Fish blocks).

---

## 3. Invariants

- All code blocks with shell-specific syntax MUST provide explicit **Bash** and **Fish** tabs/blocks.
- All relative paths MUST be valid from the `docs/hosts/` subfolder.
- Must pass `just lint-md` with zero warnings.
