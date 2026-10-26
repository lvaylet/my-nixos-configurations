---

description: "Task list for Local Development and Deployment Stack on Homelab"
---

# Tasks: Local Development and Deployment Stack on Homelab

**Input**: Design documents from `/specs/029-homelab-dev-stack/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Verification is performed via declarative Nix flake evaluation and sandbox quality gates (`nix flake check`, `deadnix`, `statix check`, `alejandra`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Branch isolation and workspace readiness in accordance with Constitutional Principle VII

- [X] T001 Create and switch to dedicated feature branch `029-homelab-dev-stack` from repository root (`.git/`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Verify existing flake development shell and `.envrc` configuration before modifying host/core modules

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 Verify `use flake` in `.envrc` and `devShells.default` package definitions (`just`, `nh`, `enabledPackages`) in `modules/core/devshell.nix`

**Checkpoint**: Foundation verified - user story implementation can now begin

---

## Phase 3: User Story 1 - Self-Hosted Configuration Deployment from Homelab (Priority: P1) 🎯 MVP

**Goal**: Provide `just`, `nh`, and the Nix CLI tooling on `homelab` (both in interactive shells and in the `opencode-web` service environment) so operators can build, test, and deploy `homelab` locally from the machine itself.

**Independent Test**: Evaluate `nixosConfigurations.homelab` to confirm `just`, `nh`, `alejandra`, `deadnix`, `statix`, `nixd`, `just-lsp`, and `cachix` are present in `environment.systemPackages` and that `opencode-web.service` includes `/run/wrappers/bin`, `/run/current-system/sw/bin`, `bash`, `just`, `nh`, and `nix` in its `PATH`.

### Implementation for User Story 1

- [X] T003 [P] [US1] Add the Nix development and deployment CLI stack (`alejandra`, `cachix`, `deadnix`, `just`, `just-lsp`, `nh`, `nixd`, `statix`) to `environment.systemPackages` in both `nixos` and `darwin` blocks of `modules/core/base.nix`
- [X] T004 [P] [US1] Expand `systemd.services.opencode-web.path` to include `"/run/wrappers"`, `"/run/current-system/sw"`, and core CLI packages (`bash`, `coreutils`, `direnv`, `gh`, `git`, `just`, `nh`, `nix`, `nixos-rebuild`, `openssh`, `ripgrep`) in `modules/services/opencode.nix`
- [X] T005 [US1] Evaluate `nixosConfigurations.homelab` to verify `just`, `nh`, and `opencode-web.service` `PATH` entries in `modules/core/base.nix` and `modules/services/opencode.nix`

**Checkpoint**: User Story 1 is complete and independently verifiable

---

## Phase 4: User Story 2 - Automatic Development Environment Activation via Direnv (Priority: P2)

**Goal**: Enable `direnv` with `nix-direnv` across system shells (Fish and Bash) and persist `~/.local/share/direnv` across reboots on `homelab`'s ephemeral root filesystem so `.envrc` (`use flake`) activates automatically when entering the workspace.

**Independent Test**: Evaluate `nixosConfigurations.homelab` to confirm `programs.direnv.enable = true`, `programs.direnv.nix-direnv.enable = true`, `programs.direnv.enableFishIntegration = true`, `programs.direnv.enableBashIntegration = true`, and `.local/share/direnv` is listed in `preservation.preserveAt."/persistent".users.laurent.directories`.

### Implementation for User Story 2

- [X] T006 [P] [US2] Enable `programs.direnv` with `nix-direnv.enable = true` in both `nixos` and `darwin` blocks of `modules/core/base.nix`
- [X] T007 [P] [US2] Add `".local/share/direnv"` to `preservation.preserveAt."/persistent".users.${vars.userName}.directories` in `modules/core/preservation.nix`
- [X] T008 [US2] Evaluate `nixosConfigurations.homelab` to verify `programs.direnv` (`enable`, `nix-direnv.enable`, `enableFishIntegration`, `enableBashIntegration`) and `.local/share/direnv` preservation in `modules/core/base.nix` and `modules/core/preservation.nix`

**Checkpoint**: User Stories 1 AND 2 are both complete and independently verifiable

---

## Phase 5: User Story 3 - Shared Core Developer Tooling Across Hosts (Priority: P3)

**Goal**: Deduplicate the Nix CLI stack and `programs.direnv` from `desktop.apps` (`homeManager`) now that they are provided centrally by `core.base`, and synchronize `README.md` with the updated architecture and `homelab` local deployment workflow.

**Independent Test**: Evaluate `nixosConfigurations.desktop-pc`, `darwinConfigurations.macbook-air-m4-15`, and `nixosConfigurations.iso` with exit code 0, confirm `home-manager.users.laurent.programs.direnv.enable` is `false` on `desktop-pc` and `macbook-air-m4-15` while system `programs.direnv.enable` is `true`, and verify `README.md` updates.

### Implementation for User Story 3

- [X] T009 [P] [US3] Remove duplicate Nix CLI packages (`alejandra`, `deadnix`, `nixd`, `statix`, `nh`, `cachix`, `just`, `just-lsp`) and `programs.direnv` from `modules/desktop/apps.nix`
- [X] T010 [P] [US3] Update `README.md` to document the shared Nix development stack and `direnv` (`nix-direnv`) in `core.base`, `.local/share/direnv` persistence on `homelab`, and local self-deployment instructions with Bash/Fish parity
- [X] T011 [US3] Evaluate `nixosConfigurations.desktop-pc`, `darwinConfigurations.macbook-air-m4-15`, and `nixosConfigurations.iso` to verify zero option conflicts or duplicate `direnv` hooks in `modules/desktop/apps.nix` and `modules/core/base.nix`

**Checkpoint**: All user stories are now independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Formatting, static analysis, and full flake verification across all hosts

- [X] T012 Format all modified Nix files with `nix fmt .` (`alejandra`) across `modules/core/base.nix`, `modules/core/preservation.nix`, `modules/desktop/apps.nix`, and `modules/services/opencode.nix`
- [X] T013 Run static analysis (`deadnix` and `statix check`) and full sandbox flake check (`nix flake check`) from repository root (`flake.nix`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2)
- **User Story 2 (Phase 4)**: Depends on Foundational (Phase 2); T006 edits `modules/core/base.nix` after T003, while T007 (`modules/core/preservation.nix`) can run in parallel
- **User Story 3 (Phase 5)**: Depends on User Stories 1 and 2 (`core.base` updates) so removing duplicates from `modules/desktop/apps.nix` retains full capability parity
- **Polish (Phase 6)**: Depends on all user stories being complete

### Parallel Opportunities

- **US1**: T003 (`modules/core/base.nix`) and T004 (`modules/services/opencode.nix`) touch different files and can be executed in parallel.
- **US2**: T006 (`modules/core/base.nix`) and T007 (`modules/core/preservation.nix`) touch different files and can be executed in parallel.
- **US3**: T009 (`modules/desktop/apps.nix`) and T010 (`README.md`) touch different files and can be executed in parallel.

---

## Parallel Example: User Story 1

```bash
# Execute in parallel across distinct module files:
Task T003: "Add the Nix development and deployment CLI stack to environment.systemPackages in modules/core/base.nix"
Task T004: "Expand systemd.services.opencode-web.path in modules/services/opencode.nix"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (branch creation)
2. Complete Phase 2: Foundational (verify `.envrc` and `devshell.nix`)
3. Complete Phase 3: User Story 1 (`just`, `nh`, and Nix CLI stack in `core.base` + `opencode-web.service` `PATH`)
4. **STOP and VALIDATE**: Evaluate `nixosConfigurations.homelab` to confirm `just` and `nh` availability

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → `just` and `nh` available on `homelab` and in `opencode-web` (MVP)
3. Add User Story 2 → Automatic `.envrc` (`use flake`) activation via `direnv` + `nix-direnv` and persistent `~/.local/share/direnv` on `homelab`
4. Add User Story 3 → Deduplicate `desktop.apps` across workstations and update `README.md`
5. Complete Polish → Pass `nix fmt .`, `deadnix`, `statix check`, and `nix flake check`
