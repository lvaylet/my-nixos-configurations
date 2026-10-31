---
description: "Task list for Harmonized Visual Studio Code and Code Server Configurations"
---

# Tasks: Harmonized Visual Studio Code and Code Server Configurations

**Input**: Design documents from `/specs/036-harmonize-vscode-codeserver/`

**Prerequisites**: `plan.md` (required), `spec.md` (required for user stories), `research.md`, `data-model.md`, `contracts/shared-vscode-contract.md`, `contracts/code-server-service-contract.md`, `contracts/desktop-editors-contract.md`, `quickstart.md`

**Tests**: Tests are not requested as standalone unit test files; validation is performed through hermetic flake evaluation (`nix eval`), static analysis (`deadnix`, `statix`), pre-commit sandbox checks (`just check`), and non-switching activation testing (`just test`) defined in `specs/036-harmonize-vscode-codeserver/quickstart.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`, `[US4]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify dependencies, available extension packages, and flake module evaluation prerequisites

- [X] T001 Inspect existing VS Code configuration in `modules/desktop/editors.nix` and `modules/services/code-server.nix` to confirm baseline settings and packages
- [X] T002 [P] Verify extension derivations in `pkgs.vscode-extensions` (`github.vscode-github-actions`, `github.vscode-pull-request-github`, `nord-visual-studio-code`, `vscode-markdownlint`, `nix-ide`, `nix`, `alejandra`, `even-better-toml`) and `pkgs.vscode-with-extensions` wrapper functionality via `nix eval`
- [X] T003 [P] Verify `specialArgs` propagation of `outputs` (`config.flake`) across `modules/core/lib.nix` for NixOS, Darwin, and Home Manager modules

---

## Phase 2: Foundational (Shared VS Code Library Module)

**Purpose**: Create the centralized dendritic module skeleton and library attributes for shared settings and extensions

**⚠️ CRITICAL**: Must be completed before any user story implementation can begin

- [X] T004 Create `modules/core/vscode.nix` declaring `config.flake.lib.vscode` for dendritic discovery via `import-tree ./modules` per `specs/036-harmonize-vscode-codeserver/contracts/shared-vscode-contract.md`
- [X] T005 [P] Implement `config.flake.lib.vscode.extensions` function (`pkgs: [ ... ]`) in `modules/core/vscode.nix` with all 8 universal extension derivations (`github.vscode-github-actions`, `github.vscode-pull-request-github`, `nord-visual-studio-code`, `vscode-markdownlint`, `nix-ide`, `nix`, `alejandra`, `even-better-toml`)
- [X] T006 [P] Implement `config.flake.lib.vscode.settings` attribute set in `modules/core/vscode.nix` with theme (`Nord`), typography (`FiraCode Nerd Font`), relative line numbers, rulers (`[ 80 88 100 120 ]`), format-on-save, diff options, file associations, and Nix language/LSP settings
- [X] T007 Verify pure evaluation of `outputs.lib.vscode` with `nix eval .#lib.vscode.settings --json`

**Checkpoint**: Foundation ready — `modules/core/vscode.nix` is discovered by `import-tree` and exports `config.flake.lib.vscode`.

---

## Phase 3: User Story 1 - Consistent Editor Settings and Visual Experience (Priority: P1) 🎯 MVP

**Goal**: Enforce shared editor settings (`Nord` theme, `FiraCode Nerd Font`, relative line numbers, rulers, formatting, file associations) on `homelab` Code Server via declarative `systemd.tmpfiles.rules`.

**Independent Test**: Evaluate `systemd.tmpfiles.rules` on `homelab` via `nix eval` to confirm symlinks for `/home/laurent/.local/share/code-server/User/settings.json` and `/home/laurent/.config/code-server/settings.json` point to the generated Nix store JSON derivation matching `outputs.lib.vscode.settings`.

### Implementation for User Story 1

- [X] T008 [US1] Add `systemd.tmpfiles.rules` in `modules/services/code-server.nix` to declaratively symlink `settings.json` generated from `outputs.lib.vscode.settings` into `/home/${vars.userName}/.local/share/code-server/User/settings.json` and `/home/${vars.userName}/.config/code-server/settings.json` using `L+` semantics per `specs/036-harmonize-vscode-codeserver/contracts/code-server-service-contract.md`
- [X] T009 [US1] Verify generation and content of the settings JSON derivation on `homelab` using `nix eval .#nixosConfigurations.homelab.config.systemd.tmpfiles.rules --json`

**Checkpoint**: User Story 1 is functional: `code-server` on `homelab` receives declarative `settings.json` matching desktop settings.

---

## Phase 4: User Story 2 - Parity of Language Extensions and Developer Tooling (Priority: P1)

**Goal**: Package `code-server` on `homelab` with all shared extensions pre-bundled via `vscode-with-extensions.override` and ensure `alejandra` and `nixd` are present in `services.code-server.extraPackages`.

**Independent Test**: Evaluate `nixosConfigurations.homelab.config.services.code-server.package.name` and inspect `services.code-server.extraPackages` via `nix eval` to verify that all 6 extensions are wrapped and `alejandra` and `nixd` are included in PATH.

### Implementation for User Story 2

- [X] T010 [P] [US2] Configure `services.code-server.package = pkgs.vscode-with-extensions.override { vscode = pkgs.code-server; vscodeExtensions = outputs.lib.vscode.extensions pkgs; };` in `modules/services/code-server.nix`
- [X] T011 [P] [US2] Add `alejandra` and `nixd` to `services.code-server.extraPackages` in `modules/services/code-server.nix` to provide Nix LSP diagnostics and document formatting tools in PATH
- [X] T012 [US2] Verify evaluation and build of wrapped `code-server` package and environment PATH on `homelab` with `nix eval .#nixosConfigurations.homelab.config.services.code-server.package.name --raw`

**Checkpoint**: User Story 2 is functional: `code-server` has all extensions pre-installed and Nix development tooling available.

---

## Phase 5: User Story 3 - Single Source of Truth with Zero Configuration Duplication (Priority: P2)

**Goal**: Refactor `modules/desktop/editors.nix` to consume `outputs.lib.vscode.extensions pkgs` and `outputs.lib.vscode.settings`, eliminating all duplicate literal setting blocks and extension lists.

**Independent Test**: Evaluate `programs.vscode.profiles.default.userSettings` and `extensions` on `desktop-pc` and `macbook-air-m4-15` via `nix eval`, and inspect `modules/desktop/editors.nix` to confirm zero duplicated settings keys or extension lists remain.

### Implementation for User Story 3

- [X] T013 [US3] Refactor `modules/desktop/editors.nix` to replace inline `extensions` with `outputs.lib.vscode.extensions pkgs` and inline `userSettings` with `outputs.lib.vscode.settings` in `programs.vscode.profiles.default`, retaining `pkgs.wl-clipboard` and `programs.zed-editor`
- [X] T014 [P] [US3] Verify that `desktop-pc` evaluates cleanly with `nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.vscode.profiles.default.userSettings --json`
- [X] T015 [P] [US3] Verify that `macbook-air-m4-15` evaluates cleanly with `nix eval .#darwinConfigurations.macbook-air-m4-15.config.home-manager.users.laurent.programs.vscode.profiles.default.userSettings --json`

**Checkpoint**: User Story 3 is functional: Desktop VS Code and Homelab Code Server both consume `outputs.lib.vscode` from a single source of truth with zero duplicate lines.

---

## Phase 6: User Story 4 - Persistent Settings and State Continuity Across Homelab Reboots (Priority: P3)

**Goal**: Ensure all shared Code Server configuration paths and user state persist across ephemeral tmpfs reboots on `homelab`.

**Independent Test**: Check `preservation.preserveAt."/persistent".users.laurent.directories` on `homelab` to confirm `.local/share/code-server` and `.config/code-server` are retained, and confirm `systemd.tmpfiles.rules` directories are created with `0755` permissions.

### Implementation for User Story 4

- [X] T016 [US4] Verify that `modules/services/code-server.nix` maintains directory preservation for `.local/share/code-server` and `.config/code-server` under `/persistent/home/${vars.userName}`
- [X] T017 [US4] Verify tmpfiles directory creation rules (`d /home/${vars.userName}/.local/share/code-server/User 0755 ${vars.userName} users -` and `d /home/${vars.userName}/.config/code-server 0755 ${vars.userName} users -`) in `modules/services/code-server.nix`

**Checkpoint**: User Story 4 is functional: Code Server settings and persistent runtime caches survive host restarts.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation updates, formatting, linting, sandbox checks, and activation testing

- [X] T018 [P] Update `README.md` to document the centralized VS Code configuration library (`modules/core/vscode.nix`), extension parity on Code Server, and operational commands with dual Bash and Fish code blocks
- [X] T019 [P] Format all Nix files with `just fmt` (`nix fmt .`)
- [X] T020 Run static linting with `just lint` (`statix check`, `deadnix`)
- [X] T021 Run hermetic sandbox verification with `just check` (`nix flake check`)
- [X] T022 Execute non-switching activation testing scenario on target host per `specs/036-harmonize-vscode-codeserver/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion (`modules/core/vscode.nix` defined)
  - User Story 1 (Phase 3) and User Story 2 (Phase 4) can proceed in parallel or sequentially (P1)
  - User Story 3 (Phase 5) consumes `outputs.lib.vscode` in desktop module (P2)
  - User Story 4 (Phase 6) validates tmpfiles and preservation rules (P3)
- **Polish (Phase 7)**: Depends on all user story implementations being complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 2 (`outputs.lib.vscode.settings` defined).
- **User Story 2 (P1)**: Depends on Phase 2 (`outputs.lib.vscode.extensions` defined).
- **User Story 3 (P2)**: Depends on Phase 2 (`outputs.lib.vscode` defined). Can run in parallel with US1 and US2.
- **User Story 4 (P3)**: Depends on US1 (`systemd.tmpfiles.rules` declared in `modules/services/code-server.nix`).

### Within Each User Story

- Foundational library definitions before consumer refactoring
- Configuration updates before evaluation tests
- Story complete before marking checkpoint satisfied

### Parallel Opportunities

- In Phase 1: `T002` and `T003` can run in parallel
- In Phase 2: `T005` (extensions) and `T006` (settings) can run in parallel
- In Phase 4: `T010` (package override) and `T011` (extraPackages) can run in parallel
- In Phase 5: `T014` (desktop-pc evaluation) and `T015` (macbook evaluation) can run in parallel
- In Phase 7: `T018` (README.md) and `T019` (formatting) can run in parallel

---

## Parallel Example: User Stories 1 & 2

```bash
# Implement Code Server settings and package wrapper in modules/services/code-server.nix:
Task: "T008 [US1] Add systemd.tmpfiles.rules in modules/services/code-server.nix"
Task: "T010 [P] [US2] Configure services.code-server.package with vscode-with-extensions in modules/services/code-server.nix"
Task: "T011 [P] [US2] Add alejandra and nixd to services.code-server.extraPackages in modules/services/code-server.nix"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001` - `T003`)
2. Complete Phase 2: Foundational (`T004` - `T007`)
3. Complete Phase 3: User Story 1 (`T008` - `T009`)
4. **STOP and VALIDATE**: Verify settings derivation on `homelab` via `nix eval`

### Incremental Delivery

1. Setup + Foundational → Shared configuration library established in `modules/core/vscode.nix`.
2. User Story 1 (Settings Parity) → `homelab` receives declarative settings via `systemd.tmpfiles.rules`.
3. User Story 2 (Extension Parity) → `homelab` receives pre-bundled extensions via `vscode-with-extensions`.
4. User Story 3 (Zero Duplication) → `modules/desktop/editors.nix` refactored to consume shared library.
5. User Story 4 (Persistence) → Preservation and tmpfiles rules verified.
6. Polish → Documentation updated, formatting, linting, and flake check verified.

---

## Notes

- All tasks follow strict format: `- [ ] [TaskID] [P?] [Story?] Description with file path`
- File paths are exact and repository-relative
- No Home Manager modules are introduced onto `homelab` (`enableHomeManager = false` strictly preserved)
- Wayland tools (`wl-clipboard`) and Zed editor remain strictly scoped to desktop environments
