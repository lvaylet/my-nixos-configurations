# Implementation Plan: Dynamic Random Noctalia Wallpapers on `desktop-pc`

**Branch**: `033-noctalia-random-wallpapers` | **Date**: 2026-10-30 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/033-noctalia-random-wallpapers/spec.md`

## Summary

Implement declarative, reproducible, and interactive random wallpaper management for the Noctalia desktop shell on `desktop-pc`:

1. **Versioned Wallpaper Assets & Home Manager Deployment**: Create and version `assets/wallpapers/` at repository root (tracked in Git via `.gitkeep`) and link it to `~/Pictures/wallpapers` in `modules/desktop/session.nix`.
2. **Startup Randomization & Nord Fallback in Noctalia**: In `modules/desktop/dotfiles/noctalia.toml`, strip stale hardcoded `/nix/store/...` paths and configure `directory = "~/Pictures/wallpapers"`, Nord Polar Night fallback (`fill_color = "#2e3440"`), and startup automation (`order = "random"`, `recursive = true`, `interval_seconds = 86400`) so wallpapers rotate at login without unwanted mid-session timer disruptions.
3. **Interactive Shortcuts in Niri**: In `modules/desktop/dotfiles/niri/config.kdl`, configure `Mod+Shift+W` to trigger `noctalia msg wallpaper-random` and `Mod+Ctrl+W` to toggle `noctalia msg panel-toggle wallpaper`.
4. **Living Documentation**: Update `README.md` to document the new wallpaper directory, deployment mapping, and desktop keybindings.

## Technical Context

**Language/Version**: Nix (Flakes, NixOS `nixos-unstable`, Home Manager), TOML, KDL, Markdown
**Primary Dependencies**: `nixpkgs`, `home-manager`, `noctalia` (`github:noctalia-dev/noctalia`), `niri` (Wayland scrollable-tiling compositor)
**Storage**: Git repository directory `assets/wallpapers/` packaged into Nix store and symlinked to `~/Pictures/wallpapers`
**Testing**: `just check` (`nix flake check`), `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`), `nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl`, and host evaluation (`desktop-pc`)
**Target Platform**: `x86_64-linux` (`desktop-pc`)
**Project Type**: Declarative OS & user environment configuration (Dendritic Pattern)
**Performance Goals**: Instant startup randomization (<100ms); smooth GPU shader transitions upon wallpaper switch; sub-500ms wallpaper panel toggle
**Constraints**: Zero hardcoded `/nix/store/...` hashes in configuration files; Nord theme consistency (`#2e3440` Polar Night fallback); no mid-session automatic wallpaper switching (startup or on-demand only)
**Scale/Scope**: 1 new asset directory (`assets/wallpapers/`), 3 configuration files (`session.nix`, `noctalia.toml`, `config.kdl`), and `README.md`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Declarative & Hermetic Configuration**: PASS — All wallpaper symlinks and shell settings are managed through Home Manager and versioned configuration files; no ad-hoc imperative edits or brittle hardcoded store hashes.
- **II. Dendritic Modularity & Feature-Centric Composition**: PASS — Desktop session and shell configurations reside strictly in `modules/desktop/session.nix` and `modules/desktop/dotfiles/`.
- **III. Shift-Left Quality, Formatting & Static Analysis**: PASS — All Nix files format with `alejandra` (`just fmt`) and pass `statix`, `deadnix`, and `nix flake check` (`just check`), while Niri config passes upstream validation.
- **IV. Zero-Secrets Leakage & Security First**: PASS — No secrets or private data are introduced.
- **V. Rigorous Verification & Safe Deployment Workflow**: PASS — Changes are validated with evaluation and sandbox testing before activation.
- **VI. Living Documentation & Dual-Shell Parity**: PASS — `README.md` will be updated to document the wallpaper asset folder, Home Manager link, and Niri shortcuts.
- **VII. Dedicated Branch & Pull Request Workflow**: PASS — Work is executed entirely on the `033-noctalia-random-wallpapers` branch.

## Project Structure

### Documentation (this feature)

```text
specs/033-noctalia-random-wallpapers/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── noctalia-wallpaper-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
assets/
└── wallpapers/
    └── .gitkeep                                # Versioned wallpaper image directory
modules/
└── desktop/
    ├── dotfiles/
    │   ├── niri/
    │   │   └── config.kdl                      # Add Mod+Shift+W and Mod+Ctrl+W wallpaper bindings
    │   └── noctalia.toml                       # Configure wallpaper directory, Nord fallback & automation
    └── session.nix                             # Link assets/wallpapers to ~/Pictures/wallpapers
README.md                                       # Document wallpaper repository path & Niri shortcuts
```

**Structure Decision**: Place the versioned wallpaper assets in `assets/wallpapers/` at the repository root, deploy to `~/Pictures/wallpapers` via Home Manager in `modules/desktop/session.nix`, configure Noctalia in `modules/desktop/dotfiles/noctalia.toml`, and declare keybindings in `modules/desktop/dotfiles/niri/config.kdl`.

## Complexity Tracking

> No Constitution Check violations.
