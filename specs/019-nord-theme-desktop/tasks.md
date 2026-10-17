---

description: "Task list for System-Wide Nord Theme Across the Desktop-PC Stack"
---

# Tasks: System-Wide Nord Theme Across the Desktop-PC Stack

**Input**: Design documents from `/specs/019-nord-theme-desktop/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/nord-theme-contract.md, quickstart.md

**Tests**: Not explicitly requested as standalone test suites; verification is performed via NixOS derivation evaluation, Ghostty config validation, and `just check` hermetic sandbox quality gates.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Ensure branch isolation and feature workspace readiness per Constitution Principle VII.

- [X] T001 Verify active feature branch isolation and specification artifacts in `specs/019-nord-theme-desktop/plan.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Disable Noctalia's imperative runtime template hooks (`builtin_ids`) before applying declarative Nord configurations to Niri and WezTerm so Noctalia does not attempt to overwrite read-only Home Manager symlinks in `/nix/store`.

**⚠️ CRITICAL**: Must be complete alongside or before graphical session and terminal stories.

- [X] T002 Set `[theme.templates]` `builtin_ids = []` in `modules/desktop/dotfiles/noctalia.toml`

**Checkpoint**: Foundation ready - user story implementation can now begin.

---

## Phase 3: User Story 1 - Unified Nord Graphical Session, Compositor, and Boot/Login Experience (Priority: P1) 🎯 MVP

**Goal**: Unify the graphical desktop session (Noctalia), Wayland compositor (Niri), login greeter (Tuigreet), and bootloader (Limine) under the Nord dark color palette without any leftover Catppuccin branding.

**Independent Test**: Evaluate `nixosConfigurations.desktop-pc.config` and inspect `modules/desktop/dotfiles/noctalia.toml`, `modules/desktop/dotfiles/niri/config.kdl`, `modules/desktop/session.nix`, and `modules/core/base.nix` to verify that Noctalia uses built-in `Nord`, Niri uses `#88c0d0`/`#4c566a`/`#bf616a`, Tuigreet passes its `--theme` flag, and Limine excludes Catppuccin wallpapers.

### Implementation for User Story 1

- [X] T003 [US1] Configure `[theme]` with `source = "builtin"`, `builtin = "Nord"`, and `mode = "dark"` (removing `community_palette = "Catppuccin Macchiato Blue"`) in `modules/desktop/dotfiles/noctalia.toml`
- [X] T004 [P] [US1] Update `layout.focus-ring` (`active-color "#88c0d0"`, `inactive-color "#4c566a"`) and `layout.border` (`active-color "#88c0d0"`, `inactive-color "#4c566a"`, `urgent-color "#bf616a"`) in `modules/desktop/dotfiles/niri/config.kdl`
- [X] T005 [P] [US1] Update `services.greetd.settings.default_session.command` to append `--theme 'border=cyan;text=white;prompt=cyan;time=cyan;action=blue;button=cyan;container=black;input=white'` to `tuigreet` in `modules/desktop/session.nix`
- [X] T006 [P] [US1] Replace `catppuccin-macchiato.gnomeFilePath` and `nineish-catppuccin-macchiato.gnomeFilePath` with `nineish-dark-gray.gnomeFilePath` and `simple-blue.gnomeFilePath` in `boot.loader.limine.style.wallpapers` in `modules/core/base.nix`

**Checkpoint**: User Story 1 is complete and independently testable across boot, login, compositor, and desktop shell.

---

## Phase 4: User Story 2 - Consistent Nord Theme Across Terminal Emulators and Code Editors (Priority: P1)

**Goal**: Configure all terminal emulators (WezTerm, Ghostty) and code editors (VS Code, Neovim/LazyVim, Zed) in the `desktop-pc` stack to load the Nord color scheme by default.

**Independent Test**: Evaluate `nixosConfigurations.desktop-pc.config` and `nixosConfigurations.homelab.config` and verify that WezTerm (`'nord'`), Ghostty (`"Nord"`), VS Code (`"Nord"`), Neovim (`"nord"` via `gbprod/nord.nvim`), and Zed (`"Nord"` via `"nord"` extension) are declaratively configured.

### Implementation for User Story 2

- [X] T007 [P] [US2] Update `programs.wezterm.extraConfig` to set `config.color_scheme = 'nord'` (replacing `'Catppuccin Mocha'`) in `modules/desktop/terminal.nix`
- [X] T008 [P] [US2] Configure `programs.ghostty.settings.theme = "Nord"` in `modules/desktop/apps.nix` to satisfy `"Ghostty Config Validation: programs.ghostty.settings.theme = \"Nord\" must pass Ghostty's build/activation validator (ghostty +validate-config) against /share/ghostty/themes/Nord"`
- [X] T009 [P] [US2] Create `modules/core/dotfiles/nvim/lua/plugins/colorscheme.lua` declaring `{ "gbprod/nord.nvim", lazy = false, priority = 1000 }` and `{ "LazyVim/LazyVim", opts = { colorscheme = "nord" } }`
- [X] T010 [P] [US2] Update `install = { colorscheme = { "nord", "habamax" } }` (replacing `"tokyonight"`) in `modules/core/dotfiles/nvim/lua/config/lazy.lua`
- [X] T011 [P] [US2] Update `programs.zed-editor` to replace `"one-dark-pro"` with `"nord"` in `extensions` and set `userSettings.theme` to `{ mode = "dark"; light = "One Light"; dark = "Nord"; }` while retaining VS Code's `arcticicestudio.nord-visual-studio-code` and `"workbench.colorTheme" = "Nord"` in `modules/desktop/editors.nix`

**Checkpoint**: User Stories 1 and 2 are complete; all terminals and editors default to Nord.

---

## Phase 5: User Story 3 - Cohesive Nord Styling for Shell Prompt and CLI/TUI Utilities (Priority: P2)

**Goal**: Apply the official 16-color Nord palette to the Starship prompt, Fish interactive shell syntax/pager, OpenCode TUI, Bat, Fzf, Yazi, Btop, and Lazygit.

**Independent Test**: Evaluate `nixosConfigurations.desktop-pc.config` and verify that Starship (`palette = 'nord'`), Fish (`fish_color_*`), OpenCode (`theme = "nord"`), Bat (`theme = "Nord"`), Fzf (`colors`), Yazi (`theme`), Btop (`color_theme = "nord"`), and Lazygit (`gui.theme`) are configured with Nord values.

### Implementation for User Story 3

- [X] T012 [P] [US3] Replace `palette = 'catppuccin_macchiato'` and the `catppuccin_*` palettes with `palette = 'nord'`, `[palettes.nord]` (`#2e3440`–`#b48ead`), and Nord powerline segment styles in `modules/desktop/dotfiles/starship.toml`
- [X] T013 [P] [US3] Add Nord syntax highlighting (`fish_color_*`) and completion pager (`fish_pager_color_*`) global variables to `programs.fish.interactiveShellInit` in `modules/desktop/shell.nix`
- [X] T014 [US3] Configure `programs.opencode.tui.theme = "nord"`, `programs.bat.config.theme = "Nord"`, `programs.fzf.colors` (Nord hex mapping), `programs.yazi.theme` (Nord hex mapping), and `programs.btop = { enable = true; settings.color_theme = "nord"; }` in `modules/desktop/apps.nix` (depends on T008)
- [X] T015 [P] [US3] Configure `programs.lazygit.settings.gui.theme` with Nord hex colors (`#88c0d0`, `#4c566a`, `#81a1c1`, `#3b4252`, `#434c5e`, `#bf616a`, `#d8dee9`, `#ebcb8b`) in `modules/core/git.nix` while preserving `"Host Isolation Invariant: homelab must continue to evaluate with enableHomeManager = false and zero desktop GUI packages"`

**Checkpoint**: User Stories 1, 2, and 3 are complete; all 17 stack components use Nord.

---

## Phase 6: User Story 4 - Declarative Reproducibility and Living Documentation Parity (Priority: P2)

**Goal**: Synchronize `README.md` with the unified Nord theme across the `desktop-pc` stack and shared core editor/CLI modules per Constitution Principle VI.

**Independent Test**: Inspect `README.md` and verify that desktop and editor descriptions accurately reflect the Nord theme across the stack.

### Implementation for User Story 4

- [X] T016 [P] [US4] Update `README.md` to document the unified Nord color theme across `desktop-pc` (Noctalia, Niri, Tuigreet, Limine, WezTerm, Ghostty, VS Code, Zed, Starship, Fish, OpenCode, Bat, Fzf, Yazi, Btop) and shared core modules (`core.neovim` and `core.git`)

**Checkpoint**: All user stories and documentation updates are complete.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validate all invariants, formatting, static analysis, and multi-host flake checks.

- [X] T017 Verify `"Zero Non-Nord Active Theme References: Active configuration files in modules/desktop/ and modules/core/ must contain zero active references to catppuccin, tokyonight, or One Dark"` and run `just fmt`, `just lint`, `just check`, and multi-host derivation evaluations (`desktop-pc`, `homelab`, `iso`) per `specs/019-nord-theme-desktop/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - starts immediately (`T001`).
- **Foundational (Phase 2)**: Depends on Setup (`T002` in `modules/desktop/dotfiles/noctalia.toml`).
- **User Story 1 (Phase 3)**: `T003` updates `modules/desktop/dotfiles/noctalia.toml` after `T002`; `T004`, `T005`, and `T006` touch independent files and can run in parallel.
- **User Story 2 (Phase 4)**: All tasks (`T007`–`T011`) touch distinct files and can run in parallel after Phase 2.
- **User Story 3 (Phase 5)**: `T012`, `T013`, and `T015` touch distinct files and can run in parallel; `T014` updates `modules/desktop/apps.nix` after `T008`.
- **User Story 4 (Phase 6)**: `T016` updates `README.md` and can run in parallel with implementation phases.
- **Polish (Phase 7)**: `T017` runs after all implementation and documentation tasks (`T001`–`T016`) are complete.

### User Story Dependencies

- **User Story 1 (P1)**: Independent of other stories (touches `noctalia.toml`, `niri/config.kdl`, `session.nix`, `base.nix`).
- **User Story 2 (P1)**: Independent of US1 (touches `terminal.nix`, `apps.nix`, `nvim/lua/plugins/colorscheme.lua`, `nvim/lua/config/lazy.lua`, `editors.nix`).
- **User Story 3 (P2)**: Independent of US1; shares `modules/desktop/apps.nix` with US2 (`T014` follows `T008`).
- **User Story 4 (P2)**: Independent file (`README.md`); summarizes US1–US3.

---

## Parallel Example: User Stories 1, 2 & 3

```bash
# Launch parallel tasks across distinct files:
Task: "T004 [P] [US1] Update layout.focus-ring and layout.border in modules/desktop/dotfiles/niri/config.kdl"
Task: "T005 [P] [US1] Update services.greetd.settings.default_session.command in modules/desktop/session.nix"
Task: "T006 [P] [US1] Replace Catppuccin wallpapers in modules/core/base.nix"
Task: "T007 [P] [US2] Update programs.wezterm.extraConfig in modules/desktop/terminal.nix"
Task: "T009 [P] [US2] Create modules/core/dotfiles/nvim/lua/plugins/colorscheme.lua"
Task: "T010 [P] [US2] Update install.colorscheme in modules/core/dotfiles/nvim/lua/config/lazy.lua"
Task: "T011 [P] [US2] Update programs.zed-editor in modules/desktop/editors.nix"
Task: "T012 [P] [US3] Replace palette with nord in modules/desktop/dotfiles/starship.toml"
Task: "T013 [P] [US3] Add Nord syntax/pager colors in modules/desktop/shell.nix"
Task: "T015 [P] [US3] Configure programs.lazygit.settings.gui.theme in modules/core/git.nix"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

1. Complete Phase 1 & Phase 2 (`T001`–`T002`)
2. Complete Phase 3: User Story 1 (`T003`–`T006` — Noctalia, Niri, Tuigreet, Limine)
3. Complete Phase 4: User Story 2 (`T007`–`T011` — WezTerm, Ghostty, VS Code, Neovim, Zed)
4. Complete Phase 5: User Story 3 (`T012`–`T015` — Starship, Fish, OpenCode, Bat, Fzf, Yazi, Btop, Lazygit)
5. Complete Phase 6 & Phase 7 (`T016`–`T017` — `README.md` + `just fmt`, `just lint`, `just check`)
