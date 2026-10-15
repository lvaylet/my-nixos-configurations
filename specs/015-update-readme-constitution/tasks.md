---
description: "Task list for updating README.md for Constitution compliance and dual-shell (Bash/Fish) parity"
---

# Tasks: Update README for Constitution Compliance and Dual-Shell Parity

**Input**: Design documents from `/specs/015-update-readme-constitution/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/readme-compliance-contract.md`, `quickstart.md`

**Organization**: Tasks are grouped by user story to enable independent implementation and verification of each story increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (`[US1]`, `[US2]`, `[US3]`)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify authoritative NixOS/Home Manager shell configurations and Constitutional governance rules

- [X] T001 [P] Verify system-wide `environment.shellAliases`, default user shell (`pkgs.fish`), and `programs.fish` command-wrapping completions in `modules/core/base.nix`
- [X] T002 [P] Verify desktop Home Manager `programs.fish` aliases (`eza`, `bat`, `yazi`, `btop`, `ncdu`), `take` function, and `programs.starship` configuration in `modules/desktop/shell.nix`
- [X] T003 [P] Verify Principles VI–VII, Structural & Architectural Constraints, and the 7-stage Quality Gates & Verification Workflow in `.specify/memory/constitution.md`

---

## Phase 2: Foundational (Base Documentation Audit)

**Purpose**: Map existing `README.md` sections and command blocks against the Dual-Shell Command Transformation Matrix

**⚠️ CRITICAL**: Blocking prerequisite before modifying user story sections in `README.md`

- [X] T004 Audit all command blocks, alias tables, and architectural descriptions in `README.md` against the invariants (`Zero Fish Heredoc Invariant`, `Literal Secret Preservation Invariant`, `Constitutional Parity Invariant`) in `specs/015-update-readme-constitution/data-model.md`

**Checkpoint**: All target sections and command blocks in `README.md` mapped for update

---

## Phase 3: User Story 1 - Dual-Shell Parity for Operational & Provisioning Commands (Priority: P1) 🎯 MVP

**Goal**: Provide explicit **Bash** and **Fish** command variants for every operational instruction in `README.md` that uses shell-specific syntax (`export` vs `set -gx`, `${TARGET_IP}` vs `$TARGET_IP`, and `<< 'EOF'` heredocs vs single-quoted `printf '%s\n' ... | sudo tee`) while keeping syntactically identical commands concise

**Independent Test**: Verify that all shell-specific command blocks in `README.md` include both `bash` and `fish` code blocks with zero `<<` heredocs in Fish snippets, and validate syntax using `bash -n` and `fish --no-execute` per `specs/015-update-readme-constitution/quickstart.md`

### Implementation for User Story 1

- [X] T005 [US1] Update Homelab Step 3 (*Install Remotely with `nixos-anywhere`*) to provide explicit **Bash** (`export TARGET_IP=<target-ip>`, `just install-homelab "${TARGET_IP}"`, `nix run github:nix-community/nixos-anywhere -- --flake .#homelab "root@${TARGET_IP}"`) and **Fish** (`set -gx TARGET_IP <target-ip>`, `just install-homelab "$TARGET_IP"`, `nix run github:nix-community/nixos-anywhere -- --flake .#homelab "root@$TARGET_IP"`) variants in `README.md`
- [X] T006 [US1] Update Homelab Step 4 (*Verify and Deploy Subsequent Updates*) to provide explicit **Bash** (`ssh "laurent@${TARGET_IP}"`, `just deploy-homelab target="${TARGET_IP}"`, `just test-homelab target="${TARGET_IP}"`) and **Fish** (`ssh "laurent@$TARGET_IP"`, `just deploy-homelab target="$TARGET_IP"`, `just test-homelab target="$TARGET_IP"`) variants in `README.md`
- [X] T007 [US1] Update Caddy Step 2 (*Cloudflare API Token Provisioning*) to provide explicit **Bash** (`sudo tee /persistent/var/lib/caddy/cloudflare.env << 'EOF'`) and **Fish** (single-quoted `printf '%s\n' 'CLOUDFLARE_API_TOKEN=<your-cloudflare-api-token>' | sudo tee /persistent/var/lib/caddy/cloudflare.env`) variants preserving literal secret values and enforcing `0600` permissions in `README.md`
- [X] T008 [US1] Update WAHA Step 4 (*WAHA Credentials & Initial WhatsApp Session Setup*) to provide explicit **Bash** (`sudo tee /persistent/var/lib/waha/waha.env << 'EOF'`) and **Fish** (single-quoted `printf '%s\n' ... | sudo tee /persistent/var/lib/waha/waha.env`) variants preserving literal secret values and enforcing `0600` permissions in `README.md`

**Checkpoint**: User Story 1 complete — 100% of shell-specific operational and secret-provisioning commands in `README.md` provide copy-pasteable Bash and Fish variants

---

## Phase 4: User Story 2 - Accurate Documentation of Host Shell Duality & Aliases (Priority: P2)

**Goal**: Document the two-tier Bash/Fish shell architecture across hosts (`laurent` vs `root`/ISO, system-wide `environment.shellAliases`, Fish `complete -w` autocompletions, and desktop Home Manager Fish aliases/functions) in `README.md`

**Independent Test**: Compare the Shell Environment & Aliases section of `README.md` against `modules/core/base.nix` and `modules/desktop/shell.nix` to confirm 100% coverage of system-wide and desktop aliases

### Implementation for User Story 2

- [X] T009 [US2] Update the Shell Aliases section introduction in `README.md` to explain the Bash and Fish duality across hosts (`laurent` using `pkgs.fish` with native `complete -c ... -w ...` command-wrapping completions vs `root` and installer ISO using Bash, both sharing `environment.shellAliases` from `modules/core/base.nix`)
- [X] T010 [US2] Complete the Git Aliases table in `README.md` to include all system-wide aliases from `modules/core/base.nix` (adding `gcan!`, `grba`, `grbc`, `gstd`, `gclean`, and exact command flags)
- [X] T011 [US2] Add a Desktop Interactive Fish Shell (`modules/desktop/shell.nix`) subsection in `README.md` documenting the `eza` directory listing aliases (`ls`, `ll`, `llt`, `la`, `lat`), CLI tool aliases (`cat` -> `bat`, `y` -> `yazi`, `b` -> `btop`, `d` -> `ncdu`, `c` -> `clear`, `x` -> `exit`, `r` -> reload config), the `take` helper function, and Starship prompt integration

**Checkpoint**: User Story 2 complete — host shell duality, system-wide aliases, and desktop Fish extensions are fully documented in `README.md`

---

## Phase 5: User Story 3 - Full Alignment with Constitutional Architecture & Quality Gates (Priority: P2)

**Goal**: Align `README.md`'s Architecture tree and development/verification workflow with `.specify/memory/constitution.md` (v2.1.0)

**Independent Test**: Verify that `NNN desktop session` is replaced with the Niri/Noctalia desktop stack in `README.md` and that all 7 Constitutional Quality Gates are documented

### Implementation for User Story 3

- [X] T012 [US3] Update the `modules/desktop/` summary in the Architecture tree of `README.md` from `NNN desktop session` to `Niri Wayland session, Noctalia shell, WezTerm, Fish shell, fonts, editors, audio, GPU`
- [X] T013 [US3] Add the Quality Gates & Verification Workflow section in `README.md` documenting the 7 constitutional gates from `.specify/memory/constitution.md` (1. Dedicated Branch & Pull Request isolation, 2. `README.md` Synchronization & Dual-Shell Parity, 3. `just fmt`, 4. `just lint` / `just fix`, 5. `just check`, 6. `just test`, and 7. `just switch` / `just boot`)

**Checkpoint**: User Story 3 complete — `README.md` is 100% aligned with the architecture and governance workflows of Constitution v2.1.0

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Shell syntax validation, formatting, static analysis, and hermetic flake checks

- [X] T014 Validate syntax of all Bash and Fish command patterns in `README.md` using `bash -n` and `fish --no-execute` per `specs/015-update-readme-constitution/quickstart.md`
- [X] T015 [P] Run `just fmt` (`alejandra`) and `just lint` (`deadnix`, `statix check`) across the repository
- [X] T016 Run hermetic pre-commit and secret/hygiene checks via `just check` (`nix flake check`) per `specs/015-update-readme-constitution/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — `T001`, `T002`, and `T003` can run in parallel
- **Foundational (Phase 2)**: Depends on Setup completion (`T004`)
- **User Stories (Phase 3–5)**: Depend on Foundational phase completion
  - **User Story 1 (P1 - Phase 3)**: Updates operational and secret-provisioning blocks with dual Bash/Fish variants (`T005`–`T008`)
  - **User Story 2 (P2 - Phase 4)**: Updates Shell Environment & Aliases section (`T009`–`T011`)
  - **User Story 3 (P2 - Phase 5)**: Updates Architecture tree and adds Constitutional Quality Gates section (`T012`–`T013`)
- **Polish (Phase 6)**: Depends on Phases 3–5 completion (`T014`–`T016`)

### Parallel Opportunities

- **Phase 1 (Setup)**: `T001` [P] (`modules/core/base.nix`), `T002` [P] (`modules/desktop/shell.nix`), and `T003` [P] (`.specify/memory/constitution.md`) read independent files and can run in parallel.
- **Phase 6 (Polish)**: `T014` (shell syntax validation) and `T015` [P] (`just fmt` / `just lint`) can run before the final `T016` (`just check`) gate.

---

## Parallel Example: Setup Phase

```bash
# Phase 1: Verify reference modules and constitution in parallel
Task: "T001 [P] Verify system-wide environment.shellAliases, default user shell (pkgs.fish), and programs.fish command-wrapping completions in modules/core/base.nix"
Task: "T002 [P] Verify desktop Home Manager programs.fish aliases, take function, and programs.starship configuration in modules/desktop/shell.nix"
Task: "T003 [P] Verify Principles VI–VII, Structural & Architectural Constraints, and the 7-stage Quality Gates & Verification Workflow in .specify/memory/constitution.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only - P1)

1. Complete Phase 1: Setup (`T001`–`T003`)
2. Complete Phase 2: Foundational (`T004`)
3. Complete Phase 3: User Story 1 (`T005`–`T008` — dual Bash/Fish operational and secret provisioning commands in `README.md`)
4. **STOP and VALIDATE**: Run `bash -n` and `fish --no-execute` on the updated command blocks
5. Complete Phase 4: User Story 2 (`T009`–`T011` — Bash/Fish host duality, complete Git aliases, and desktop Fish shell section)
6. Complete Phase 5: User Story 3 (`T012`–`T013` — Niri/Noctalia architecture description and Constitutional Quality Gates)
7. Complete Phase 6: Polish (`T014`–`T016` — `bash -n`, `fish --no-execute`, `just fmt`, `just lint`, `just check`)
