---

description: "Task list for Unified FiraCode Nerd Font Typography Across All Code & Terminal Views"
---

# Tasks: Unified FiraCode Nerd Font Typography Across All Code & Terminal Views

**Input**: Design documents from `/specs/020-firacode-nerd-font/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/firacode-typography-contract.md, quickstart.md

**Tests**: Not explicitly requested as standalone test suites; verification is performed via NixOS/Home Manager option evaluation (`nix eval`), Ghostty build-time config validation, and `just check` hermetic sandbox quality gates.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Ensure branch isolation and feature workspace readiness per Constitution Principle VII.

- [X] T001 Verify active feature branch isolation (`020-firacode-nerd-font`) and specification artifacts in `specs/020-firacode-nerd-font/plan.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Confirm that `pkgs.nerd-fonts.fira-code` and `fonts.fontconfig.enable = true` are present in the desktop font module before configuring application and Fontconfig consumers.

**⚠️ CRITICAL**: Must be verified before user story implementation.

- [X] T002 Verify `pkgs.nerd-fonts.fira-code` package installation and `fonts.fontconfig.enable = true` in `modules/desktop/fonts.nix`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel.

---

## Phase 3: User Story 1 - Consistent Code Editor Typography and Ligatures (Priority: P1) 🎯 MVP

**Goal**: Configure every code editor in the stack (VS Code, Zed Editor, and Neovim/LazyVim) to display source code buffers, integrated terminals, debug consoles, SCM inputs, chat code blocks, and GUI windows using `FiraCode Nerd Font` with programming ligatures enabled.

**Independent Test**: Evaluate `nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.vscode.profiles.default.userSettings` and `programs.zed-editor.userSettings` via `nix eval`, and inspect `modules/core/dotfiles/nvim/lua/config/options.lua` to confirm all editor buffers, integrated terminals, and GUI font options specify `FiraCode Nerd Font`.

### Implementation for User Story 1

- [X] T003 [P] [US1] Configure VS Code auxiliary code surfaces (`"debug.console.fontFamily" = "FiraCode Nerd Font"`, `"scm.inputFontFamily" = "FiraCode Nerd Font"`, `"chat.editor.fontFamily" = "FiraCode Nerd Font"` alongside existing `"editor.fontFamily"` and `"terminal.integrated.fontFamily"`) and Zed Editor typography (`buffer_font_family = "FiraCode Nerd Font"`, `buffer_font_size = 12`, `buffer_font_features = { calt = true; }`, `terminal = { font_family = "FiraCode Nerd Font"; font_size = 12; }`) in `modules/desktop/editors.nix`
- [X] T004 [P] [US1] Set `vim.opt.guifont = "FiraCode Nerd Font:h12"` in `modules/core/dotfiles/nvim/lua/config/options.lua` while preserving `"Host Isolation Invariant: homelab MUST continue to evaluate with enableHomeManager = false and zero desktop font derivations added to its system closure"`

**Checkpoint**: User Story 1 is complete and independently testable across VS Code, Zed Editor, and Neovim.

---

## Phase 4: User Story 2 - Unified Terminal Emulator Typography (Priority: P1)

**Goal**: Ensure all standalone terminal emulators on `desktop-pc` (WezTerm and Ghostty) use `FiraCode Nerd Font` with OpenType ligatures (`calt`, `clig`, `liga`) enabled by default.

**Independent Test**: Evaluate `nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.wezterm.extraConfig` and `programs.ghostty.settings` via `nix eval` to confirm both terminal emulators explicitly configure `FiraCode Nerd Font` and ligature features.

### Implementation for User Story 2

- [X] T005 [P] [US2] Verify and retain `config.font = wezterm.font('FiraCode Nerd Font')`, `config.font_size = 11.5`, and `config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }` in `modules/desktop/terminal.nix`
- [X] T006 [P] [US2] Configure `font-family = "FiraCode Nerd Font"` and `font-feature = [ "calt" "clig" "liga" ]` in `programs.ghostty.settings` in `modules/desktop/apps.nix` to satisfy `"Ghostty Build-Time Config Validation: programs.ghostty.settings MUST pass ghostty +validate-config during Home Manager derivation builds"` and `"Universal Code Font Coverage: Every code editor (VS Code, Zed, Neovim) and terminal emulator (WezTerm, Ghostty, VS Code terminal, Zed terminal) in the desktop-pc closure MUST explicitly specify FiraCode Nerd Font"`

**Checkpoint**: User Stories 1 and 2 are complete; all editors and terminal emulators use `FiraCode Nerd Font`.

---

## Phase 5: User Story 3 - System-Wide Default Monospace Fallback & Living Documentation (Priority: P2)

**Goal**: Register `FiraCode Nerd Font` as the primary system/user `monospace` font family in Fontconfig so generic code blocks resolve to `FiraCode Nerd Font`, and update `README.md` in parity.

**Independent Test**: Evaluate `nixosConfigurations.desktop-pc.config.home-manager.users.laurent.fonts.fontconfig.defaultFonts.monospace` via `nix eval` and inspect `README.md` to confirm `FiraCode Nerd Font` is documented across editors, terminals, and default monospace rendering.

### Implementation for User Story 3

- [X] T007 [P] [US3] Configure `fonts.fontconfig.defaultFonts.monospace = [ "FiraCode Nerd Font" "FiraCode Nerd Font Mono" ]` in `modules/desktop/fonts.nix` to satisfy `"Fontconfig Default Monospace Priority: FiraCode Nerd Font MUST be the first entry in fonts.fontconfig.defaultFonts.monospace so fc-match monospace resolves to FiraCode Nerd Font"`
- [X] T008 [P] [US3] Update `README.md` to document the unified `FiraCode Nerd Font` typography and programming ligatures across code editors (VS Code, Zed, Neovim), terminal emulators (WezTerm, Ghostty), and Fontconfig default `monospace` resolution

**Checkpoint**: All user stories and living documentation updates are complete.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate all formatting, static analysis, option evaluations, and multi-host flake checks.

- [X] T009 Run `just fmt`, `just lint`, `just check`, and multi-host derivation evaluations (`desktop-pc`, `homelab`, `iso`) per `specs/020-firacode-nerd-font/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - starts immediately (`T001`).
- **Foundational (Phase 2)**: Depends on Setup (`T002` in `modules/desktop/fonts.nix`).
- **User Story 1 (Phase 3)**: `T003` (`modules/desktop/editors.nix`) and `T004` (`modules/core/dotfiles/nvim/lua/config/options.lua`) touch distinct files and can run in parallel after Phase 2.
- **User Story 2 (Phase 4)**: `T005` (`modules/desktop/terminal.nix`) and `T006` (`modules/desktop/apps.nix`) touch distinct files and can run in parallel after Phase 2.
- **User Story 3 (Phase 5)**: `T007` (`modules/desktop/fonts.nix`) and `T008` (`README.md`) touch distinct files and can run in parallel after Phase 2.
- **Polish (Phase 6)**: `T009` runs after all implementation and documentation tasks (`T001`–`T008`) are complete.

### User Story Dependencies

- **User Story 1 (P1)**: Independent of US2 and US3 (touches `modules/desktop/editors.nix` and `modules/core/dotfiles/nvim/lua/config/options.lua`).
- **User Story 2 (P1)**: Independent of US1 and US3 (touches `modules/desktop/terminal.nix` and `modules/desktop/apps.nix`).
- **User Story 3 (P2)**: Independent of US1 and US2 (touches `modules/desktop/fonts.nix` and `README.md`).

---

## Parallel Example: User Stories 1, 2 & 3

```bash
# All user story implementation tasks operate on distinct files and can run in parallel:
Task: "T003 [P] [US1] Configure VS Code auxiliary code surfaces and Zed Editor typography in modules/desktop/editors.nix"
Task: "T004 [P] [US1] Set vim.opt.guifont in modules/core/dotfiles/nvim/lua/config/options.lua"
Task: "T005 [P] [US2] Verify WezTerm FiraCode Nerd Font and harfbuzz_features in modules/desktop/terminal.nix"
Task: "T006 [P] [US2] Configure font-family and font-feature in programs.ghostty.settings in modules/desktop/apps.nix"
Task: "T007 [P] [US3] Configure fonts.fontconfig.defaultFonts.monospace in modules/desktop/fonts.nix"
Task: "T008 [P] [US3] Update README.md to document unified FiraCode Nerd Font typography"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

1. Complete Phase 1 & Phase 2 (`T001`–`T002`)
2. Complete Phase 3: User Story 1 (`T003`–`T004` — VS Code, Zed, Neovim)
3. Complete Phase 4: User Story 2 (`T005`–`T006` — WezTerm, Ghostty)
4. Complete Phase 5: User Story 3 (`T007`–`T008` — Fontconfig `monospace` default + `README.md`)
5. Complete Phase 6: Polish (`T009` — `just fmt`, `just lint`, `just check`)
