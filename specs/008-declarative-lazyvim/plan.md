# Implementation Plan: Declarative LazyVim Configuration

**Branch**: `008-declarative-lazyvim` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/008-declarative-lazyvim/spec.md`

## Summary

Implement a declarative, NixOS-compatible LazyVim editing environment that replicates the upstream `LazyVim/starter` baseline and satisfies all runtime dependencies from the LazyVim Getting Started guide. Neovim and its runtime tools are configured via Home Manager in `modules/desktop/editors.nix`, superseding the legacy `nvf` NixOS configuration. The full starter file layout (`init.lua`, `lua/config/*`, `lua/plugins/*`, `stylua.toml`) is stored under `modules/desktop/dotfiles/nvim/` and declaratively linked into `~/.config/nvim` via `xdg.configFile."nvim"`. To prevent read-only filesystem errors in the Nix store, `lua/config/lazy.lua` redirects the `lazy.nvim` lockfile to `~/.local/share/nvim/lazy-lock.json`. All required tools (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `wl-clipboard`, curl/tar/unzip) are declared in `home.packages`.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable), Lua (LuaJIT via Neovim >= 0.9.0)

**Primary Dependencies**:
- `home-manager` (`programs.neovim`, `xdg.configFile`)
- `pkgs.neovim` (>= 0.9.0 with LuaJIT)
- `pkgs.git` (>= 2.19.0)
- `pkgs.gcc` & `pkgs.gnumake` (Tree-sitter compiler & native extensions)
- `pkgs.ripgrep` & `pkgs.fd` (Live search and fuzzy file discovery)
- `pkgs.wl-clipboard` (Wayland clipboard bridge for Niri)
- `nerd-fonts.fira-code` (via `modules/desktop/fonts.nix`)
- `wezterm` (via `modules/desktop/terminal.nix`)

**Storage**:
- Immutable declarative configuration: `~/.config/nvim/` linked to Nix store
- Transient runtime state & plugins: `~/.local/share/nvim/` (plugins, lockfile, treesitter grammars)
- Transient cache: `~/.cache/nvim/`
- User state: `~/.local/state/nvim/` (undo tree, history, ShaDa)

**Testing**:
- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix check`, `deadnix`)
- Flake evaluation: `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`
- Regression evaluation: `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`, `nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath`
- Sandbox checks: `just check` (`nix flake check`)

**Target Platform**: `x86_64-linux` (`desktop-pc` workstation with Niri Wayland compositor)

**Project Type**: Infrastructure as Code & Desktop User Environment (Nix Flakes, Home Manager, Neovim dotfiles)

**Performance Goals**:
- Editor startup to interactive dashboard in < 1.0 second on standard hardware
- Project file search (<leader>ff) across 10,000+ files in < 500 ms
- 100% of runtime dependencies resolved immediately without missing binary errors

**Constraints**:
- Strict Dendritic Pattern compliance: `modules/desktop/editors.nix` discovered automatically via `import-tree`
- Declarative hermeticity: zero imperative mutations in `~/.config/nvim`
- Writable lockfile: lockfile directed to `stdpath("data")` to avoid read-only Nix store conflicts
- Zero plaintext secrets committed to version control
- Zero build regressions across existing host definitions (`desktop-pc`, `homelab`, `iso`)

**Scale/Scope**:
- 1 modified module: `modules/desktop/editors.nix` (replaces `nvf` NixOS module with declarative Home Manager Neovim)
- 1 new dotfiles directory: `modules/desktop/dotfiles/nvim/` (7 starter files)

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` drift | **PASS** | Editor configuration declared via Home Manager `xdg.configFile` and `programs.neovim`. Runtime plugins and lockfile isolated in documented transient directories (`stdpath("data")`). |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | `modules/desktop/editors.nix` encapsulates Neovim, VS Code, and Zed editor configurations. Discovered automatically via `import-tree ./modules`. `modules/hosts/desktop-pc.nix` only references `desktop.editors`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | All Nix expressions formatted with `alejandra`, checked with `statix` and `deadnix`, verified via `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | Editor dotfiles and Nix expressions contain zero secrets, API tokens, or private credentials. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Flake evaluation and sandbox checks verified across all targets (`desktop-pc`, `homelab`, `iso`) prior to profile switching. |

---

## Project Structure

### Documentation (this feature)

```text
specs/008-declarative-lazyvim/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Entities, schemas & validation rules (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   ├── lazyvim-module-contract.md
│   ├── starter-layout-contract.md
│   └── cli-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
└── desktop/
    ├── editors.nix                     # Refactored: removes nvf, adds programs.neovim + deps + xdg link
    ├── dotfiles/
    │   ├── starship.toml
    │   ├── noctalia.toml
    │   ├── niri/
    │   │   └── config.kdl
    │   └── nvim/                       # New: LazyVim starter baseline configuration
    │       ├── init.lua                # Entrypoint bootstrapping require("config.lazy")
    │       ├── stylua.toml             # StyLua formatting configuration
    │       └── lua/
    │           ├── config/
    │           │   ├── autocmds.lua    # Starter autocommands
    │           │   ├── keymaps.lua     # Starter keybindings
    │           │   ├── lazy.lua        # Lazy.nvim setup with writable lockfile path
    │           │   └── options.lua     # Starter editor options
    │           └── plugins/
    │               └── example.lua     # Starter example plugin overrides
    ├── apps.nix
    ├── fonts.nix
    ├── terminal.nix
    ├── session.nix
    └── ...
```

**Structure Decision**:
- The editor module resides in `modules/desktop/editors.nix`, maintaining dendritic modularity and colocating all desktop editors (`neovim`, `vscode`, `zed-editor`).
- Dotfiles reside in `modules/desktop/dotfiles/nvim/`, matching the established repository pattern used for `niri/config.kdl`, `starship.toml`, and `noctalia.toml`.

---

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No constitution violations. All principles pass unconditionally.*
