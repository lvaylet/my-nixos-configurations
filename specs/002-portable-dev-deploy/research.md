# Phase 0: Research & Technical Architecture Decisions

**Feature**: Portable Multi-Environment Development, Testing, and Deployment (`002-portable-dev-deploy`)
**Date**: 2026-08-12
**Status**: Completed

## 1. Development Environment Strategy & Devbox Integration

### Decision

Provide dual-layer development environment support:

1. **Devbox (`devbox.json`)**: Declarative JSON environment for cross-platform onboarding (macOS, Windows with WSL/terminal, generic Linux distributions) without requiring manual toolchain setup.
2. **Nix Flake DevShell (`devShells.default`)**: Multi-system development shell supporting `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin` with automatic `git-hooks.nix` installation and core CLI tools (`just`, `alejandra`, `statix`, `deadnix`, `nh`).

### Rationale

- **Zero-Friction Onboarding**: Contributors on non-NixOS machines or macOS can install Devbox (`curl -fsSL https://get.jetify.com/devbox | bash`) and immediately run `devbox shell` to gain access to `just`, linters, and formatters with identical tool versions.
- **Flake DevShell Parity**: Expanding `systems` in `flake.nix` to include `aarch64-linux`, `x86_64-darwin`, and `aarch64-darwin` allows native `nix develop` users on non-Linux machines to run flake checks and formatters hermetically without modifying NixOS configurations.
- **Non-Invasive**: Does not interfere with existing NixOS module definitions or host configurations.

### Alternatives Considered

- *Docker / Dev Containers*: Rejected as primary solution due to heavy daemon overhead, slow file synchronization on macOS/Windows, and divergence from the repository's Nix-centric philosophy. Devbox leverages Nix natively without container overhead.
- *Direnv Only*: Useful for automatic shell activation, but assumes Nix is already configured with appropriate channels or flake settings. Devbox acts as a higher-level bootstrap while remaining complementary to direnv.

---

## 2. Remote Deployment Architecture & Tooling

### Decision

Utilize native `nixos-rebuild` with `--target-host` and `--use-remote-sudo` for remote operations over SSH, wrapped in parameterized `justfile` recipes (`switch`, `test`, `boot`, `build`), with graceful fallback and environment detection.

### Rationale

- **No Third-Party Flake Dependencies**: Avoids adding complex external deployment dependencies (such as `deploy-rs`, `colmena`, or `morph`) into `flake.nix`, preserving minimal inputs and zero drift risks.
- **Universal Availability**: `nixos-rebuild` is standard across Nixpkgs and can be run from any machine where Nix is installed.
- **Safe SSH Privilege Escalation**: `--use-remote-sudo` allows connecting as a regular user with SSH keys while safely executing privileged activation steps on the remote target.
- **Local / Remote Unified Interface**: By parameterizing recipes with `target=""`, local commands (`just switch`) preserve `nh os switch` behavior on native NixOS, while `just switch homelab homelab.internal` executes remote deployment.

### Alternatives Considered

- *Deploy-RS*: Powerful for parallel deployments, but introduces Rust binary dependencies, specialized schema definitions in `flake.nix`, and unnecessary complexity for personal desktop/homelab infrastructure.
- *Colmena*: Requires custom hive definitions and adds an external CLI dependency not present in standard nixpkgs devShells.
- *SSH + Remote NH*: Requires `nh` to be installed on target and requires complex remote interactive shell forwarding.

---

## 3. Cross-Platform Local Build & Testing Strategy

### Decision

Enable non-destructive building and evaluation on non-NixOS Linux workstations via `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` and flake sandbox checks (`nix flake check`).

### Rationale

- **Non-Root Safe Execution**: `nix build` evaluates and builds the NixOS derivation into `/nix/store` and creates a `./result` symlink without needing root/sudo or attempting to activate systemd units.
- **Host OS Protection**: Guards against accidental execution of `nh os switch` on non-NixOS systems (like Ubuntu or Fedora) by verifying `/etc/NIXOS` presence before attempting local profile switching.
- **CI / Headless Compatibility**: Standard Linux runners in GitHub Actions or generic servers can run `just check` and `just build <host>` to verify syntax and derivation integrity on every commit.

### Alternatives Considered

- *NixOS VM Testing (`nixos-rebuild build-vm`)*: Can be supported as an auxiliary recipe, but toplevel derivation build (`build.toplevel`) is faster and sufficient for verifying system closures.

---

## 4. SSH & Target Identity Resolution

### Decision

Support target specification via standard SSH connection strings (e.g., `target="homelab"`, `target="laurent@192.168.1.50"`, `target="homelab.lan"`), leveraging the user's existing `~/.ssh/config` or SSH agent.

### Rationale

- **Flexibility**: Works seamlessly across local LAN hostnames, Tailscale mesh hostnames (`homelab.tailnet.ts.net`), or explicit IP addresses.
- **Zero Hardcoded Secrets**: Conforms strictly to Principle IV (Zero-Secrets Leakage) by relying on external SSH keys/agents without embedding connection credentials in code.

---

## Summary of Decisions

| Area | Selected Decision | Key Benefit |
| :--- | :--- | :--- |
| **Dev Environment** | `devbox.json` + Multi-System `flake.nix` `devShells` | Fast onboarding on macOS/Linux/WSL with full tool parity |
| **Remote Deployer** | Native `nixos-rebuild --target-host --use-remote-sudo` | Standard NixOS tooling without external flake dependencies |
| **CLI Experience** | Parameterized `justfile` recipes with `/etc/NIXOS` guard | Unified commands (`just switch [config] [target]`) with local safety |
| **Non-NixOS Testing** | Direct `nix build` of `build.toplevel` | Safe, unprivileged system closure builds on any Linux host |
