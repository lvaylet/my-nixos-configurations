---
description: "Task list for declarative LazyVim configuration implementation"
---

# Tasks: Declarative LazyVim Configuration

**Input**: Design documents from `/specs/008-declarative-lazyvim/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish directory structure and verify desktop system prerequisites

- [X] T001 Create starter dotfiles directory structure `modules/desktop/dotfiles/nvim/lua/config` and `modules/desktop/dotfiles/nvim/lua/plugins`
- [X] T002 [P] Verify Nerd Fonts and terminal true-color configuration prerequisites in `modules/desktop/fonts.nix` and `modules/desktop/terminal.nix`

---

## Phase 2: Foundational (Module Skeleton & Deprecations)

**Purpose**: Deprecate legacy editor configuration and configure Neovim engine skeleton

**⚠️ CRITICAL**: Blocking prerequisite before LazyVim starter files and dependencies are composed

- [X] T003 Remove legacy `programs.nvf` NixOS configuration and `nvf` module import from `modules/desktop/editors.nix`
- [X] T004 Configure Home Manager `programs.neovim` engine with `enable = true`, `defaultEditor = true`, `viAlias = true`, `vimAlias = true`, `withNodeJs = true`, and `withPython3 = true` in `modules/desktop/editors.nix`

**Checkpoint**: Foundation ready - Neovim engine is active in Home Manager and `nvf` is removed

---

## Phase 3: User Story 1 - Out-of-the-Box Modal Editing with LazyVim Starter (Priority: P1) 🎯 MVP

**Goal**: Deploy upstream LazyVim starter configuration files and link them to `~/.config/nvim` with a writable lockfile

**Independent Test**: Launch `nvim` in a terminal, verify that the LazyVim starter interface loads without errors, presents the starter dashboard, and applies default options and keymaps

### Implementation for User Story 1

- [X] T005 [P] [US1] Create root entrypoint `init.lua` bootstrapping `require("config.lazy")` in `modules/desktop/dotfiles/nvim/init.lua`
- [X] T006 [P] [US1] Create StyLua code formatting configuration in `modules/desktop/dotfiles/nvim/stylua.toml`
- [X] T007 [P] [US1] Create baseline editor options module in `modules/desktop/dotfiles/nvim/lua/config/options.lua`
- [X] T008 [P] [US1] Create baseline keybindings module in `modules/desktop/dotfiles/nvim/lua/config/keymaps.lua`
- [X] T009 [P] [US1] Create baseline autocommands module in `modules/desktop/dotfiles/nvim/lua/config/autocmds.lua`
- [X] T010 [US1] Create bootstrap module in `modules/desktop/dotfiles/nvim/lua/config/lazy.lua` configuring `lazy.nvim` setup, plugin specs (`LazyVim/LazyVim` and `plugins`), and writable lockfile `lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json"`
- [X] T011 [US1] Symlink the starter configuration to `~/.config/nvim` via `xdg.configFile."nvim".source = ./dotfiles/nvim;` in `modules/desktop/editors.nix`

**Checkpoint**: User Story 1 is functional: LazyVim starter files are linked, Neovim boots the starter UI, and lockfile is writable

---

## Phase 4: User Story 2 - Comprehensive Availability of Upstream Runtime Dependencies (Priority: P1)

**Goal**: Provision all external CLI tools mandated by LazyVim Getting Started documentation in the user environment

**Independent Test**: Run `rg --version`, `fd --version`, `gcc --version`, `make --version`, `git --version`, and `wl-copy --version` from a shell session and confirm all binaries execute successfully

### Implementation for User Story 2

- [X] T012 [P] [US2] Add search tools `pkgs.ripgrep` and `pkgs.fd` to `home.packages` in `modules/desktop/editors.nix`
- [X] T013 [P] [US2] Add compilation tools `pkgs.gcc` and `pkgs.gnumake` for Tree-sitter parsers to `home.packages` in `modules/desktop/editors.nix`
- [X] T014 [P] [US2] Add download and archive utilities `pkgs.curl`, `pkgs.unzip`, `pkgs.tar`, and `pkgs.gzip` to `home.packages` in `modules/desktop/editors.nix`
- [X] T015 [P] [US2] Add Wayland clipboard bridge `pkgs.wl-clipboard` to `home.packages` in `modules/desktop/editors.nix`
- [X] T016 [US2] Verify version control tool `pkgs.git` availability in `home.packages` in `modules/desktop/editors.nix` alongside `modules/core/git.nix`

**Checkpoint**: User Story 2 is functional: all runtime dependencies from LazyVim Getting Started are available in PATH

---

## Phase 5: User Story 3 - Declarative Customization and Extension Workflow (Priority: P2)

**Goal**: Provide reference plugin extension point demonstrating how users add custom plugins and overrides

**Independent Test**: Verify `lua/plugins/example.lua` is discoverable and processed by `lazy.nvim` on editor launch

### Implementation for User Story 3

- [X] T017 [US3] Create reference user plugin customization file demonstrating plugin overrides in `modules/desktop/dotfiles/nvim/lua/plugins/example.lua`

**Checkpoint**: User Story 3 is functional: custom plugin definitions can be added under `modules/desktop/dotfiles/nvim/lua/plugins/`

---

## Phase 6: User Story 4 - Hermetic System Integration and State Isolation (Priority: P2)

**Goal**: Ensure clean dendritic composition into `desktop-pc` host and verify mutable state isolation

**Independent Test**: Evaluate `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath` and verify `desktop.editors` compiles cleanly with zero inline host logic

### Implementation for User Story 4

- [X] T018 [US4] Verify dendritic composition of `desktop.editors` in `modules/hosts/desktop-pc.nix` without inline service or editor logic
- [X] T019 [US4] Validate transient state isolation paths (`~/.local/share/nvim`, `~/.cache/nvim`, `~/.local/state/nvim`) in `specs/008-declarative-lazyvim/data-model.md`

**Checkpoint**: User Story 4 is functional: editor configuration is modularized, evaluated purely, and state is isolated

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Formatting, static analysis, flake evaluation, regression checks, and end-to-end quickstart validation

- [X] T020 [P] Format all Nix expressions using `just fmt` (`alejandra`) across `modules/desktop/editors.nix`
- [X] T021 [P] Run static analysis and dead code checks via `just lint` (`statix check`, `deadnix`)
- [X] T022 Verify system derivation graph evaluation for `desktop-pc`, `homelab`, and `iso` targets per `specs/008-declarative-lazyvim/quickstart.md`
- [X] T023 Run hermetic pre-commit checks in sandbox via `just check` (`nix flake check`)
- [X] T024 Execute end-to-end validation scenarios documented in `specs/008-declarative-lazyvim/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: Depend on Foundational phase completion
  - **User Story 1 (P1)**: Depends on Phase 2 - Deploys starter files and `xdg.configFile` symlink (MVP)
  - **User Story 2 (P1)**: Depends on Phase 2 - Adds runtime dependencies to `home.packages` (can run in parallel with US1)
  - **User Story 3 (P2)**: Depends on US1 (requires starter plugin directory)
  - **User Story 4 (P2)**: Depends on US1 and US2 - Verifies full dendritic composition
- **Polish (Phase 7)**: Depends on all user stories (US1–US4) being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start immediately after Foundational (Phase 2)
- **User Story 2 (P1)**: Can start immediately after Foundational (Phase 2) in parallel with US1
- **User Story 3 (P2)**: Extends US1 by adding plugin demonstration file
- **User Story 4 (P2)**: Verifies end-to-end composition across US1 and US2

### Parallel Opportunities

- Within Phase 1: `T002` [P] can run while `T001` runs.
- Within Phase 3 (US1): `T005`, `T006`, `T007`, `T008`, and `T009` [P] can all be authored in parallel.
- Within Phase 4 (US2): `T012`, `T013`, `T014`, and `T015` [P] can all be declared in parallel.
- Within Phase 7 (Polish): `T020` [P] and `T021` [P] can run in parallel.

---

## Parallel Example: User Story 1 & User Story 2

```bash
# Launch starter file creation in parallel (User Story 1):
Task: "Create root entrypoint init.lua in modules/desktop/dotfiles/nvim/init.lua"
Task: "Create StyLua code formatting configuration in modules/desktop/dotfiles/nvim/stylua.toml"
Task: "Create baseline editor options module in modules/desktop/dotfiles/nvim/lua/config/options.lua"
Task: "Create baseline keybindings module in modules/desktop/dotfiles/nvim/lua/config/keymaps.lua"
Task: "Create baseline autocommands module in modules/desktop/dotfiles/nvim/lua/config/autocmds.lua"

# Declare runtime dependencies concurrently (User Story 2):
Task: "Add search tools pkgs.ripgrep and pkgs.fd to home.packages in modules/desktop/editors.nix"
Task: "Add compilation tools pkgs.gcc and pkgs.gnumake to home.packages in modules/desktop/editors.nix"
Task: "Add download utilities pkgs.curl, unzip, tar, gzip to home.packages in modules/desktop/editors.nix"
Task: "Add Wayland clipboard bridge pkgs.wl-clipboard to home.packages in modules/desktop/editors.nix"
```

---

## Implementation Strategy

### MVP First (User Story 1 & User Story 2)

1. Complete Phase 1: Setup (Create dotfiles directory tree `modules/desktop/dotfiles/nvim/`)
2. Complete Phase 2: Foundational (Remove `nvf`, setup `programs.neovim` skeleton in `modules/desktop/editors.nix`)
3. Complete Phase 3: User Story 1 (Create starter Lua files and link via `xdg.configFile."nvim"`)
4. Complete Phase 4: User Story 2 (Add `rg`, `fd`, `gcc`, `make`, `wl-clipboard`, `git` to `home.packages`)
5. **STOP and VALIDATE**: Verify `nvim` launches with LazyVim starter UI and dependencies in PATH (MVP!)
6. Complete Phase 5: User Story 3 (Add `lua/plugins/example.lua`)
7. Complete Phase 6: User Story 4 (Verify dendritic host composition and state isolation)
8. Complete Phase 7: Polish (Format with `just fmt`, lint with `just lint`, check with `just check`)
