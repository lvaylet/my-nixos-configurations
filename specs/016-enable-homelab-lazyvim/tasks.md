---
description: "Task list for enabling shared LazyVim Neovim configuration on homelab"
---

# Tasks: Enable Shared LazyVim Neovim Configuration on Homelab

**Input**: Design documents from `/specs/016-enable-homelab-lazyvim/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Dotfiles Relocation)

**Purpose**: Relocate the LazyVim starter configuration to the shared `core` domain so both workstation and server hosts reference a single source of truth

- [X] T001 Relocate the LazyVim starter dotfiles directory from `modules/desktop/dotfiles/nvim/` to `modules/core/dotfiles/nvim/` (preserving `init.lua`, `stylua.toml`, `lua/config/autocmds.lua`, `lua/config/keymaps.lua`, `lua/config/lazy.lua`, `lua/config/options.lua`, and `lua/plugins/example.lua`, and removing `modules/desktop/dotfiles/nvim/`)

---

## Phase 2: Foundational (Core Neovim Module Extraction)

**Purpose**: Create the shared `core.neovim` dendritic feature module that all host stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 Create `modules/core/neovim.nix` exporting `flake.modules.core.neovim.homeManager` with `xdg.configFile."nvim".source = ./dotfiles/nvim;`, `home.packages` (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`), and `programs.neovim` (`enable = true`, `defaultEditor = true`, `viAlias = true`, `vimAlias = true`, `withNodeJs = true`, `withPython3 = true`)

**Checkpoint**: Foundation ready - `flake.modules.core.neovim` is available for host composition

---

## Phase 3: User Story 1 - Unified LazyVim Editing Environment on Homelab (Priority: P1) 🎯 MVP

**Goal**: Enable the shared LazyVim Neovim configuration and CLI runtime dependencies for the primary user on `homelab`

**Independent Test**: Evaluate `nixosConfigurations.homelab` Home Manager configuration to confirm `programs.neovim.enable`, `defaultEditor`, `viAlias`, `vimAlias`, `withNodeJs`, and `withPython3` are `true` and `xdg.configFile.nvim.source` points to the LazyVim starter directory

### Implementation for User Story 1

- [X] T003 [US1] Enable Home Manager user environment management by removing `enableHomeManager = false;` and adding `core.neovim` under `# Base Settings` in `modules/hosts/homelab.nix`
- [X] T004 [US1] Verify `nixosConfigurations.homelab` evaluates `programs.neovim` (`enable = true`, `defaultEditor = true`, `viAlias = true`, `vimAlias = true`, `withNodeJs = true`, `withPython3 = true`) and `xdg.configFile.nvim.source` from `modules/hosts/homelab.nix`

**Checkpoint**: User Story 1 is functional: `homelab` provisions the LazyVim configuration and CLI runtime dependencies via Home Manager

---

## Phase 4: User Story 2 - Single Source of Truth Without Desktop GUI Bloat (Priority: P1)

**Goal**: Ensure `desktop-pc` and `homelab` share `core.neovim` without duplication while keeping graphical desktop editors (`vscode`, `zed-editor`) and `wl-clipboard` scoped strictly to `desktop-pc`

**Independent Test**: Evaluate `xdg.configFile.nvim.source` on both `desktop-pc` and `homelab` to confirm identical store paths, and evaluate `programs.vscode.enable` and `programs.zed-editor.enable` to confirm `false` on `homelab` and `true` on `desktop-pc`

### Implementation for User Story 2

- [X] T005 [P] [US2] Refactor `modules/desktop/editors.nix` to remove `xdg.configFile."nvim"`, `programs.neovim`, and CLI-only LazyVim packages while retaining `pkgs.wl-clipboard` in `home.packages`, `programs.vscode`, and `programs.zed-editor`
- [X] T006 [P] [US2] Add `core.neovim` under `# Base Settings` alongside `core.base` and `core.git` (retaining `desktop.editors` under `# Desktop & Shell`) in `modules/hosts/desktop-pc.nix`
- [X] T007 [US2] Verify identical `xdg.configFile.nvim.source` store paths and confirm `programs.vscode.enable` and `programs.zed-editor.enable` evaluate to `false` on `homelab` and `true` on `desktop-pc` across `modules/hosts/homelab.nix` and `modules/hosts/desktop-pc.nix`

**Checkpoint**: User Stories 1 and 2 are functional: both hosts share `core.neovim` from a single source and `homelab` remains free of GUI editor packages

---

## Phase 5: User Story 3 - Persistent Editor State Across Impermanent Homelab Reboots (Priority: P2)

**Goal**: Persist Neovim's downloaded LazyVim plugins, lockfile, Tree-sitter parsers, and editor state across ephemeral reboots on `homelab`

**Independent Test**: Evaluate `nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".users.laurent.directories` and confirm `.local/share/nvim` and `.local/state/nvim` are present

### Implementation for User Story 3

- [X] T008 [US3] Add `".local/share/nvim"` and `".local/state/nvim"` to `preservation.preserveAt."/persistent".users.${vars.userName}.directories` (replacing the commented-out `# ".local/state/neovim"` placeholder) in `modules/core/preservation.nix`
- [X] T009 [US3] Verify `nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".users.laurent.directories` includes `.local/share/nvim` and `.local/state/nvim` from `modules/core/preservation.nix`

**Checkpoint**: User Story 3 is functional: Neovim runtime plugins and state directories are preserved under `/persistent` on `homelab`

---

## Phase 6: User Story 4 - Repository Quality Gates and Documentation Synchronization (Priority: P2)

**Goal**: Synchronize `README.md` with the updated module architecture and ensure full compliance with project governance

**Independent Test**: Inspect `README.md` architecture overview to confirm `core/` and `desktop/` descriptions reflect the shared Neovim/LazyVim module

### Implementation for User Story 4

- [X] T010 [US4] Update the architecture directory tree description in `README.md` to reflect that Neovim/LazyVim is part of `modules/core/` (shared across `desktop-pc` and `homelab`) while graphical editors remain in `modules/desktop/`

**Checkpoint**: User Story 4 is functional: documentation accurately reflects the shared Neovim architecture

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Run formatting, static analysis, host derivation evaluations, and full flake checks across all targets

- [X] T011 [P] Format all Nix expressions using `just fmt` (`alejandra`) across `modules/core/neovim.nix`, `modules/core/preservation.nix`, `modules/desktop/editors.nix`, `modules/hosts/desktop-pc.nix`, and `modules/hosts/homelab.nix`
- [X] T012 [P] Run static analysis and dead-code detection via `just lint` (`statix check` and `deadnix`) across `modules/`
- [X] T013 Execute all validation scenarios from `specs/016-enable-homelab-lazyvim/quickstart.md` including system toplevel evaluations (`desktop-pc`, `homelab`, `iso`) and `just check` (`nix flake check`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately (`T001`)
- **Foundational (Phase 2)**: Depends on Setup (`T001`) - BLOCKS all user stories (`T002`)
- **User Story 1 (Phase 3, P1)**: Depends on Foundational (`T002`) - Enables `core.neovim` on `homelab` (`T003` -> `T004`)
- **User Story 2 (Phase 4, P1)**: Depends on Foundational (`T002`) - Refactors `desktop.editors` and wires `core.neovim` on `desktop-pc` (`T005`, `T006` -> `T007`)
- **User Story 3 (Phase 5, P2)**: Can run after Foundational (`T002`) in parallel with US1/US2 (`T008` -> `T009`)
- **User Story 4 (Phase 6, P2)**: Can run after US1 and US2 (`T010`)
- **Polish (Phase 7)**: Depends on all user stories (`T001`–`T010`) being complete (`T011`, `T012` -> `T013`)

### User Story Dependencies

- **User Story 1 (P1)**: Independent after Phase 2
- **User Story 2 (P1)**: Independent after Phase 2 (can be implemented in parallel with US1; `T007` verifies cross-host parity with US1)
- **User Story 3 (P2)**: Independent after Phase 2 (modifies `modules/core/preservation.nix` only)
- **User Story 4 (P2)**: Updates `README.md` to document the completed module structure

### Parallel Opportunities

- After `T002` completes:
  - `T003` (`modules/hosts/homelab.nix`), `T005` (`modules/desktop/editors.nix`), `T006` (`modules/hosts/desktop-pc.nix`), `T008` (`modules/core/preservation.nix`), and `T010` (`README.md`) touch completely separate files and can be executed in parallel.
- Within Phase 4 (US2): `T005` [P] and `T006` [P] operate on separate files (`modules/desktop/editors.nix` and `modules/hosts/desktop-pc.nix`).
- Within Phase 7 (Polish): `T011` [P] and `T012` [P] can run in parallel before `T013`.

---

## Parallel Example: User Story 2

```bash
# Execute desktop module refactoring and desktop-pc host update in parallel:
Task: "Refactor modules/desktop/editors.nix to retain only wl-clipboard, vscode, and zed-editor"
Task: "Add core.neovim to modules/hosts/desktop-pc.nix"
```

---

## Implementation Strategy

### MVP First (User Story 1 + User Story 2)

1. Complete Phase 1: Setup (`T001` — relocate `dotfiles/nvim` to `modules/core/dotfiles/nvim/`)
2. Complete Phase 2: Foundational (`T002` — create `modules/core/neovim.nix`)
3. Complete Phase 3: User Story 1 (`T003`–`T004` — enable Home Manager and `core.neovim` on `homelab`)
4. Complete Phase 4: User Story 2 (`T005`–`T007` — refactor `desktop.editors` and wire `core.neovim` on `desktop-pc`)
5. **STOP and VALIDATE**: Confirm both `homelab` and `desktop-pc` evaluate identical `~/.config/nvim` sources and `homelab` has zero GUI editors.

### Incremental Delivery

1. Complete Setup + Foundational → `core.neovim` module ready
2. Add User Story 1 & User Story 2 → Shared LazyVim active on both hosts without GUI bloat on `homelab`
3. Add User Story 3 → Persistent Neovim plugin/state storage on `homelab`
4. Add User Story 4 + Polish → Documentation updated and all quality gates (`just fmt`, `just lint`, `just check`) passing
