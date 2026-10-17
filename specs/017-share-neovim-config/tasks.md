---

description: "Task list for Shared System-Level Neovim Configuration Across Desktop and Homelab"
---

# Tasks: Shared System-Level Neovim Configuration Across Desktop and Homelab

**Input**: Design documents from `/specs/017-share-neovim-config/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/neovim-module-contract.md, quickstart.md

**Tests**: Not explicitly requested in the specification; verification is performed via NixOS derivation evaluation and `just check` quality gates.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Colocate the shared LazyVim starter dotfiles within the `core` domain so `modules/core/neovim.nix` can reference `${./dotfiles/nvim}` directly.

- [X] T001 Relocate the LazyVim starter dotfiles directory from `modules/desktop/dotfiles/nvim/` to `modules/core/dotfiles/nvim/` (`init.lua`, `stylua.toml`, `lua/config/autocmds.lua`, `lua/config/keymaps.lua`, `lua/config/lazy.lua`, `lua/config/options.lua`, and `lua/plugins/example.lua`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Prevent binary collisions in `environment.systemPackages` before enabling system-level `programs.neovim.vimAlias = true`.

**⚠️ CRITICAL**: Must be complete before enabling `core.neovim` on hosts.

- [X] T002 Remove `vim` from `environment.systemPackages` in `modules/core/base.nix` to enforce the validation rule `"Zero Binary Conflict: pkgs.vim MUST NOT be present alongside programs.neovim.vimAlias = true in environment.systemPackages"`

**Checkpoint**: Foundation ready - user story implementation can now begin.

---

## Phase 3: User Story 1 - Unified Neovim & LazyVim Experience on Both Desktop and Homelab (Priority: P1) 🎯 MVP

**Goal**: Provide a shared, system-level Neovim (`core.neovim`) module that configures `programs.neovim`, installs all cross-platform LazyVim runtime CLI dependencies, links `/home/${vars.userName}/.config/nvim` via `systemd.tmpfiles.rules`, and is enabled on both `desktop-pc` and `homelab` without requiring Home Manager on `homelab`.

**Independent Test**: Evaluate `nixosConfigurations.homelab.config` and `nixosConfigurations.desktop-pc.config` to verify `programs.neovim.enable == true`, `systemd.tmpfiles.rules` contains `"L+ /home/laurent/.config/nvim - - - - ${./dotfiles/nvim}"`, and `homelab` evaluates cleanly with `enableHomeManager = false`.

### Implementation for User Story 1

- [X] T003 [US1] Create `modules/core/neovim.nix` defining `flake.modules.core.neovim.nixos` with `programs.neovim` (`enable = true`, `defaultEditor = true`, `viAlias = true`, `vimAlias = true`, `withNodeJs = true`, `withPython3 = true`), `environment.systemPackages` (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`), and `systemd.tmpfiles.rules` (`["d /home/${vars.userName}/.config 0755 ${vars.userName} users -" "L+ /home/${vars.userName}/.config/nvim - - - - ${./dotfiles/nvim}"]`)
- [X] T004 [P] [US1] Add `core.neovim` to the `features` list in `modules/hosts/desktop-pc.nix`
- [X] T005 [P] [US1] Add `core.neovim` to the `features` list in `modules/hosts/homelab.nix` while preserving `"Home Manager Independence on homelab: nixosConfigurations.homelab.config MUST evaluate with enableHomeManager = false while containing programs.neovim.enable == true"`

**Checkpoint**: User Story 1 is complete when both `desktop-pc` and `homelab` include `core.neovim` and expose the shared system-level LazyVim configuration.

---

## Phase 4: User Story 2 - Persistent Neovim Plugins and Editor State Across Homelab Reboots (Priority: P1)

**Goal**: Persist the primary user's `.local/share/nvim` and `.local/state/nvim` directories on `/persistent` via `core.preservation` so LazyVim plugins, `lazy-lock.json`, compiled Tree-sitter parsers, ShaDa history, and undo state survive `homelab` reboots.

**Independent Test**: Evaluate `nix eval --json .#nixosConfigurations.homelab.config.preservation.preserveAt.\"/persistent\".users.laurent.directories` and confirm both `".local/share/nvim"` and `".local/state/nvim"` are present.

### Implementation for User Story 2

- [X] T006 [US2] Update `modules/core/preservation.nix` to replace the commented `# ".local/state/neovim"` entry with `".local/share/nvim"` and `".local/state/nvim"` in `preservation.preserveAt."/persistent".users.${vars.userName}.directories`, enforcing `"Impermanence Coverage: nixosConfigurations.homelab.config.preservation.preserveAt.\"/persistent\".users.laurent.directories MUST include both .local/share/nvim and .local/state/nvim"`

**Checkpoint**: User Story 2 is complete when `homelab`'s preservation configuration persists both `.local/share/nvim` and `.local/state/nvim`.

---

## Phase 5: User Story 3 - Clean Modular Separation Between Shared Core Editor and Desktop GUI Editors (Priority: P2)

**Goal**: Remove duplicate Home Manager Neovim settings, dotfiles symlink, and shared CLI dependencies from `modules/desktop/editors.nix` while retaining `wl-clipboard`, VS Code, and Zed for the graphical desktop session.

**Independent Test**: Evaluate `nixosConfigurations.desktop-pc.config` and verify that `desktop.editors` only installs `wl-clipboard`, `programs.vscode`, and `programs.zed-editor` in Home Manager without conflicting with `core.neovim`.

### Implementation for User Story 3

- [X] T007 [US3] Update `modules/desktop/editors.nix` to remove `xdg.configFile."nvim"`, `programs.neovim`, and the migrated LazyVim CLI packages (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`), retaining `pkgs.wl-clipboard` in `home.packages` alongside `programs.vscode` and `programs.zed-editor`

**Checkpoint**: All user stories are complete and modular boundaries between `core.neovim` and `desktop.editors` are clean.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Synchronize repository documentation (`README.md`) per Constitution Principle VI and run all verification and quality gates.

- [X] T008 [P] Update `README.md` to document `modules/core/neovim.nix` (`core.neovim`), the relocated `modules/core/dotfiles/nvim/` tree, the shared availability of Neovim/LazyVim on `desktop-pc` and `homelab`, and the persisted `.local/share/nvim` and `.local/state/nvim` user directories on `homelab`
- [X] T009 Run formatting (`just fmt`), static linting (`just lint`), full flake check (`just check`), and host evaluation checks from `specs/017-share-neovim-config/quickstart.md` across `desktop-pc`, `homelab`, and `iso`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately (`T001`).
- **Foundational (Phase 2)**: Can run alongside or immediately after Phase 1 (`T002`) - blocks host evaluation of `core.neovim`.
- **User Story 1 (Phase 3)**: Depends on `T001` and `T002`. `T004` and `T005` can run in parallel after `T003`.
- **User Story 2 (Phase 4)**: Independent file (`modules/core/preservation.nix`); can run in parallel with Phase 3 or Phase 5.
- **User Story 3 (Phase 5)**: Depends on `T001` and `T003` so `desktop-pc` transitions seamlessly from Home Manager Neovim to `core.neovim`.
- **Polish (Phase 6)**: `T008` can run in parallel with code changes; `T009` runs after all implementation tasks (`T001`–`T008`) are complete.

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 1 (`T001`) and Phase 2 (`T002`).
- **User Story 2 (P1)**: Independent at the file level (`modules/core/preservation.nix`), complements US1 on `homelab`.
- **User Story 3 (P2)**: Cleans up `modules/desktop/editors.nix` once `core.neovim` (`US1`) provides Neovim for `desktop-pc`.

---

## Parallel Example: User Story 1 & Cross-Story Tasks

```bash
# After T001, T002, and T003 complete, the following tasks modify distinct files and can run in parallel:
Task: "T004 [P] [US1] Add core.neovim to the features list in modules/hosts/desktop-pc.nix"
Task: "T005 [P] [US1] Add core.neovim to the features list in modules/hosts/homelab.nix"
Task: "T006 [US2] Update modules/core/preservation.nix to persist .local/share/nvim and .local/state/nvim"
Task: "T007 [US3] Update modules/desktop/editors.nix to retain only wl-clipboard, vscode, and zed-editor"
Task: "T008 [P] Update README.md to document core.neovim and homelab persistence"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2)

1. Complete Phase 1: Setup (`T001` — relocate `dotfiles/nvim` to `modules/core/dotfiles/nvim/`)
2. Complete Phase 2: Foundational (`T002` — remove conflicting `vim` from `modules/core/base.nix`)
3. Complete Phase 3: User Story 1 (`T003`–`T005` — create `modules/core/neovim.nix` and enable on both hosts)
4. Complete Phase 4: User Story 2 (`T006` — persist `.local/share/nvim` and `.local/state/nvim` on `homelab`)
5. Complete Phase 5: User Story 3 (`T007` — clean up `modules/desktop/editors.nix`)
6. Complete Phase 6: Polish (`T008`–`T009` — update `README.md` and run `just fmt`, `just lint`, `just check`)
