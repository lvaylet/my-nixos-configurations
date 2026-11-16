# Contract: Screenshot Workflow CLI Interface

**Feature**: `041-macos-screenshot-workflow` | **Date**: 2026-11-16 | **Spec**: [spec.md](../spec.md)

---

## 1. CLI Signature & Invocations

The screenshot workflow is exposed on the system PATH as `screenshot-tool`:

```text
Usage: screenshot-tool {region|screen|window}
```

### Arguments

| Argument | Description | Success Precondition | Failure Handling |
| --- | --- | --- | --- |
| `region` (or `area`) | Launches `slurp` for interactive drag-selection of a rectangular screen area, then captures via `grim`. | Valid Wayland compositor active. User drags a rectangle. | If user hits Escape, `slurp` returns non-zero; script exits with return code `0` and creates zero files. |
| `screen` (or `output`) | Captures the entire display canvas via `grim`. | Valid Wayland compositor active. | If `grim` fails, script exits with return code `1`. |
| `window` | Captures the focused window via Niri IPC (`niri msg action screenshot-window --path "$FILE"`). | Niri session active with at least one open window. | If Niri IPC fails or file is not written within 2s, script exits with return code `1`. |

---

## 2. Environment & System Contracts

- **Output Directory**: The tool guarantees creation of `~/Pictures/Screenshots` if missing (`mkdir -p`).
- **File Naming Pattern**: `~/Pictures/Screenshots/Screenshot from YYYY-MM-DD HH-MM-SS.png`.
- **Clipboard Output**: `wl-copy --type image/png < "$FILE"`.
- **Notification Daemon Contract**:
  - Notification Summary: `"Capture d'écran enregistrée"`
  - Notification Body: `"Enregistrée dans Screenshots et copiée dans le presse-papiers"`
  - Icon: File path of the screenshot (`-i "$FILE"`)
  - Action IDs:
    - `"annotate"`: Label `"Annoter"`
    - `"open"`: Label `"Ouvrir"`
    - `"delete"`: Label `"Supprimer"`
  - Blocking flag: `--wait` to synchronously capture chosen action key.

---

## 3. Exit Codes

| Exit Code | Meaning |
| --- | --- |
| `0` | Capture successful, or interactive region selection cleanly canceled by user. |
| `1` | Capture failed (invalid argument, screenshot binary failure, or write error). |
