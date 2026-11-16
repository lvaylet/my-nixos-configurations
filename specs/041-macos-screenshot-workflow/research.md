# Phase 0 Research: macOS-like Screenshot Workflow with Satty & Desktop Notifications

**Feature**: `041-macos-screenshot-workflow` | **Date**: 2026-11-16 | **Spec**: [spec.md](spec.md)

---

## Technical Context & Decisions

### Decision 1: Wayland Capture Backend (`grim` + `slurp` + `niri msg`)

- **Decision**: Use `grim` and `slurp` for interactive region capture and full-screen output capture, and `niri msg action screenshot-window --path` for focused window capture.
- **Rationale**:
  - `slurp` provides the standard Wayland region selection UI with clean exit codes (exits with code 1 upon cancellation with Escape), allowing reliable cancellation handling without orphan files.
  - `grim -g "$(slurp)"` captures pixel-perfect rectangles across multi-monitor setups and mixed fractional scaling without compositor distortion.
  - For active window capture, Wayland compositors isolate client geometry for security; `niri msg action screenshot-window --path "$FILE"` uses Niri's native IPC to capture the exact focused window boundaries cleanly without relying on client guessing or manual window cropping.
- **Alternatives Considered**:
  - *Niri built-in interactive UI (`niri msg action screenshot`)*: Does not output to stdout or provide a synchronous script exit callback upon user cancellation, leading to fragile polling or inotify loops.
  - *Flameshot (`flameshot gui`)*: Has known multi-monitor and Wayland protocol glitches on wlroots/smithay compositors, whereas `grim` + `slurp` is rock-solid and native.

### Decision 2: Annotation Editor (`satty`)

- **Decision**: Package and integrate `satty` (v0.22.0) via `pkgs.satty`, configured with floating window behavior in Niri.
- **Rationale**:
  - `satty` is written in Rust using GTK4 and Libadwaita, matching modern Wayland desktop aesthetics.
  - It includes all key markup tools required by macOS Markup: arrows, text, rectangle, ellipse, line, highlight, step counters, and crucial redaction tools (blur/pixelate).
  - Fast CLI startup: `satty --filename "$FILE" --output-filename "$FILE" --early-exit all --copy-command wl-copy`.
  - Configurable in `xdg.configFile."satty/config.toml"` with FiraCode Nerd Font and sensible defaults.
- **Alternatives Considered**:
  - *Swappy (`pkgs.swappy`)*: Older GTK3 UI, lacks step counters, less active development.
  - *Ksnip (`pkgs.ksnip`)*: Heavier Qt dependency, slower startup, windowed canvas rather than streamlined markup HUD.

### Decision 3: macOS-Style Notification Mechanism (`notify-send` with Actions)

- **Decision**: Use `libnotify`'s `notify-send` with `-A` (actions), `-i` (image preview icon), and `-w` (wait).
- **Rationale**:
  - `notify-send` supports interactive action buttons (`-A "annotate=Annoter" -A "open=Ouvrir" -A "delete=Supprimer"`).
  - When `--wait` is specified, `notify-send` blocks until the user either clicks an action (outputting the action key to stdout) or the notification expires/dismisses.
  - The notification server (Noctalia / Freedesktop notification daemon) renders the captured screenshot as a visual thumbnail icon, perfectly mirroring the macOS floating thumbnail experience.
  - Timeout or dismissal gracefully exits without side effects; the saved screenshot remains on disk and in the clipboard.
- **Alternatives Considered**:
  - *Custom GTK/Eww overlay daemon*: High implementation complexity and maintenance overhead for a problem already solved by the Freedesktop notification specification and Noctalia.
  - *Immediate Satty opening*: Violates the user's explicit preference (Q1: Option A) for a non-intrusive, notification-driven workflow.

### Decision 4: Packaging and Hermeticity (`writeShellApplication`)

- **Decision**: Wrap the workflow script in `pkgs.writeShellApplication` named `screenshot-tool` placed in `modules/desktop/session.nix` (or `apps.nix`) with explicit `runtimeInputs`.
- **Rationale**:
  - Adheres to Constitution Principle I (Declarative & Hermetic) and Principle III (Shift-Left Quality & Static Analysis).
  - Automatically runs `shellcheck` during `nix flake check` (`just check`), preventing shell scripting regressions.
  - Bundles `coreutils`, `grim`, `slurp`, `wl-clipboard`, `libnotify`, `satty`, `xdg-utils`, and `niri` in a hermetic runtime PATH.
- **Alternatives Considered**:
  - *Raw unverified shell script in dotfiles*: Prone to PATH lookup failures and missing dependencies on clean installs.

### Decision 5: Keybinding Scheme in Niri

- **Decision**: Replace default screenshot actions in `modules/desktop/dotfiles/niri/config.kdl` with calls to `screenshot-tool`:
  - `Print { spawn "screenshot-tool" "region"; }`
  - `Ctrl+Print { spawn "screenshot-tool" "screen"; }`
  - `Alt+Print { spawn "screenshot-tool" "window"; }`
- **Rationale**:
  - Directly fulfills Q2: Option B (standard Linux PrintScreen bindings).
  - Replaces Niri's un-notified built-in capture with the macOS-like notification & Satty workflow.
- **Alternatives Considered**:
  - *Mod+Shift+3/4/5*: Kept optional or omitted per user preference for standard Linux keybindings.
