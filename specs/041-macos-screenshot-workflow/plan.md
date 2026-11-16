# Implementation Plan: macOS-like Screenshot Workflow with Satty & Notifications

**Branch**: `041-macos-screenshot-workflow` | **Date**: 2026-11-16 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/041-macos-screenshot-workflow/spec.md`

---

## Summary

Integrate a macOS-like screenshot workflow on `desktop-pc` running Niri. The workflow combines:

1. Fast, reliable Wayland capture using `grim` + `slurp` (for region and screen) and Niri IPC (for active window).
2. Dual destination: immediate automatic copy to the Wayland clipboard (`wl-copy`) and simultaneous file persistence to `~/Pictures/Screenshots/`.
3. A macOS-style floating thumbnail desktop notification with interactive actions:
   - "Annoter": launches `satty` (GTK4/Libadwaita markup tool) to add arrows, text, blur/pixelate, and numbered steps.
   - "Ouvrir": opens the enclosing screenshots folder in the default file manager.
   - "Supprimer": removes the saved screenshot.
4. Hermetic packaging via `pkgs.writeShellApplication` (`screenshot-tool`) with static analysis (`shellcheck`).
5. Standard Linux PrintScreen keybindings integrated in `modules/desktop/dotfiles/niri/config.kdl` (`Print`, `Ctrl+Print`, `Alt+Print`), along with floating window rules for Satty.

---

## Technical Context

**Language/Version**: Nix Flakes, Bash (POSIX-compatible, shellcheck-verified).

**Primary Dependencies**:

- `satty` (Modern Wayland screenshot annotation utility in GTK4/Libadwaita)
- `grim` (Wayland screencopy tool)
- `slurp` (Wayland interactive region selector)
- `wl-clipboard` (Wayland clipboard utilities: `wl-copy`, `wl-paste`)
- `libnotify` (Desktop notification tool: `notify-send`)
- `xdg-utils` (Desktop integration: `xdg-open`)
- `niri` (Wayland compositor)

**Storage**: Local user storage at `~/Pictures/Screenshots/`.

**Testing**:

- Static analysis & Flake check: `just check` (`nix flake check`)
- Shell scripting verification: Automatic `shellcheck` via `writeShellApplication`
- Markdown linting: `just lint-md` (`markdownlint-cli2`)
- End-to-end interactive validation scenarios documented in `quickstart.md`

**Target Platform**: `desktop-pc` (NixOS x86_64-linux, Niri compositor).

**Project Type**: Desktop User Experience & Wayland Workstation Configuration.

**Constraints**:

- Wayland native: zero X11/XWayland dependencies for capture or markup.
- Clean cancellation: pressing Escape during region selection must exit with code 0 without writing files or notifying.
- Non-blocking notifications: notifications dismiss automatically after timeout without blocking the system.
- Strict dual-shell parity (Bash & Fish) in all documentation (Constitution Principle VI).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic** | Nix flakes, pinned packages, pure evaluation | **PASS** | Script packaged hermetically with `writeShellApplication` and explicit `runtimeInputs`. Packages pinned in `flake.lock`. |
| **II. Dendritic Modularity & Feature Colocation** | Feature-centric colocation under `modules/` | **PASS** | Implemented within `modules/desktop/session.nix` (or `apps.nix`) and `modules/desktop/dotfiles/niri/config.kdl` without scattering. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, `shellcheck` pass, clean `just check` | **PASS** | `writeShellApplication` enforces `shellcheck` during build; `just fmt` and `just check` validate formatting and flake evaluation. |
| **IV. Zero-Secrets Leakage** | No plaintext credentials in version control | **PASS** | Tool handles local user desktop screenshots; zero secrets involved. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> `just test` before `just switch` | **PASS** | Validated via `just check` and test scenarios in `quickstart.md`. |
| **VI. Living Documentation & Dual-Shell Parity** | Documentation updated in same branch, dual Bash/Fish parity | **PASS** | Operational instructions in `quickstart.md` provide explicit **Bash** and **Fish** code blocks. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in dedicated branch (`041-macos-screenshot-workflow`) | **PASS** | Work executed exclusively on branch `041-macos-screenshot-workflow`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/041-macos-screenshot-workflow/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Entities, attributes, schemas & state transitions (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   ├── screenshot-workflow-contract.md
│   └── niri-keybindings-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
└── desktop/
    ├── apps.nix                         # Or session.nix: packages satty, grim, slurp, libnotify, screenshot-tool
    ├── session.nix                      # Packages screenshot-tool application and satty configuration
    └── dotfiles/
        ├── niri/
        │   └── config.kdl               # Updates Print/Ctrl+Print/Alt+Print keybindings and Satty window rules
        └── satty/
            └── config.toml              # (Optional) Declarative Satty user configuration
```

---

## Phases

### Phase 0: Research & Key Decisions

- Consolidate Wayland capture tools (`grim`, `slurp`, `niri msg`), notification action mechanics (`notify-send -A ... -w`), and annotation tooling (`satty`).
- Document all findings in `research.md`.

### Phase 1: Design & Contracts

- Data model with entities, schemas, and state transitions in `data-model.md`.
- Contract for CLI interface in `contracts/screenshot-workflow-contract.md`.
- Contract for Niri keybindings and window rules in `contracts/niri-keybindings-contract.md`.
- Validation guide in `quickstart.md`.
- Re-check Constitution: All 7 principles verified and passing.
