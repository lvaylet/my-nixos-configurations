# Data Model: macOS-like Screenshot Workflow

**Feature**: `041-macos-screenshot-workflow` | **Date**: 2026-11-16 | **Spec**: [spec.md](spec.md)

---

## Entities & Schemas

### 1. `CaptureRequest`

Represents an invocation of the screenshot tool initiated by user input (keyboard shortcut or CLI invocation).

| Attribute | Type | Description | Invariants / Validation |
| --- | --- | --- | --- |
| `mode` | Enum (`region`, `screen`, `window`) | The capture target scope. | Required. Must be one of `region`, `screen`, `window`. |
| `target_dir` | Path (`string`) | Destination directory on persistent storage. | Default: `~/Pictures/Screenshots`. Automatically created if absent (`mkdir -p`). |
| `timestamp` | Datetime (`string`) | Capture initiation time formatted as `%Y-%m-%d %H-%M-%S`. | Required. Matches ISO-like filename friendly pattern. |
| `output_path` | Path (`string`) | Full filesystem destination path. | Invariant: `${target_dir}/Screenshot from ${timestamp}.png`. |

### 2. `ScreenshotArtifact`

Represents the physical image file persisted on disk.

| Attribute | Type | Description | Invariants / Validation |
| --- | --- | --- | --- |
| `file_path` | Path (`string`) | Absolute location of the screenshot file. | Must be readable and writable by user (`0644`). |
| `format` | String | Encoded image format. | Invariant: `image/png` (lossless 24-bit/32-bit PNG). |
| `size_bytes` | Integer | Byte size of the generated image. | Must be > 0 bytes. Empty files indicate capture failure and must be deleted. |

### 3. `ClipboardPayload`

Represents the bitmap data placed into the Wayland clipboard buffer.

| Attribute | Type | Description | Invariants / Validation |
| --- | --- | --- | --- |
| `mime_type` | String | Target Wayland MIME type. | Invariant: `image/png`. |
| `source` | Binary stream | Piped content of `ScreenshotArtifact`. | Validated via `wl-copy --type image/png`. |

### 4. `NotificationSession`

Represents the desktop notification presented to the user.

| Attribute | Type | Description | Invariants / Validation |
| --- | --- | --- | --- |
| `app_name` | String | Identifier of the originating utility. | Constant: `"Capture d'écran"`. |
| `title` | String | Notification summary title. | Constant: `"Capture d'écran enregistrée"`. |
| `body` | String | Informational message indicating storage and clipboard sync. | Describes file location and clipboard status. |
| `icon_path` | Path (`string`) | Path to the captured screenshot file for thumbnail preview. | Must point to a valid PNG file on disk. |
| `actions` | List of Tuples | Action identifiers and localized display labels. | `[("annotate", "Annoter"), ("open", "Ouvrir"), ("delete", "Supprimer")]`. |
| `timeout_ms` | Integer | Display duration before automatic dismissal. | Normal urgency (~5000ms) or compositor default. |

### 5. `SattyConfiguration`

Represents the declarative configuration for the Satty annotation application (`~/.config/satty/config.toml`).

| Section | Key | Type | Value | Description |
| --- | --- | --- | --- | --- |
| `[general]` | `fullscreen` | Boolean | `false` | Windowed floating mode. |
| `[general]` | `early-exit` | Boolean | `true` | Exit immediately after save/copy action. |
| `[general]` | `initial-tool` | String | `"arrow"` | Default tool on launch. |
| `[general]` | `copy-command` | String | `"wl-copy"` | Native Wayland clipboard command. |
| `[general]` | `corner-roundness`| Integer | `12` | Modern rounded markup boxes. |
| `[font]` | `family` | String | `"FiraCode Nerd Font"` | Font matching repository standard. |

---

## State Transitions & Workflow Lifecycle

```text
[User Triggers Keybind]
       │
       ▼
 [Mode Selection]
  ├── region ──> slurp selection
  │               ├── Canceled (Esc) ───────> [Clean Exit: Code 0, No Artifacts]
  │               └── Selected (Geometry) ──> grim -g "$GEOM" "$FILE"
  ├── screen ───────────────────────────────> grim "$FILE"
  └── window ───────────────────────────────> niri msg action screenshot-window --path "$FILE"
       │
       ▼
[Validate Non-Empty File: -s "$FILE"]
       │
       ├── Failure ─────────────────────────> [Clean Error Exit: Code 1]
       ▼
[Sync to Clipboard: wl-copy < "$FILE"]
       │
       ▼
[Emit Desktop Notification: notify-send --wait -i "$FILE" -A ...]
       │
       ├── Timeout / Dismissed ─────────────> [Complete: Artifact on disk & in clipboard]
       │
       ├── Action: "delete" ────────────────> rm -f "$FILE" ──> [Complete: Removed]
       │
       ├── Action: "open" ──────────────────> xdg-open "$(dirname "$FILE")" ──> [Complete]
       │
       └── Action: "annotate" ──────────────> satty --filename "$FILE"
                                                │
                                                └── User Edits / Saves / Copies ──> [Complete]
```
