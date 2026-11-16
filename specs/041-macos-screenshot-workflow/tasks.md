---

description: "Task list for implementing macOS-like screenshot workflow with Satty and notifications"
---

# Tasks: macOS-like Screenshot Workflow with Satty & Notifications

**Input**: Design documents from `/specs/041-macos-screenshot-workflow/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Not explicitly requested as TDD unit tests; verification is performed via `shellcheck` (enforced by `writeShellApplication`), `just lint-md` (`markdownlint-cli2`), `just check` (`nix flake check`), and manual end-to-end scenarios documented in `quickstart.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify repository branch isolation, existing Niri screenshot bindings, and desktop package baseline.

- [X] T001 [P] Verify dedicated feature branch `041-macos-screenshot-workflow` is active and inspect existing Niri screenshot bindings in `modules/desktop/dotfiles/niri/config.kdl`
- [X] T002 [P] Inspect existing desktop package definitions in `modules/desktop/session.nix` and `modules/desktop/apps.nix` to confirm module structure and package colocation patterns

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Package runtime Wayland screenshot dependencies (`grim`, `slurp`, `libnotify`, `satty`, `wl-clipboard`, `xdg-utils`) into the desktop configuration.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 Ensure `grim`, `slurp`, `libnotify`, and `satty` packages are available in desktop system packages in `modules/desktop/apps.nix`

**Checkpoint**: Core Wayland screenshot and annotation binaries are declared and available on `desktop-pc`.

---

## Phase 3: User Story 1 - Fast Area & Screen Capture with Dual Destination (Priority: P1) 🎯 MVP

**Goal**: Implement the core `screenshot-tool` script supporting interactive region selection (`region`), full screen (`screen`), and active window (`window`) with automatic saving to `~/Pictures/Screenshots/` and simultaneous clipboard copy (`wl-copy`).

**Independent Test**: Execute `screenshot-tool region` and cancel with `Escape` (verify clean exit code `0`, no files written, clipboard untouched); drag-select a region (verify file saved to `~/Pictures/Screenshots/` and image copied to clipboard via `wl-paste --type image/png`).

### Implementation for User Story 1

- [X] T004 [US1] Create the hermetic `screenshot-tool` script package using `pkgs.writeShellApplication` with runtime dependencies (`coreutils`, `grim`, `slurp`, `wl-clipboard`, `libnotify`, `satty`, `xdg-utils`, `niri`) in `modules/desktop/session.nix`
- [X] T005 [US1] Implement target directory initialization ("`mkdir -p ~/Pictures/Screenshots`") and timestamped output path generation ("`${target_dir}/Screenshot from ${timestamp}.png` where `timestamp` is formatted as `%Y-%m-%d %H-%M-%S`") in `modules/desktop/session.nix`
- [X] T006 [US1] Implement interactive region capture mode (`region` or `area`) invoking `slurp 2>/dev/null` ("If user hits Escape, `slurp` returns non-zero; script exits with return code `0` and creates zero files") and `grim -g "$GEOM" "$FILE"` in `modules/desktop/session.nix`
- [X] T007 [US1] Implement full screen capture mode (`screen` or `output`) invoking `grim "$FILE"` in `modules/desktop/session.nix`
- [X] T008 [US1] Implement active window capture mode (`window`) invoking `niri msg action screenshot-window --path "$FILE"` with polling loop ("Wait up to 2 seconds for non-empty file: `[ -s \"$FILE\" ]`") in `modules/desktop/session.nix`
- [X] T009 [US1] Implement automatic Wayland clipboard synchronization ("`wl-copy --type image/png < \"$FILE\"`") upon successful capture in `modules/desktop/session.nix`
- [X] T010 [US1] Update Niri keybindings in `modules/desktop/dotfiles/niri/config.kdl` to map `Print` to `spawn "screenshot-tool" "region"`, `Ctrl+Print` to `spawn "screenshot-tool" "screen"`, and `Alt+Print` to `spawn "screenshot-tool" "window"` with `hotkey-overlay-title` metadata

**Checkpoint**: User Story 1 (MVP) is complete — `desktop-pc` captures regions, screens, and windows, copies them to the clipboard, and saves them to `~/Pictures/Screenshots/` with clean cancellation handling.

---

## Phase 4: User Story 2 - macOS-Style Thumbnail Notification with Quick Actions (Priority: P2)

**Goal**: Display an interactive desktop notification with an image preview thumbnail and action buttons ("Annoter", "Ouvrir", "Supprimer") after every successful capture.

**Independent Test**: Take a screenshot and verify that a desktop notification appears with the image thumbnail; test that selecting "Ouvrir" opens the screenshots folder, selecting "Supprimer" removes the screenshot file, and dismissing or letting the notification expire leaves the file and clipboard intact.

### Implementation for User Story 2

- [X] T011 [US2] Add synchronous interactive notification dispatch using `notify-send --wait --app-name="Capture d'écran" --urgency=low --icon="$FILE" -A "annotate=Annoter" -A "open=Ouvrir" -A "delete=Supprimer"` in `modules/desktop/session.nix`
- [X] T012 [US2] Implement notification action handler for `"open"` invoking `xdg-open "$(dirname "$FILE")"` in `modules/desktop/session.nix`
- [X] T013 [US2] Implement notification action handler for `"delete"` invoking `rm -f "$FILE"` in `modules/desktop/session.nix`
- [X] T014 [US2] Handle notification timeout and dismissal gracefully ("If notification is closed, timed out, or dismissed without selecting an action, script exits cleanly leaving saved file and clipboard intact") in `modules/desktop/session.nix`

**Checkpoint**: User Stories 1 and 2 are complete — captures trigger an actionable macOS-style thumbnail notification.

---

## Phase 5: User Story 3 - Interactive Image Annotation & Markup with Satty (Priority: P3)

**Goal**: Integrate the Satty annotation editor into the notification workflow, configure its appearance and behavior declaratively, and set up floating window rules in Niri.

**Independent Test**: Click "Annoter" on the capture notification, verify that Satty opens in a floating window displaying the captured image with markup tools (arrows, text, blur), and confirm that saving or copying updates the image and clipboard.

### Implementation for User Story 3

- [X] T015 [US3] Implement notification action handler for `"annotate"` invoking `satty --filename "$FILE" --output-filename "$FILE" --early-exit all --copy-command wl-copy` in `modules/desktop/session.nix`
- [X] T016 [US3] Create declarative Satty configuration in `modules/desktop/session.nix` managing `xdg.configFile."satty/config.toml"` with `general.fullscreen = false`, `general.early-exit = true`, `general.initial-tool = "arrow"`, `general.copy-command = "wl-copy"`, `general.corner-roundness = 12`, and `font.family = "FiraCode Nerd Font"`
- [X] T017 [US3] Add Niri window rule in `modules/desktop/dotfiles/niri/config.kdl` matching `app-id=r#"^com\.gabm\.satty$"#` with `open-floating true` to ensure Satty opens as a floating dialog over the active workspace

**Checkpoint**: User Stories 1, 2, and 3 are complete — clicking "Annoter" opens Satty in a floating window with declarative styling and markup tools.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Update living documentation, verify formatting, and run full flake quality checks per `quickstart.md`.

- [X] T018 [P] Update `docs/reference/shell-aliases.md` to document the new screenshot shortcuts (`Print`, `Ctrl+Print`, `Alt+Print`), notification actions, and Satty annotation workflow
- [X] T019 [P] Run `just lint-md` and `just fix-md` to ensure all documentation files pass `markdownlint-cli2` with zero issues
- [X] T020 Run `just check` (`nix flake check`) to verify flake evaluation, module syntax, and `shellcheck` verification for `screenshot-tool`

---

## Dependencies & Execution Order

```text
Phase 1: Setup (T001, T002)
   │
   ▼
Phase 2: Foundational (T003)
   │
   ▼
Phase 3: User Story 1 - MVP (T004 -> T005 -> T006, T007, T008 -> T009 -> T010)
   │
   ▼
Phase 4: User Story 2 - Notifications (T011 -> T012, T013, T014)
   │
   ▼
Phase 5: User Story 3 - Satty Markup (T015, T016, T017)
   │
   ▼
Phase 6: Polish & Quality Gates (T018, T019, T020)
```

---

## Parallel Execution Opportunities

- **Phase 1**: `T001` and `T002` can execute concurrently (read-only inspection of independent files).
- **Phase 3 (within story)**: `T006` (region), `T007` (screen), and `T008` (window) implement distinct capture modes within the case statement.
- **Phase 4 (within story)**: `T012` (open action) and `T013` (delete action) can be implemented in parallel.
- **Phase 5 (within story)**: `T016` (Satty config) and `T017` (Niri window rule) touch different files and can run in parallel.
- **Phase 6**: `T018` (documentation update) and `T019` (markdown linting) can run concurrently.

---

## Implementation Strategy & MVP Scope

1. **MVP (User Story 1)**: Deliver tasks `T001` through `T010`. At this point, the user can press `Print`, `Ctrl+Print`, or `Alt+Print` to capture regions, screens, and windows with automatic dual persistence to `~/Pictures/Screenshots/` and the Wayland clipboard.
2. **Increment 2 (User Story 2)**: Deliver tasks `T011` through `T014`. Adds the macOS-style floating thumbnail desktop notification with "Ouvrir" and "Supprimer" actions.
3. **Increment 3 (User Story 3)**: Deliver tasks `T015` through `T017`. Connects the "Annoter" action to Satty with declarative configuration and floating window management.
4. **Final Polish**: Deliver tasks `T018` through `T020` to guarantee living documentation sync, markdown cleanliness, and clean `nix flake check` sandbox verification.
