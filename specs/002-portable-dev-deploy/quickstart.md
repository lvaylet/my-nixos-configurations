# Quickstart & Verification Guide: Portable Multi-Environment Development, Testing, and Deployment

**Feature**: Portable Multi-Environment Development, Testing, and Deployment (`002-portable-dev-deploy`)
**Date**: 2026-08-12
**Status**: Completed

## 1. Prerequisites

- **On Any Linux Distribution (NixOS, Ubuntu, Debian, Fedora, Arch)**:
  - Nix package manager installed (multi-user or single-user) with Flakes enabled.
  - Git and SSH client configured.
- **On macOS / Windows (WSL2)**:
  - Devbox installed: `curl -fsSL https://get.jetify.com/devbox | bash`

---

## 2. Validation Scenarios

### Scenario 1: Quick Developer Onboarding via Devbox (macOS / Linux / WSL)

Prove that any contributor on non-NixOS platforms can immediately format, lint, and validate code.

1. **Enter the Devbox environment**:

   ```bash
   devbox shell
   ```

   *Expected Outcome*: Environment activates instantly; `just`, `alejandra`, `statix`, and `deadnix` become available in `$PATH`.

2. **Execute static analysis and formatting**:

   ```bash
   just fmt
   just lint
   ```

   *Expected Outcome*: Alejandra formats `.nix` files; deadnix and statix report zero errors.

3. **Run Flake sandbox checks**:

   ```bash
   just check
   ```

   *Expected Outcome*: Flake evaluation and pre-commit checks pass in sandbox.

---

### Scenario 2: Unprivileged Non-NixOS Local Build & Verification

Prove that a non-NixOS Linux workstation can build system derivations without requiring root privileges or modifying the host OS.

1. **Build a NixOS configuration closure locally**:

   ```bash
   just build configuration="homelab"
   ```

   *Expected Outcome*: Nix evaluates and builds the `homelab` toplevel derivation into `/nix/store` and creates a `./result` symlink, without modifying host files in `/etc` or `/boot`.

2. **Attempt local switch on non-NixOS (safety guard verification)**:

   ```bash
   just switch configuration="homelab"
   ```

   *Expected Outcome*: Command detects non-NixOS environment (`/etc/NIXOS` absent) and exits cleanly with code 1, displaying an error message instructing the operator to provide a `target` host.

---

### Scenario 3: Remote Deployment to a Target NixOS Host

Prove that an operator on any Linux machine can deploy a system configuration to a remote host over SSH.

1. **Verify SSH reachability to target host**:

   ```bash
   ssh homelab "echo 'SSH connection verified'"
   ```

2. **Test configuration activation on remote target (non-switching)**:

   ```bash
   just test configuration="homelab" target="homelab"
   ```

   *Expected Outcome*: `nixos-rebuild test` executes over SSH with `--use-remote-sudo`, temporarily activating services on `homelab` without altering the bootloader entry.

3. **Deploy and permanently switch remote target**:

   ```bash
   just switch configuration="homelab" target="homelab"
   ```

   *Expected Outcome*: Configuration is built, transferred, and permanently activated as the default generation on `homelab`.

---

## 3. Reference Links

- [CLI Contract](contracts/cli-contract.md)
- [Devbox Contract](contracts/devbox-contract.md)
- [Data Model & State Transitions](data-model.md)
- [Feature Specification](spec.md)
