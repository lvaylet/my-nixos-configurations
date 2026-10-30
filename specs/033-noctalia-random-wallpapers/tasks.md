---

description: "Task list for Dynamic Random Noctalia Wallpapers on desktop-pc"
---

# Tasks: Dynamic Random Noctalia Wallpapers on `desktop-pc`

**Input**: Design documents from `/specs/033-noctalia-random-wallpapers/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/noctalia-wallpaper-contract.md, quickstart.md

**Tests**: No separate test suite was requested; verification is performed via `niri -- validate`, Nix flake evaluations, and repository quality gates (`just fmt`, `just lint`, `just check`).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize the versioned asset directory in the repository

- [X] T001 Create asset directory `assets/wallpapers/` with `.gitkeep` placeholder file

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Provision user-level Home Manager symlink for the wallpaper collection

**⚠️ CRITICAL**: Must be completed before user stories to provide the target path `~/Pictures/wallpapers`

- [X] T002 Declare `home.file."Pictures/wallpapers".source = ../../assets/wallpapers;` in `modules/desktop/session.nix`

**Checkpoint**: Foundation ready - `~/Pictures/wallpapers` is linked to `assets/wallpapers` in Home Manager

---

## Phase 3: User Story 1 - Versioned Wallpaper Directory & Startup Random Selection (Priority: P1) 🎯 MVP

**Goal**: Configure Noctalia to pick a random wallpaper from `~/Pictures/wallpapers` upon startup, eliminate stale `/nix/store/...` paths, and apply a Nord Polar Night (`#2e3440`) fallback background color.

**Independent Test**: Evaluate `nixosConfigurations.desktop-pc.config.home-manager.users.laurent.home.file."Pictures/wallpapers".source` and inspect `modules/desktop/dotfiles/noctalia.toml` to verify zero `/nix/store/` paths, `directory = "~/Pictures/wallpapers"`, `fill_color = "#2e3440"`, and `[wallpaper.automation]` with `order = "random"`, `recursive = true`, and `interval_seconds = 86400`.

### Implementation for User Story 1

- [X] T003 [US1] Remove obsolete static store paths `[wallpaper.default].path` and `[wallpaper.last].path` from `modules/desktop/dotfiles/noctalia.toml`
- [X] T004 [US1] Configure `[wallpaper]` with `directory = "~/Pictures/wallpapers"`, `enabled = true`, `fill_mode = "crop"`, `fill_color = "#2e3440"`, and `[wallpaper.automation]` with `enabled = true`, `order = "random"`, `recursive = true`, and `interval_seconds = 86400` in `modules/desktop/dotfiles/noctalia.toml`
- [X] T005 [US1] Evaluate `desktop-pc` Home Manager wallpaper path with `nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.home.file."Pictures/wallpapers".source`

**Checkpoint**: User Story 1 is complete and independently verifiable via Nix evaluation

---

## Phase 4: User Story 2 - On-Demand Wallpaper Randomization & Graphical Picker Shortcuts (Priority: P2)

**Goal**: Configure Niri keybindings to randomize wallpaper on demand (`Mod+Shift+W`) and toggle Noctalia's interactive wallpaper picker panel (`Mod+Ctrl+W`).

**Independent Test**: Validate the compositor configuration with `nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl` to confirm syntax and keybindings are strictly valid.

### Implementation for User Story 2

- [X] T006 [US2] Add `Mod+Shift+W` (`spawn "noctalia" "msg" "wallpaper-random"`) and `Mod+Ctrl+W` (`spawn "noctalia" "msg" "panel-toggle" "wallpaper"`) keybindings in `modules/desktop/dotfiles/niri/config.kdl`
- [X] T007 [US2] Validate Niri compositor configuration with `nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl`

**Checkpoint**: User Stories 1 and 2 are both complete and independently verifiable

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Update documentation, format code, and run quality checks across the repository

- [X] T008 [P] Update `README.md` to document the wallpaper repository directory (`assets/wallpapers`), Home Manager symlink (`~/Pictures/wallpapers`), and Niri wallpaper shortcuts (`Mod+Shift+W`, `Mod+Ctrl+W`)
- [X] T009 [P] Format all modified Nix, TOML, KDL, and Markdown files using `nix fmt .` (`just fmt`)
- [X] T010 Run repository linters (`just lint`) and hermetic sandbox checks (`just check` / `nix flake check`)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately (`assets/wallpapers/.gitkeep`).
- **Foundational (Phase 2)**: Depends on Setup (T001) - links `assets/wallpapers` in Home Manager (`modules/desktop/session.nix`).
- **User Story 1 (Phase 3)**: Depends on Foundational (T002) - configures Noctalia wallpaper automation and fallback color.
- **User Story 2 (Phase 4)**: Depends on Foundational (T002) - adds Niri shortcuts targeting Noctalia's wallpaper IPC. Can proceed in parallel with US1 as it touches a different file (`config.kdl`).
- **Polish (Phase 5)**: Depends on completion of User Stories 1 and 2.

### User Story Dependencies

- **User Story 1 (P1)**: Independent of User Story 2; touches `modules/desktop/dotfiles/noctalia.toml`.
- **User Story 2 (P2)**: Independent of User Story 1; touches `modules/desktop/dotfiles/niri/config.kdl`.

### Parallel Opportunities

- T008 (`README.md`) and T009 (`nix fmt .`) can execute in parallel during Polish.
- US1 (T003-T005 in `noctalia.toml`) and US2 (T006-T007 in `niri/config.kdl`) touch disjoint files and can execute concurrently once Phase 2 completes.

---

## Parallel Example: User Story 1 & User Story 2

```bash
# After Foundational (T002) completes, US1 and US2 touch different configuration files:
Task: "T003 [US1] Remove obsolete static store paths in modules/desktop/dotfiles/noctalia.toml"
Task: "T006 [US2] Add Mod+Shift+W and Mod+Ctrl+W keybindings in modules/desktop/dotfiles/niri/config.kdl"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (`T001` - `assets/wallpapers/.gitkeep`)
2. Complete Phase 2: Foundational (`T002` - `modules/desktop/session.nix`)
3. Complete Phase 3: User Story 1 (`T003`-`T005` - `modules/desktop/dotfiles/noctalia.toml`)
4. **STOP and VALIDATE**: Verify `nix eval` for `desktop-pc`
5. Deploy/test on `desktop-pc` (`just test configuration="desktop-pc"`)

### Incremental Delivery

1. Setup + Foundational → Repository asset directory and Home Manager symlink ready.
2. User Story 1 → Startup wallpaper randomization and Nord fallback functional (MVP).
3. User Story 2 → Interactive Niri keybindings for on-demand cycling and graphical picker functional.
4. Polish → Documentation updated in `README.md`, formatting and flake checks verified green.
