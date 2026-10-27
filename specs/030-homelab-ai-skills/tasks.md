---

description: "Task list for AI Skills Provisioning and Package Runners on Homelab"
---

# Tasks: AI Skills Provisioning and Package Runners on Homelab

**Input**: Design documents from `/specs/030-homelab-ai-skills/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: No separate test suite was requested; verification is performed via Nix flake evaluations and quality gates (`just fmt`, `just lint`, `just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create dedicated feature branch and inspect baseline configuration

- [X] T001 Ensure repository is on dedicated feature branch `030-homelab-ai-skills` per Constitutional Principle VII

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Declare and lock upstream AI skill repository flake inputs required by user stories

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 Add `mattpocock-skills` (`url = "github:mattpocock/skills"; flake = false;`) and `addyosmani-agent-skills` (`url = "github:addyosmani/agent-skills"; flake = false;`) to `inputs` in `flake.nix`
- [X] T003 Lock the new `mattpocock-skills` and `addyosmani-agent-skills` inputs in `flake.lock` using `nix flake lock`

**Checkpoint**: Foundation ready - upstream skill repositories are pinned in `flake.lock`

---

## Phase 3: User Story 1 - Declarative AI Agent Skills Across Hosts (Priority: P1) 🎯 MVP

**Goal**: Provision the 27 published skills from Matt Pocock (`skills/engineering/*` and `skills/productivity/*`) and the 25 skills from Addy Osmani (`skills/*` plus `references/`) declaratively across `homelab`, `desktop-pc`, and `macbook-air-m4-15`.

**Independent Test**: Build and inspect the `opencode-skills` derivation and verify that `nixosConfigurations.homelab`, `nixosConfigurations.desktop-pc`, and `darwinConfigurations.macbook-air-m4-15` evaluate cleanly with all 52 skills linked into OpenCode's skills configuration.

### Implementation for User Story 1

- [X] T004 [US1] Create a shared `mkOpencodeSkillsDir` helper in `modules/services/opencode.nix` (using `pkgs.runCommandLocal "opencode-skills"`) that symlinks `${inputs.addyosmani-agent-skills}/skills/*`, `${inputs.addyosmani-agent-skills}/references`, `${inputs.mattpocock-skills}/skills/engineering/*`, and `${inputs.mattpocock-skills}/skills/productivity/*` into `$out`, enforcing the `data-model.md` validation rule: "Every linked skill directory MUST contain a valid `SKILL.md` file; build MUST fail if duplicate skill directory names collide unexpectedly"
- [X] T005 [US1] Provision the declarative skills directory on headless NixOS hosts (`homelab`) via `systemd.tmpfiles.rules` (`L+ /home/${vars.userName}/.config/opencode/skills - - - - ${opencodeSkillsDir}` when Home Manager is not enabled) in `modules/services/opencode.nix`
- [X] T006 [US1] Set `xdg.configFile."opencode/skills"` (`{ source = opencodeSkillsDir; recursive = true; }`) in the `homeManager` aspect of `modules/services/opencode.nix` so `desktop-pc` and `macbook-air-m4-15` share the exact same declarative skills bundle

**Checkpoint**: User Story 1 is complete and independently verifiable via `nix build` / `nix eval`

---

## Phase 4: User Story 2 - Ad-Hoc Package & Skill Execution with `npm`, `npx`, `uv`, and `uvx` on Homelab (Priority: P2)

**Goal**: Provide `npm`, `npx` (via `pkgs.nodejs`) and `uv`, `uvx` (via `pkgs.uv`) in interactive shells and the `opencode-web` service on `homelab` (and across hosts), and persist `~/.agents` across ephemeral root reboots on `homelab`.

**Independent Test**: Evaluate `nixosConfigurations.homelab` to confirm `nodejs` and `uv` are present in `environment.systemPackages` and `systemd.services.opencode-web.path`, and that `".agents"` is included in `preservation.preserveAt."/persistent".users.laurent.directories`.

### Implementation for User Story 2

- [X] T007 [US2] Add `pkgs.nodejs` (`node`, `npm`, `npx`) and `pkgs.uv` (`uv`, `uvx`) to `environment.systemPackages` (in `nixos` and `darwin`), `systemd.services.opencode-web.path` (in `nixos`), and `programs.opencode.extraPackages` (in `homeManager`) in `modules/services/opencode.nix`
- [X] T008 [US2] Add `".agents"` to `preservation.preserveAt."/persistent".users.${vars.userName}.directories` in `modules/services/opencode.nix` so global ad-hoc skills installed via `npx skills add -g` persist across `homelab` reboots

**Checkpoint**: User Stories 1 and 2 are complete and independently verifiable

---

## Phase 5: User Story 3 - Architectural Guidance & Living Documentation Synchronization (Priority: P3)

**Goal**: Document the declarative AI skills setup (Matt Pocock & Addy Osmani) and the availability of `npm`, `npx`, `uv`, and `uvx` on `homelab` in `README.md` with Bash and Fish parity.

**Independent Test**: Verify `README.md` updates and pass all repository quality gates (`just fmt`, `just lint`, `just check`).

### Implementation for User Story 3

- [X] T009 [US3] Update `README.md` (in the `macbook-air-m4-15` shared capabilities, `Homelab Hosted Services` table, and `7. OpenCode v2 Initial Setup & Access` sections) to document the declaratively provisioned skills (`mattpocock/skills` and `addyosmani/agent-skills`), the `~/.agents` persistence, and the availability of `npm`, `npx`, `uv`, and `uvx` with Bash and Fish examples

**Checkpoint**: All user stories are complete and documented

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Run formatting, static analysis, flake checks, and host evaluations across all targets

- [X] T010 Run `just fmt` (`nix fmt .`) and `just lint` (`deadnix` and `statix check`) across the repository and fix any formatting or lint issues in `flake.nix`, `modules/services/opencode.nix`, and `README.md`
- [X] T011 Run `just check` (`nix flake check`) and verify that `homelab`, `desktop-pc`, and `macbook-air-m4-15` configurations evaluate and build the `opencode-skills` derivation cleanly per `specs/030-homelab-ai-skills/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS User Story 1
- **User Story 1 (Phase 3 - P1)**: Depends on Foundational (Phase 2) completion (`flake.nix` and `flake.lock` inputs)
- **User Story 2 (Phase 4 - P2)**: Modifies `modules/services/opencode.nix` after User Story 1
- **User Story 3 (Phase 5 - P3)**: Can run after User Stories 1 and 2 are defined; modifies `README.md`
- **Polish (Phase 6)**: Depends on Phases 1–5 completion

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Phase 2 (`mattpocock-skills` and `addyosmani-agent-skills` flake inputs)
- **User Story 2 (P2)**: Independent functionally from US1, sequenced after US1 because both touch `modules/services/opencode.nix`
- **User Story 3 (P3)**: Documents US1 and US2 in `README.md`

### Parallel Opportunities

- User Story 3 (`README.md` documentation in T009) touches a different file from `modules/services/opencode.nix` and can be prepared in parallel with US1/US2 implementation.

---

## Parallel Example: User Story 1 & User Story 3

```bash
# After Phase 2 (flake.nix & flake.lock) completes:
Task: "T004-T006 [US1] Implement declarative skills in modules/services/opencode.nix"
Task: "T009 [US3] Document declarative skills and npm/npx/uv/uvx in README.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`030-homelab-ai-skills` branch)
2. Complete Phase 2: Foundational (`flake.nix` + `flake.lock` for `mattpocock-skills` and `addyosmani-agent-skills`)
3. Complete Phase 3: User Story 1 (Declarative skills derivation and linking in `modules/services/opencode.nix`)
4. **STOP and VALIDATE**: Verify that all 52 skills from Matt Pocock and Addy Osmani are linked into `~/.config/opencode/skills`

### Incremental Delivery

1. Complete Setup + Foundational → Flake inputs pinned
2. Add User Story 1 → Declarative skills available across `homelab`, `desktop-pc`, and `macbook-air-m4-15`
3. Add User Story 2 → `npm`, `npx`, `uv`, `uvx` available on `homelab` (shell + `opencode-web`) and `~/.agents` persisted
4. Add User Story 3 + Polish → `README.md` updated and `just fmt`, `just lint`, `just check` passing with exit code 0
