# Technical Research: Integrate MacBook Air M4 Host and Mutualize Shared Configurations

**Feature**: `021-integrate-macbook-air`
**Status**: Completed
**Date**: 2026-10-21

---

## 1. System Management Framework on macOS (Apple Silicon M4)

### Context

The MacBook Air M4 runs macOS Sonoma/Sequoia on Apple Silicon (`aarch64-darwin`). The repository currently defines NixOS systems (`x86_64-linux`) using `inputs.nixpkgs.lib.nixosSystem` wrapped in `mkHost`. We need a declarative mechanism to manage the host at both system and user levels while maximizing code reuse.

### Decision

Adopt **`nix-darwin`** (`github:LnL7/nix-darwin`) paired with **Home Manager** (`github:nix-community/home-manager`), integrated via a new helper `config.flake.lib.mkDarwinHost` in `modules/core/lib.nix`.

### Rationale

- `nix-darwin` provides native declarative control over macOS system settings (dock, trackpad, hostname, nix-daemon settings, garbage collection, and PAM Touch ID for sudo) while managing `/run/current-system`.
- Home Manager embeds seamlessly within `nix-darwin` via `inputs.home-manager.darwinModules.home-manager`, exactly mirroring how `inputs.home-manager.nixosModules.home-manager` works in `nixosSystem`.
- This ensures 100% parity with the dendritic composition model in `modules/core/lib.nix`: feature modules can export `homeManager` blocks that are evaluated identically on both NixOS (`desktop-pc`) and macOS (`macbook-air-m4-15`).

### Alternatives Considered

- **Home Manager standalone (`homeConfigurations.macbook-air-m4-15`)**:
  - *Pros*: Does not require root permissions or `nix-darwin`.
  - *Cons*: Cannot manage macOS system settings, cannot configure Nix daemon settings (`trusted-users`, `experimental-features`) system-wide, cannot manage Touch ID for `sudo`, and breaks parity with the host declaration style used across the repo.
- **Asahi Linux on MacBook Air M4**:
  - *Pros*: Runs standard NixOS.
  - *Cons*: As of 2026, Apple Silicon M4 Linux support is in early experimental bringup; everyday drivers (audio, display, power management) are incomplete. The user specifically acquired a MacBook Air running macOS.

---

## 2. Dendritic Module Pattern & Cross-Platform Slicing

### Context

Constitution Principle II dictates that capabilities are organized into domain-grouped features under `modules/` (`core/`, `desktop/`, `services/`). We must support both NixOS and Darwin targets without duplicating module files or breaking `import-tree ./modules`.

### Decision

Extend the module contract so that each dendritic feature module can optionally export:

- `nixos`: NixOS-specific configuration (consumed by `mkHost`).
- `darwin`: macOS/nix-darwin-specific configuration (consumed by `mkDarwinHost`).
- `homeManager`: cross-platform user-level configuration (consumed by both `mkHost` on `desktop-pc` and `mkDarwinHost` on `macbook-air-m4-15`).

In `modules/core/lib.nix`:

- `mkHost` extracts `f.nixos` and `f.homeManager`.
- `mkDarwinHost` extracts `f.darwin` and `f.homeManager`.

### Rationale

- Zero file duplication: A single file like `modules/desktop/shell.nix` or `modules/core/git.nix` remains the single source of truth for both Linux and macOS.
- Total backward compatibility: Existing NixOS modules without a `darwin` block simply contribute nothing to Darwin's system layer, but their `homeManager` block is reused immediately.
- Fully compatible with `import-tree ./modules` and `flake-parts`.

### Alternatives Considered

- **Separate OS directory trees (`modules/darwin/` vs `modules/nixos/`)**:
  - Rejected: Violates Constitution Principle II by reintroducing directory silos and preventing colocation of user dotfiles and shared toolchains.
- **Conditional OS branches inside a single untyped module**:
  - Rejected: Mixing `pkgs.stdenv.isDarwin` checks everywhere within a single monolithic NixOS module leads to messy code and evaluation warnings. Slicing into explicit `nixos`, `darwin`, and `homeManager` keys provides clean separation of concerns.

---

## 3. Mutualization & Portability Audit of Existing Modules

### Findings & Adaptations

| Module | Current Scope | Target Scope on `macbook-air-m4-15` | Action / Adaptation Required |
| --- | --- | --- | --- |
| `core.vars` | Global options (`config.flake.vars`) | Shared (100%) | None. Fully platform-agnostic. |
| `core.base` | `nixos` (Limine, Nix GC, users, shellAliases) | Add `darwin` block | Declare macOS system defaults, nix daemon settings (`flakes`), user account home (`/Users/laurent`), Touch ID sudo. |
| `core.git` | `homeManager` (git + lazygit) | Shared (100%) | None. Fully portable. |
| `core.neovim` | `nixos` (`systemd.tmpfiles.rules`, packages) | Add `darwin` & `homeManager` support | On Darwin/HM, link `dotfiles/nvim` via `xdg.configFile."nvim".source = ./dotfiles/nvim;` and install CLI runtime packages (`ripgrep`, `fd`, `tree-sitter`, etc.). Preserve `systemd.tmpfiles.rules` on NixOS for headless `homelab`. |
| `desktop.shell` | `homeManager` (Fish, Starship, aliases) | Shared (100%) | None. Fish, Starship, and all aliases (`eza`, `bat`, `yazi`, `btop`) work out of the box on macOS. |
| `desktop.terminal` | `homeManager` (WezTerm) | Shared (100%) | Make `enable_wayland = true` conditional on Linux (`lib.optionalAttrs pkgs.stdenv.isLinux`). Font and Nord theme remain identical. |
| `desktop.editors` | `homeManager` (VS Code, `wl-clipboard`) | Shared (100%) | Guard `wl-clipboard` with `lib.optionals pkgs.stdenv.isLinux [ pkgs.wl-clipboard ]`. VS Code settings and extensions are 100% portable. |
| `desktop.fonts` | `homeManager` (Nerd Fonts, fontconfig) | Shared (100%) | Install fonts via packages; guard `fonts.fontconfig.enable = pkgs.stdenv.isLinux;` (macOS handles fonts in `~/Library/Fonts`). |
| `desktop.apps` | `nixos` (libinput) + `homeManager` (CLI tools + GUI) | Shared CLI tools & Ghostty | Guard Linux disk utilities (`efibootmgr`, `gptfdisk`, `parted`, `tparted`) with `lib.optionals pkgs.stdenv.isLinux`. Ghostty, Obsidian, and all CLI tools (`bat`, `btop`, `eza`, `fzf`, `jq`, `ripgrep`, `yazi`, `just`, `direnv`) work identically on macOS. |
| `desktop.session` | `nixos` (Niri, Greetd) + `homeManager` (Noctalia) | Linux-only | Excluded from `macbook-air-m4-15`. macOS uses native WindowServer/Quartz. |
| `desktop.graphics` | `nixos` (Nvidia, Xserver, Linux kernel) | Linux-only | Excluded from `macbook-air-m4-15`. M4 uses Apple Silicon Metal GPU. |
| `desktop.audio` | `nixos` (PipeWire) | Linux-only | Excluded from `macbook-air-m4-15`. macOS uses CoreAudio. |
| `services.ssh` | `nixos` (OpenSSH daemon) + `homeManager` (client config) | Shared client config | `homeManager` block is imported, instantly giving `macbook-air-m4-15` the `ssh homelab` alias (`192.168.1.180`, `laurent`, `id_ed25519`). |
| `services.*` (homelab) | Caddy, Jellyfin, AdGuard, n8n, etc. | Server-only (`homelab`) | Excluded from `macbook-air-m4-15`. Laptop acts as client over LAN/Tailscale. |

---

## 4. Build, Activation & Deployment Workflows

### Context

On NixOS, rebuilding is handled via `nh os switch .#<host>` or `nixos-rebuild switch`.
On macOS with `nix-darwin`, the toolchain uses `darwin-rebuild switch --flake .#macbook-air-m4-15` or `nix run nix-darwin -- switch --flake .#macbook-air-m4-15`.

### Decision

1. Flake output: Expose `flake.darwinConfigurations.macbook-air-m4-15`.
2. Justfile integration: Add a dedicated recipe `switch-darwin configuration="macbook-air-m4-15"` and `test-darwin configuration="macbook-air-m4-15"` (or update `switch`/`build` to detect Darwin).
3. Parity in `README.md`: Provide both Bash and Fish snippets for switching and updating the MacBook Air M4.
