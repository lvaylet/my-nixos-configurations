---

description: "Task list for integrating MacBook Air M4 host and mutualizing shared configurations"
---

# Tasks: Integrate MacBook Air M4 Host and Mutualize Shared Configurations

**Input**: Design documents from `/specs/021-integrate-macbook-air/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/darwin-host-contract.md, contracts/shared-features-contract.md, quickstart.md

**Tests**: Tests are not requested as standalone unit suites; validation is performed through hermetic flake evaluation (`nix eval`), static linters (`deadnix`, `statix`), and sandbox checks (`just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add Darwin input to the root flake to enable `nix-darwin` evaluation.

- [X] T001 Add `inputs.darwin` (`github:LnL7/nix-darwin` following `nixpkgs`) in `flake.nix`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Provide the core Darwin host builder and system baseline required before any Darwin host or shared feature can be evaluated.

**⚠️ CRITICAL**: Must be completed before any user story can be validated on Darwin.

- [X] T002 Implement `mkDarwinHost` builder in `modules/core/lib.nix` supporting `system ? "aarch64-darwin"`, extracting `f.darwin` and `f.homeManager` from enabled features, and integrating `inputs.home-manager.darwinModules.home-manager` per `specs/021-integrate-macbook-air/contracts/darwin-host-contract.md`
- [X] T003 [P] Add `darwin` system configuration block in `modules/core/base.nix` declaring `nixpkgs.config.allowUnfree = true`, `nix.settings` (flakes, trusted-users), `nix.gc`, `users.users.${vars.userName}`, and `security.pam.enableSudoTouchIdAuth = true`

**Checkpoint**: Foundation ready - Darwin builder and system defaults are in place.

---

## Phase 3: User Story 1 - Shared User Environment & Productivity Tools on `macbook-air-m4-15` (Priority: P1) 🎯 MVP

**Goal**: Mutualize existing user environments and productivity tools (Fish, Starship, Git, Lazygit, Neovim, VS Code, WezTerm, Ghostty, core CLI tools) across `desktop-pc` and `macbook-air-m4-15` with platform-specific guards.

**Independent Test**: Evaluate shared Home Manager configuration options for `programs.fish.shellAliases`, `programs.git.settings`, `programs.vscode.profiles.default.userSettings`, and `programs.ghostty.settings` on `macbook-air-m4-15` via `nix eval` per `specs/021-integrate-macbook-air/quickstart.md`.

### Implementation for User Story 1

- [X] T004 [P] [US1] Support Darwin and Home Manager in `modules/core/neovim.nix` by configuring `xdg.configFile."nvim".source = ./dotfiles/nvim;` for Home Manager while preserving `systemd.tmpfiles.rules` on NixOS per `specs/021-integrate-macbook-air/contracts/shared-features-contract.md`
- [X] T005 [P] [US1] Guard `wl-clipboard` package in `modules/desktop/editors.nix` with `lib.optionals pkgs.stdenv.isLinux [ pkgs.wl-clipboard ]` per `specs/021-integrate-macbook-air/contracts/shared-features-contract.md`
- [X] T006 [P] [US1] Update WezTerm configuration in `modules/desktop/terminal.nix` to make `enable_wayland = true` conditional on Linux (`pkgs.stdenv.isLinux`) per `specs/021-integrate-macbook-air/contracts/shared-features-contract.md`
- [X] T007 [P] [US1] Guard `fonts.fontconfig.enable = pkgs.stdenv.isLinux;` in `modules/desktop/fonts.nix` so font packages install cleanly on macOS without invalid fontconfig evaluation
- [X] T008 [P] [US1] Guard Linux disk utilities (`efibootmgr`, `gptfdisk`, `parted`, `tparted`) in `modules/desktop/apps.nix` with `lib.optionals pkgs.stdenv.isLinux`
- [X] T009 [US1] Verify cross-platform Home Manager evaluation for shared tools (Fish shell in `modules/desktop/shell.nix`, Git in `modules/core/git.nix`, and CLI utilities in `modules/desktop/apps.nix`) on both Linux and Darwin targets

**Checkpoint**: User Story 1 complete — all user-space configurations and dotfiles are portable and evaluate cleanly across platforms.

---

## Phase 4: User Story 2 - Declarative Host Definition & Cross-Platform Modularity (Priority: P1)

**Goal**: Declare the `macbook-air-m4-15` host in the repository using the dendritic pattern, and verify multi-platform evaluation across all repository targets.

**Independent Test**: Evaluate `darwinConfigurations.macbook-air-m4-15.system.drvPath` as well as all NixOS host derivations (`desktop-pc`, `homelab`, `iso`) via `nix eval` without errors or warnings.

### Implementation for User Story 2

- [X] T010 [US2] Create declarative Darwin host definition `modules/hosts/macbook-air-m4-15.nix` using `config.flake.lib.mkDarwinHost` with `system = "aarch64-darwin"` and composing shared features (`core.base`, `core.git`, `core.neovim`, `desktop.apps`, `desktop.editors`, `desktop.fonts`, `desktop.shell`, `desktop.terminal`, `services.ssh`) per `specs/021-integrate-macbook-air/contracts/darwin-host-contract.md`
- [X] T011 [P] [US2] Add Darwin rebuild and test recipes (`switch-darwin`, `test-darwin`) in `justfile`
- [X] T012 [US2] Verify hermetic evaluation of all flake hosts (`nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`, `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`, `nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath`, and `nix eval .#darwinConfigurations.macbook-air-m4-15.system.drvPath`) without regressions

**Checkpoint**: User Story 2 complete — `macbook-air-m4-15` is fully declared and integrates alongside existing NixOS hosts.

---

## Phase 5: User Story 3 - Homelab Connectivity & Remote Client Access (Priority: P2)

**Goal**: Provide `macbook-air-m4-15` with immediate client access to `homelab` services via declarative SSH aliases and network coordinates.

**Independent Test**: Evaluate `darwinConfigurations.macbook-air-m4-15.config.home-manager.users.laurent.programs.ssh.settings.homelab.HostName` via `nix eval` to confirm the target IP is `"192.168.1.180"`.

### Implementation for User Story 3

- [X] T013 [US3] Verify that `services.ssh` Home Manager client configuration (`programs.ssh.settings.homelab`) in `modules/services/ssh.nix` is cleanly evaluated on `macbook-air-m4-15` without pulling OpenSSH daemon or Linux firewall rules

**Checkpoint**: User Story 3 complete — client SSH connection profile is active on the MacBook Air.

---

## Phase 6: User Story 4 - Living Documentation & Dual-Shell Parity (Priority: P2)

**Goal**: Update repository documentation to reflect `macbook-air-m4-15`, its architecture, mutualized components, and operational commands with strict dual Bash/Fish parity.

**Independent Test**: Review `README.md` to confirm `macbook-air-m4-15` is listed in the host inventory and that all macOS build and switch instructions provide explicit `bash` and `fish` code blocks.

### Implementation for User Story 4

- [X] T014 [US4] Update `README.md` to document `macbook-air-m4-15` in the host inventory and architecture tree, listing mutualized vs host-specific features and providing copy-paste ready deployment commands with dual Bash and Fish syntax per Constitution Principle VI

**Checkpoint**: User Story 4 complete — living documentation is in sync with dual-shell parity.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Run repository quality gates, static linters, and full sandbox checks.

- [X] T015 [P] Run code formatting (`just fmt`) and static analysis (`just lint`)
- [X] T016 Run full hermetic sandbox verification (`just check`) and validate all steps in `specs/021-integrate-macbook-air/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: `flake.nix` updated with `darwin` input — can start immediately.
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories on Darwin.
- **User Story 1 (Phase 3)**: Depends on Foundational completion (`mkDarwinHost` available).
- **User Story 2 (Phase 4)**: Depends on User Story 1 completion (shared modules guarded).
- **User Story 3 (Phase 5)**: Depends on User Story 2 completion (`macbook-air-m4-15` declared).
- **User Story 4 (Phase 6)**: Depends on all user stories being defined.
- **Polish (Phase 7)**: Depends on all user stories and documentation being complete.

### Parallel Opportunities

- Within Phase 2: `T003` (base.nix) can be implemented in parallel with `T002` (lib.nix).
- Within Phase 3 (US1): `T004` (neovim.nix), `T005` (editors.nix), `T006` (terminal.nix), `T007` (fonts.nix), and `T008` (apps.nix) can all be edited in parallel as they touch independent files.
- Within Phase 4 (US2): `T011` (justfile) can run in parallel with `T010` (macbook-air-m4-15.nix).
- Within Phase 7: `T015` (lint/fmt) runs before `T016` (flake check).

---

## Parallel Example: User Story 1

```bash
# Launch parallel edits for User Story 1 guards:
Task T004: "modules/core/neovim.nix"
Task T005: "modules/desktop/editors.nix"
Task T006: "modules/desktop/terminal.nix"
Task T007: "modules/desktop/fonts.nix"
Task T008: "modules/desktop/apps.nix"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2)

1. Complete Phase 1: Setup (`flake.nix` inputs).
2. Complete Phase 2: Foundational (`mkDarwinHost` and `core.base.darwin`).
3. Complete Phase 3: User Story 1 (Shared module guards).
4. Complete Phase 4: User Story 2 (`modules/hosts/macbook-air-m4-15.nix`).
5. **STOP and VALIDATE**: Verify `nix eval .#darwinConfigurations.macbook-air-m4-15.system.drvPath`.
6. Complete Phase 5 (Homelab SSH client verification) and Phase 6 (`README.md` documentation).
7. Complete Phase 7: Polish (`just fmt`, `just lint`, `just check`).
