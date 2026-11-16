# Quickstart Validation: macOS-like Screenshot Workflow

**Feature Branch**: `041-macos-screenshot-workflow` | **Date**: 2026-11-16 | **Spec**: [spec.md](spec.md)

---

## Prerequisites

- Local git clone checked out on branch `041-macos-screenshot-workflow`.
- Repository development shell activated (`direnv allow` or `nix develop`).
- For runtime testing: Wayland session running on `desktop-pc`.

---

## Validation Scenario 1: Nix Flake Evaluation & Shellcheck Static Analysis

Verify that the Nix configuration evaluates cleanly and that the `screenshot-tool` script passes `shellcheck` via `writeShellApplication`:

**Bash**:

```bash
just check
```

**Fish**:

```fish
just check
```

**Expected Outcome**: Nix flake check evaluates successfully with zero errors, confirming hermeticity and valid syntax.

---

## Validation Scenario 2: Area / Region Screenshot Execution (Interactive)

Verify that running `screenshot-tool region` launches `slurp`, captures the region, copies it to the clipboard, saves it to `~/Pictures/Screenshots`, and displays the notification:

**Bash**:

```bash
screenshot-tool region
```

**Fish**:

```fish
screenshot-tool region
```

**Test Steps**:

1. Drag-select a box on the screen.
2. Verify that a PNG file is created in `~/Pictures/Screenshots/`.
3. Check clipboard content:
   - Run `wl-paste --type image/png > /tmp/test-clip.png` and verify `/tmp/test-clip.png` is identical to the saved file.
4. Verify desktop notification with thumbnail appears.

**Expected Outcome**: Image saved, clipboard populated, thumbnail notification displayed.

---

## Validation Scenario 3: Clean Cancellation on Region Selection

Verify that canceling the region selection (pressing `Escape`) produces zero side effects:

**Bash**:

```bash
screenshot-tool region
```

**Fish**:

```fish
screenshot-tool region
```

**Test Steps**:

1. Press `Print` or run the command above.
2. Press `Escape` without selecting any area.

**Expected Outcome**: Script exits immediately with exit code `0`. No image file is written to `~/Pictures/Screenshots/`, clipboard is unchanged, and no notification is triggered.

---

## Validation Scenario 4: Full Screen & Window Captures

Verify full screen and window capture modes:

**Bash**:

```bash
screenshot-tool screen
screenshot-tool window
```

**Fish**:

```fish
screenshot-tool screen
screenshot-tool window
```

**Expected Outcome**: Both commands complete, persisting screenshots and displaying actionable notifications.

---

## Validation Scenario 5: Notification Actions (Satty Markup & Deletion)

Verify interactive actions on the notification:

1. **Annotate**: Click the "Annoter" button on the notification.
   - Verify Satty opens in a floating window displaying the captured screenshot.
   - Test markup tools (arrow, blur, text).
   - Press Enter or click Copy/Save. Verify Satty exits cleanly and image updates.
2. **Delete**: Click the "Supprimer" button on a new capture notification.
   - Verify the screenshot file is removed from `~/Pictures/Screenshots/`.
