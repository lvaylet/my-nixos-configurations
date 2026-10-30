# Implementation Plan: Shared System-Level Neovim Configuration Across Desktop and Homelab

**Branch**: `017-share-neovim-config` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/017-share-neovim-config/spec.md`

## Summary

Extract the declarative LazyVim Neovim setup from the desktop-only Home Manager module (`modules/desktop/editors.nix`) into a shared system-level NixOS module (`modules/core/neovim.nix` defining `flake.modules.core.neovim.nixos`) so that both `desktop-pc` and `homelab` share the exact same Neovim configuration without requiring Home Manager on `homelab`. Specifically:

1. Move `modules/desktop/dotfiles/nvim/` to `modules/core/dotfiles/nvim/` to colocate the LazyVim starter files with `modules/core/neovim.nix`.
2. Configure NixOS's native `programs.neovim` (`enable = true`, `defaultEditor = true`, `viAlias = true`, `vimAlias = true`, `withNodeJs = true`, `withPython3 = true`) and install all cross-host LazyVim runtime dependencies (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`) via `environment.systemPackages`.
3. Create and update the `/home/${vars.userName}/.config/nvim` symlink to the Nix store via `systemd.tmpfiles.rules` (`L+`), removing the dependency on Home Manager's `xdg.configFile`.
4. Remove the standalone `vim` package from `modules/core/base.nix` to avoid binary collisions with `programs.neovim.vimAlias = true`, and keep desktop-only GUI editors (`vscode`, `zed-editor`) and `wl-clipboard` in `modules/desktop/editors.nix`.
5. Persist `.local/share/nvim` and `.local/state/nvim` in `modules/core/preservation.nix` so LazyVim plugins, `lazy-lock.json`, compiled Tree-sitter parsers, and editor state survive `homelab` reboots, and document the changes in `README.md`.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable), Lua (LuaJIT via Neovim >= 0.9.0)

**Primary Dependencies**:

- NixOS native `programs.neovim` module (`enable`, `defaultEditor`, `viAlias`, `vimAlias`, `withNodeJs`, `withPython3`)
- `systemd.tmpfiles.rules` (`d` and `L+` directives for `~/.config/nvim` store symlink)
- `pkgs.neovim` (>= 0.9.0 with LuaJIT)
- `pkgs.git`, `pkgs.gcc`, `pkgs.gnumake`, `pkgs.ripgrep`, `pkgs.fd`, `pkgs.tree-sitter`
- `pkgs.curl`, `pkgs.unzip`, `pkgs.gnutar`, `pkgs.gzip`
- `preservation` NixOS module (`modules/core/preservation.nix` for `homelab` state persistence)

**Storage**:

- Immutable declarative configuration: `/home/${vars.userName}/.config/nvim` symlinked to `${./dotfiles/nvim}` in `/nix/store` via `systemd.tmpfiles.rules`
- Persisted user runtime data (`homelab` via `/persistent/home/${vars.userName}`): `~/.local/share/nvim` (LazyVim plugins, `lazy-lock.json`, Tree-sitter compiled parsers) and `~/.local/state/nvim` (undo history, ShaDa, sessions)
- Transient cache: `~/.cache/nvim/`

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix check`, `deadnix`)
- Host evaluation checks:
  - `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`
  - `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`
  - `nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath`
- Sandbox checks: `just check` (`nix flake check`)

**Target Platform**: `x86_64-linux` (`desktop-pc` workstation and `homelab` headless server)

**Project Type**: Infrastructure as Code / NixOS Multi-Host Configuration (Nix Flakes, `flake-parts`, `import-tree`)

**Performance Goals**:

- Editor startup to interactive LazyVim dashboard in < 1.0 second on both `desktop-pc` and `homelab`
- Zero plugin re-downloads or Tree-sitter parser recompilations across `homelab` reboots

**Constraints**:

- `homelab` MUST retain `enableHomeManager = false`
- Strict Dendritic Pattern compliance: `modules/core/neovim.nix` discovered automatically via `import-tree ./modules`
- Zero duplication of Neovim Lua dotfiles across hosts
- `README.md` synchronized in the same branch with dual Bash/Fish command parity where applicable

**Scale/Scope**:

- 1 new module: `modules/core/neovim.nix`
- 1 relocated dotfiles tree: `modules/desktop/dotfiles/nvim/` -> `modules/core/dotfiles/nvim/` (7 files)
- 5 updated modules: `modules/core/base.nix`, `modules/core/preservation.nix`, `modules/desktop/editors.nix`, `modules/hosts/desktop-pc.nix`, `modules/hosts/homelab.nix`
- 1 updated documentation file: `README.md`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic Configuration** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` drift | **PASS** | `programs.neovim` and `systemd.tmpfiles.rules` (`L+`) declaratively manage Neovim and `/home/${vars.userName}/.config/nvim`. Mutable plugin/state data is isolated in `.local/share/nvim` and `.local/state/nvim` and persisted declaratively on `homelab`. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | Shared Neovim capability is encapsulated in `modules/core/neovim.nix` with colocated `modules/core/dotfiles/nvim/`. Hosts (`desktop-pc.nix`, `homelab.nix`) simply enable `core.neovim` in `features`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | All modified and created `.nix` and `.md` files are validated with `just fmt`, `just lint`, and `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | No secrets, credentials, or keys are involved in Neovim configuration or dotfiles. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Both `desktop-pc` and `homelab` derivations are evaluated and `just check` passes with exit code 0. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronized with branch changes; dual Bash/Fish syntax when shell-specific | **PASS** | `README.md` is updated to document `core.neovim`, `homelab` Neovim availability, and preserved Neovim directories. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in a dedicated feature branch associated with a PR | **PASS** | All changes take place on branch `017-share-neovim-config`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/017-share-neovim-config/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── neovim-module-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
├── core/
│   ├── base.nix                        # Modified: remove standalone `vim` package from systemPackages
│   ├── neovim.nix                      # New: shared system-level Neovim + LazyVim deps + tmpfiles symlink
│   ├── preservation.nix                # Modified: persist `.local/share/nvim` and `.local/state/nvim`
│   └── dotfiles/
│       └── nvim/                       # Relocated from modules/desktop/dotfiles/nvim/
│           ├── init.lua
│           ├── stylua.toml
│           └── lua/
│               ├── config/
│               │   ├── autocmds.lua
│               │   ├── keymaps.lua
│               │   ├── lazy.lua
│               │   └── options.lua
│               └── plugins/
│                   └── example.lua
├── desktop/
│   └── editors.nix                     # Modified: retain `wl-clipboard`, `vscode`, and `zed-editor` only
└── hosts/
    ├── desktop-pc.nix                  # Modified: add `core.neovim` to features
    └── homelab.nix                     # Modified: add `core.neovim` to features
README.md                               # Modified: reflect `core.neovim` and homelab Neovim persistence
```

**Structure Decision**:

- Moving `dotfiles/nvim` from `modules/desktop/dotfiles/nvim` to `modules/core/dotfiles/nvim` colocates the shared LazyVim starter files directly with `modules/core/neovim.nix` using relative path `${./dotfiles/nvim}`, adhering strictly to Constitution Principle II (Dendritic Modularity).
- `modules/desktop/editors.nix` remains focused on the graphical desktop session (`wl-clipboard`, VS Code, Zed).

---

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No constitution violations. All 7 principles pass unconditionally.*
