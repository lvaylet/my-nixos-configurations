# Implementation Plan: Enable Shared LazyVim Neovim Configuration on Homelab

**Branch**: `016-enable-homelab-lazyvim` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/016-enable-homelab-lazyvim/spec.md`

## Summary

Make the LazyVim-based Neovim configuration currently used on `desktop-pc` also available on `homelab` without duplicating dotfiles or installing graphical desktop editors on the headless server. The implementation extracts the Neovim program configuration, LazyVim starter dotfiles, and CLI runtime dependencies (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`) from `modules/desktop/editors.nix` into a shared core module `modules/core/neovim.nix` (`flake.modules.core.neovim`) backed by `modules/core/dotfiles/nvim/`. Both `modules/hosts/desktop-pc.nix` and `modules/hosts/homelab.nix` compose `core.neovim` (with Home Manager enabled on `homelab`), while `desktop.editors` remains exclusive to `desktop-pc` for VS Code, Zed, and `wl-clipboard`. Finally, `modules/core/preservation.nix` persists `~/.local/share/nvim` and `~/.local/state/nvim` under `/persistent` so downloaded LazyVim plugins, compiled Tree-sitter parsers, lockfiles, and editor state survive ephemeral reboots on `homelab`.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable), Lua (LuaJIT via Neovim >= 0.9.0)

**Primary Dependencies**:

- `home-manager` (`programs.neovim`, `xdg.configFile`)
- `preservation` (`preservation.preserveAt."/persistent".users.<name>.directories`)
- `pkgs.neovim` (with `withNodeJs = true`, `withPython3 = true`, `defaultEditor = true`, `viAlias = true`, `vimAlias = true`)
- LazyVim CLI runtime dependencies: `pkgs.git`, `pkgs.gcc`, `pkgs.gnumake`, `pkgs.ripgrep`, `pkgs.fd`, `pkgs.tree-sitter`, `pkgs.curl`, `pkgs.unzip`, `pkgs.gnutar`, `pkgs.gzip`

**Storage**:

- Declarative immutable configuration: `~/.config/nvim/` linked to Nix store (`modules/core/dotfiles/nvim/`) via Home Manager on both `desktop-pc` and `homelab`
- Persistent user state on `homelab`: `/persistent/home/laurent/.local/share/nvim` and `/persistent/home/laurent/.local/state/nvim` via `modules/core/preservation.nix`
- Transient cache: `~/.cache/nvim/`

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix check`, `deadnix`)
- Host & Home Manager attribute evaluation: `nix eval` on `nixosConfigurations.desktop-pc` and `nixosConfigurations.homelab`
- Full flake & pre-commit sandbox checks: `just check` (`nix flake check`)

**Target Platform**: `x86_64-linux` (`desktop-pc` workstation and `homelab` headless server)

**Project Type**: Infrastructure as Code (Nix Flakes, NixOS & Home Manager dendritic modules)

**Performance Goals**:

- Zero runtime plugin re-downloads or Tree-sitter recompilations across `homelab` reboots thanks to `/persistent` state preservation
- Zero GUI editor package overhead (`vscode`, `zed-editor`) in the `homelab` closure

**Constraints**:

- Strict Dendritic Pattern compliance (`import-tree ./modules`, feature-centric modules, no inline services in host definitions)
- Single source of truth for LazyVim starter dotfiles (`modules/core/dotfiles/nvim/`)
- Full `README.md` parity with dual Bash/Fish command variants where applicable (Constitution Principle VI)
- Dedicated branch and Pull Request workflow (Constitution Principle VII)

**Scale/Scope**:

- 1 new core module: `modules/core/neovim.nix`
- 1 relocated dotfiles directory: `modules/desktop/dotfiles/nvim/` -> `modules/core/dotfiles/nvim/` (7 files)
- 1 refactored desktop module: `modules/desktop/editors.nix`
- 1 updated preservation module: `modules/core/preservation.nix`
- 2 updated host definitions: `modules/hosts/desktop-pc.nix`, `modules/hosts/homelab.nix`
- 1 updated documentation file: `README.md`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Pre-Design Status | Post-Design Status | Verification Notes |
| --- | --- | --- | --- | --- |
| **I. Declarative & Hermetic** | Pure Nix flakes, Home Manager, no imperative `$HOME` drift | **PASS** | **PASS** | `~/.config/nvim` linked declaratively from Nix store via Home Manager on both hosts; mutable plugin/state paths isolated and persisted declaratively on `homelab`. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric modules under `modules/`, auto-discovery via `import-tree`, host files only compose features | **PASS** | **PASS** | Shared CLI editor extracted to `modules/core/neovim.nix` (`core.neovim`); GUI editors remain in `modules/desktop/editors.nix` (`desktop.editors`). Hosts compose `core.neovim` declaratively. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra`, `statix`, `deadnix`, `nix flake check` pass with 0 warnings/errors | **PASS** | **PASS** | Verified via `just fmt`, `just lint`, and `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets or private keys committed | **PASS** | **PASS** | Lua dotfiles and Nix modules contain zero secrets or credentials. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` and evaluation checks before switching | **PASS** | **PASS** | Toplevel derivations and Home Manager options evaluated for `desktop-pc`, `homelab`, and `iso`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronized with architecture/service changes; Bash & Fish variants | **PASS** | **PASS** | `README.md` architecture overview updated to reflect shared `core` Neovim/LazyVim capability and `homelab` persistent user directories. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in dedicated branch associated with a PR | **PASS** | **PASS** | Tracked on branch `016-enable-homelab-lazyvim`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/016-enable-homelab-lazyvim/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── neovim-module-contract.md
│   └── homelab-preservation-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
├── core/
│   ├── base.nix                        # Base OS & Home Manager user profile foundation
│   ├── git.nix                         # Shared Git & Lazygit Home Manager module
│   ├── neovim.nix                      # NEW: Shared LazyVim Neovim & CLI dependencies module
│   ├── preservation.nix                # UPDATED: Persists .local/share/nvim & .local/state/nvim
│   └── dotfiles/
│       └── nvim/                       # MOVED from modules/desktop/dotfiles/nvim/
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
│   ├── editors.nix                     # UPDATED: Retains VS Code, Zed, and wl-clipboard only
│   └── dotfiles/
│       ├── niri/
│       │   └── config.kdl
│       ├── noctalia.toml
│       └── starship.toml
└── hosts/
    ├── desktop-pc.nix                  # UPDATED: Adds core.neovim alongside desktop.editors
    └── homelab.nix                     # UPDATED: Enables Home Manager and adds core.neovim
README.md                               # UPDATED: Reflects shared Neovim module & homelab setup
```

**Structure Decision**:
Placing the shared LazyVim configuration in `modules/core/neovim.nix` (`flake.modules.core.neovim`) and `modules/core/dotfiles/nvim/` mirrors `modules/core/git.nix` (`flake.modules.core.git`) and cleanly separates cross-host CLI editor capabilities (`core.neovim`) from graphical desktop IDEs (`desktop.editors`).

---

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *None* | All designs strictly comply with Constitution Principles I–VII | N/A |
