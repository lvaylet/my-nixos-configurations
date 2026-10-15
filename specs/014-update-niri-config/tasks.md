---
description: "Task list for updating Niri configuration with upstream defaults and documentation"
---

# Tasks: Update Niri Configuration with Upstream Defaults and Documentation

**Input**: Design documents from `/specs/014-update-niri-config/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/niri-config-contract.md`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and verification of each story increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify existing Home Manager dotfile wiring and desktop module integrations

- [X] T001 [P] Verify `xdg.configFile."niri/config.kdl".source = ./dotfiles/niri/config.kdl` and Noctalia integration in `modules/desktop/session.nix`
- [X] T002 [P] Verify WezTerm configuration and Wayland package integration in `modules/desktop/terminal.nix`

---

## Phase 2: Foundational (Base Configuration Structure)

**Purpose**: Establish the upstream KDL file header and top-level section ordering in `modules/desktop/dotfiles/niri/config.kdl`

**⚠️ CRITICAL**: Blocking prerequisite for populating user story configuration sections in `modules/desktop/dotfiles/niri/config.kdl`

- [X] T003 Initialize upstream KDL format header comments (`https://kdl.dev`, `/-` node-comment explanation, and `https://niri-wm.github.io/niri/Configuration:-Introduction` reference) in `modules/desktop/dotfiles/niri/config.kdl`

**Checkpoint**: Base file header and KDL structure ready in `modules/desktop/dotfiles/niri/config.kdl`

---

## Phase 3: User Story 1 - Comprehensive Upstream Niri Capabilities & Inline Reference Documentation (Priority: P1) 🎯 MVP

**Goal**: Integrate all upstream Niri sections (`input` device blocks, `/-output "eDP-1"` template, `layout` sub-blocks `shadow` and `struts`, `hotkey-overlay`, `screenshot-path`, `animations`, and upstream window/column/workspace/monitor `binds`) with full inline documentation comments in `modules/desktop/dotfiles/niri/config.kdl`

**Independent Test**: Inspect `modules/desktop/dotfiles/niri/config.kdl` for all upstream sections and comments (`input`, `/-output "eDP-1"`, `layout`, `hotkey-overlay`, `screenshot-path`, `animations`, `binds`) and run `nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl` (exits with code `0`)

### Implementation for User Story 1

- [X] T004 [US1] Add upstream `input` comments and commented libinput subsections (`touchpad` optional flags, `mouse`, `trackpoint`, `warp-mouse-to-focus`, `focus-follows-mouse max-scroll-amount="0%"`, and `numlock`) in `modules/desktop/dotfiles/niri/config.kdl`
- [X] T005 [US1] Add upstream commented-out `/-output "eDP-1"` example block with `mode`, `scale`, `transform`, and logical `position` documentation in `modules/desktop/dotfiles/niri/config.kdl`
- [X] T006 [US1] Add upstream `layout` documentation comments, `preset-window-heights` comment, `border` fallback properties (`width 4`, `active-color "#ffc87f"`, `inactive-color "#505050"`, `urgent-color "#9b0000"`, gradient examples), `shadow` (`softness 30`, `spread 5`, `offset x=0 y=5`, `color "#0007"`), and `struts` sections in `modules/desktop/dotfiles/niri/config.kdl`
- [X] T007 [US1] Add upstream `hotkey-overlay`, `screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"` (plus commented `screenshot-path null`), and `animations` sections with inline comments in `modules/desktop/dotfiles/niri/config.kdl`
- [X] T008 [US1] Add upstream Niri window, column, workspace, monitor, mouse-wheel, overview (`Mod+O`), hotkey-overlay (`Mod+Shift+Slash`), screenshot (`Print`, `Ctrl+Print`, `Alt+Print`), shortcut-inhibitor (`Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }`), quit (`Ctrl+Alt+Delete`), and monitor power-off (`Mod+Shift+P`) bindings and comments in `modules/desktop/dotfiles/niri/config.kdl`

**Checkpoint**: User Story 1 complete — all upstream Niri sections, documentation comments, and standard compositor keybindings are present in `modules/desktop/dotfiles/niri/config.kdl`

---

## Phase 4: User Story 2 - Seamless Preservation of Personal Desktop Stack Customizations (Priority: P1)

**Goal**: Preserve and harmonize all personal customizations for Noctalia, WezTerm, `us,fr` XKB keyboard layout, `gaps 8`, `proportion 1.0` preset width, Catppuccin focus ring (`width 2`, `#cba6f7`, `#45475a`), `prefer-no-csd`, and clarified modifier bindings in `modules/desktop/dotfiles/niri/config.kdl`

**Independent Test**: Verify `spawn-at-startup "noctalia"`, `layout "us,fr"`, `gaps 8`, `proportion 1.0`, `active-color "#cba6f7"`, `prefer-no-csd`, and Noctalia/WezTerm binds (`Mod+Return`, `Mod+T`, `Mod+Space`, `Mod+D`, `Mod+N`, `Mod+Shift+E`, `Super+Alt+L`, `Mod+Shift+1..9`) in `modules/desktop/dotfiles/niri/config.kdl` and validate with `nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl`

### Implementation for User Story 2

- [X] T009 [US2] Configure personal `input.keyboard.xkb` settings (`layout "us,fr"`, `variant "intl,"`, `options "grp:alt_shift_toggle"`) and active `input.touchpad` settings (`tap`, `natural-scroll`) in `modules/desktop/dotfiles/niri/config.kdl`
- [X] T010 [US2] Configure personal `layout` overrides (`gaps 8`, `center-focused-column "never"`, `preset-column-widths` including `proportion 1.0`, `default-column-width { proportion 0.5; }`, `focus-ring` with `width 2`, `active-color "#cba6f7"`, `inactive-color "#45475a"`, and `border { off; ... }`) and active `prefer-no-csd` in `modules/desktop/dotfiles/niri/config.kdl`
- [X] T011 [US2] Configure `spawn-at-startup "noctalia"` with upstream startup and `spawn-sh-at-startup` comments in `modules/desktop/dotfiles/niri/config.kdl`
- [X] T012 [US2] Configure WezTerm and Noctalia IPC keybindings (`Mod+Return` and `Mod+T` for `wezterm`, `Mod+Space` and `Mod+D` for Noctalia launcher, `Mod+N` for Noctalia control center, `Mod+Shift+E` for Noctalia session menu, `Super+Alt+L` for Noctalia session lock, and `Mod+Shift+1..9` for `move-window-to-workspace 1..9`) with `hotkey-overlay-title` attributes in `modules/desktop/dotfiles/niri/config.kdl`

**Checkpoint**: User Story 2 complete — all personal Noctalia, WezTerm, keyboard layout, and visual styling settings are active and harmonized without keybinding conflicts in `modules/desktop/dotfiles/niri/config.kdl`

---

## Phase 5: User Story 3 - Application Window Rules and Hardware Media/Brightness Ergonomics (Priority: P2)

**Goal**: Integrate upstream `window-rule` blocks (active WezTerm initial configure workaround, active Firefox Picture-in-Picture floating rule, and commented-out `/-window-rule` examples) and hardware audio/media/brightness/touchpad/accessibility bindings in `modules/desktop/dotfiles/niri/config.kdl`

**Independent Test**: Verify active `window-rule` blocks for WezTerm and Firefox Picture-in-Picture, commented `/-window-rule` blocks, and `XF86Audio*` / `XF86MonBrightness*` / `XF86TouchpadToggle` / `Super+Alt+S` bindings in `modules/desktop/dotfiles/niri/config.kdl`, and run `nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl`

### Implementation for User Story 3

- [X] T013 [US3] Add `window-rule` blocks (active WezTerm rule matching `^org\.wezfurlong\.wezterm$` and `"wezterm"` with `default-column-width {}`, active Firefox `Picture-in-Picture` floating rule, and commented `/-window-rule` examples for password managers `block-out-from "screen-capture"` and rounded corners `geometry-corner-radius 12`) in `modules/desktop/dotfiles/niri/config.kdl`
- [X] T014 [US3] Add hardware audio (`XF86AudioRaiseVolume`, `XF86AudioLowerVolume`, `XF86AudioMute`, `XF86AudioMicMute` via `wpctl`), media (`XF86AudioPlay/Pause/Stop/Prev/Next` via `playerctl`), brightness (`XF86MonBrightnessUp/Down` via `brightnessctl`), touchpad toggle (`XF86TouchpadToggle`), and screen reader (`Super+Alt+S` via `orca`) bindings with `allow-when-locked=true` and `repeat=false` properties in `modules/desktop/dotfiles/niri/config.kdl`

**Checkpoint**: User Story 3 complete — all window rules and hardware/media keybindings are integrated in `modules/desktop/dotfiles/niri/config.kdl`

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: KDL schema validation, formatting, static analysis, flake evaluation, and hermetic sandbox checks

- [X] T015 Validate KDL syntax and schema of `modules/desktop/dotfiles/niri/config.kdl` using `nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl` per `specs/014-update-niri-config/quickstart.md`
- [X] T016 [P] Run `just fmt` (`alejandra`) and `just lint` (`statix check`, `deadnix`) across the repository
- [X] T017 [P] Verify `desktop-pc` NixOS toplevel derivation evaluation (`nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`) per `specs/014-update-niri-config/quickstart.md`
- [X] T018 Run hermetic pre-commit and flake checks via `just check` (`nix flake check`) across all repository files

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately (`T001` and `T002` in parallel)
- **Foundational (Phase 2)**: Depends on Setup completion (`T003`)
- **User Stories (Phase 3–5)**: Depend on Foundational phase completion
  - **User Story 1 (P1 - Phase 3)**: Populates upstream sections, comments, and standard Niri binds (`T004`–`T008`)
  - **User Story 2 (P1 - Phase 4)**: Applies and harmonizes personal Noctalia, WezTerm, XKB, and layout overrides (`T009`–`T012`)
  - **User Story 3 (P2 - Phase 5)**: Adds application window rules and hardware/media/brightness binds (`T013`–`T014`)
- **Polish (Phase 6)**: Depends on Phases 3–5 completion (`T015`–`T018`)

### Parallel Opportunities

- **Phase 1 (Setup)**: `T001` [P] (`modules/desktop/session.nix`) and `T002` [P] (`modules/desktop/terminal.nix`) inspect independent files and can run in parallel.
- **Phase 6 (Polish)**: `T016` [P] (`just fmt` / `just lint`) and `T017` [P] (`nix eval` of `desktop-pc`) can run in parallel after `T015`.

---

## Parallel Example: Setup & Polish Phases

```bash
# Phase 1: Verify existing desktop module wiring in parallel
Task: "T001 [P] Verify xdg.configFile.\"niri/config.kdl\" and Noctalia integration in modules/desktop/session.nix"
Task: "T002 [P] Verify WezTerm configuration and Wayland package integration in modules/desktop/terminal.nix"

# Phase 6: Run formatting/linting and flake evaluation in parallel
Task: "T016 [P] Run just fmt and just lint across the repository"
Task: "T017 [P] Verify desktop-pc NixOS toplevel derivation evaluation per specs/014-update-niri-config/quickstart.md"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 - P1 Stories)

1. Complete Phase 1: Setup (`T001`–`T002`)
2. Complete Phase 2: Foundational (`T003`)
3. Complete Phase 3: User Story 1 (`T004`–`T008` — full upstream sections, comments, and standard Niri binds)
4. Complete Phase 4: User Story 2 (`T009`–`T012` — personal Noctalia, WezTerm, `us,fr` XKB, and Catppuccin layout settings)
5. **STOP and VALIDATE**: Run `nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl`
6. Complete Phase 5: User Story 3 (`T013`–`T014` — WezTerm & Firefox PiP window rules + media/hardware keys)
7. Complete Phase 6: Polish (`T015`–`T018` — `niri validate`, `just fmt`, `just lint`, `nix eval`, `just check`)
