# Implementation Plan: Update Niri Configuration with Upstream Defaults and Documentation

**Branch**: `014-update-niri-config` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/014-update-niri-config/spec.md`

## Summary

Update the declarative Niri Wayland compositor configuration in `modules/desktop/dotfiles/niri/config.kdl` to adopt the complete structure, default settings, window rules, keybindings, and inline reference documentation from the official upstream Niri configuration (`https://github.com/niri-wm/niri/blob/main/resources/default-config.kdl`). Personal workstation specificities are preserved and harmonized with upstream conventions: Noctalia (`spawn-at-startup "noctalia"`, launcher on `Mod+Space`/`Mod+D`, control center on `Mod+N`, session panel on `Mod+Shift+E`, screen lock on `Super+Alt+L`), WezTerm (`Mod+Return` and `Mod+T`, plus the WezTerm initial configure `window-rule`), bilingual `us,fr` XKB keyboard layout (`variant "intl,"`, `options "grp:alt_shift_toggle"`, `numlock`), personalized layout geometry (`gaps 8`, `proportion 1.0` preset width, `prefer-no-csd`, and Catppuccin `focus-ring` colors `#cba6f7`/`#45475a` with `width 2`), and upstream modifier conventions (`Mod+Ctrl` for moving columns/windows, `Mod+Shift` for focusing monitors, `Mod+Shift+1..9` for moving single windows to workspaces, and `Mod+Escape` for `toggle-keyboard-shortcuts-inhibit`).

---

## Technical Context

**Language/Version**: KDL (Niri configuration format), Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:

- `programs.niri` (Niri scrollable-tiling Wayland compositor enabled in `modules/desktop/session.nix`)
- `xdg.configFile."niri/config.kdl"` (Home Manager declarative dotfile link in `modules/desktop/session.nix`)
- `programs.noctalia` (`github:noctalia-dev/noctalia` desktop shell & IPC commands)
- `programs.wezterm` (WezTerm terminal emulator in `modules/desktop/terminal.nix`)
- PipeWire / WirePlumber (`wpctl` in `modules/desktop/audio.nix`)

**Storage**: Declarative immutable store object linked to `~/.config/niri/config.kdl` via Home Manager `xdg.configFile`.

**Testing**:

- Niri native configuration validation: `niri validate -c modules/desktop/dotfiles/niri/config.kdl` (or via `nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl`).
- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Flake evaluation: `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`.
- Hermetic sandbox checks: `just check` (`nix flake check`).

**Target Platform**: `desktop-pc` (`x86_64-linux` Wayland workstation).

**Project Type**: Declarative NixOS & Home Manager desktop configuration (`modules/desktop/`).

**Performance Goals**:

- Zero compositor startup overhead or config parse latency (< 10ms validation time).
- 100% of upstream and custom keybindings immediately responsive in the Wayland session and visible in the `Mod+Shift+Slash` hotkey overlay.

**Constraints**:

- Strict adherence to Constitution Principles I–VII.
- Zero duplicate active keybindings in `binds`.
- All upstream comments (`//`) and commented-out example nodes (`/-output`, `/-window-rule`) preserved verbatim where applicable so `config.kdl` acts as a self-contained reference manual.
- No modifications required to host definitions (`modules/hosts/desktop-pc.nix`) since `modules/desktop/session.nix` already sources `./dotfiles/niri/config.kdl`.

**Scale/Scope**:

- 1 primary dotfile updated: `modules/desktop/dotfiles/niri/config.kdl` (expanded from ~110 lines to ~515 lines with full upstream comments, sections, window rules, and binds).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` drift | **PASS** | `modules/desktop/dotfiles/niri/config.kdl` is managed declaratively via `xdg.configFile."niri/config.kdl".source` in `modules/desktop/session.nix`. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | Changes are strictly encapsulated in `modules/desktop/dotfiles/niri/config.kdl` within the `desktop` domain. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox, file hygiene | **PASS** | Validated via `niri validate`, `just fmt`, `just lint`, and `just check` (including trailing whitespace, end-of-file newline, and mixed line-ending hooks). |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | Pure window manager configuration; zero secrets or credentials involved. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> `just test` before `just switch` | **PASS** | Validation workflow in `quickstart.md` verifies syntax with `niri validate`, evaluates `desktop-pc`, runs `just check`, and tests with `just test`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronization when services/workflows change; dual Bash/Fish command variants where syntax differs | **PASS** | `README.md` does not hardcode Niri internal keybindings (no service added/removed); all shell commands in `quickstart.md` provide explicit Bash and Fish variants where syntax differs. |
| **VII. Dedicated Branch & Pull Request Workflow** | Dedicated branch and associated Pull Request targeting `main` | **PASS** | Feature implementation and commits are isolated on a dedicated branch and tracked via a Pull Request targeting `main`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/014-update-niri-config/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Configuration entities, sections & invariants (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   └── niri-config-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
└── desktop/
    ├── session.nix                 # Existing module linking ./dotfiles/niri/config.kdl
    └── dotfiles/
        └── niri/
            └── config.kdl          # Updated Niri KDL configuration with upstream defaults & comments
```

**Structure Decision**:
Preserves the existing Dendritic layout under `modules/desktop/`. `modules/desktop/session.nix` already links `./dotfiles/niri/config.kdl` to `~/.config/niri/config.kdl`, so updating `modules/desktop/dotfiles/niri/config.kdl` in place requires zero structural boilerplate changes.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| *None* | All designs strictly comply with Constitution Principles I–VII | N/A |
