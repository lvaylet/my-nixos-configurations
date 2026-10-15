# Technical Research: Update Niri Configuration with Upstream Defaults and Documentation

**Branch**: `014-update-niri-config` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This document consolidates the technical analysis and decisions for merging Niri's official `resources/default-config.kdl` with the repository's personal Niri + Noctalia + WezTerm configuration in `modules/desktop/dotfiles/niri/config.kdl`.

---

## 1. Base Template & Comment Preservation Strategy

### Decision

Use the official upstream `https://github.com/niri-wm/niri/blob/main/resources/default-config.kdl` file as the structural backbone, preserving 100% of its top-level sections, inline `//` documentation comments, wiki URLs (`https://niri-wm.github.io/niri/...`), and `/-` commented-out KDL example nodes (`/-output "eDP-1"`, `/-window-rule`), while injecting the user's specific active parameters in their respective sections.

### Rationale

- **Self-Documenting Configuration**: Upstream `default-config.kdl` is designed as an interactive reference manual explaining KDL syntax (`/-` node commenting), libinput flags, output logical scaling/positioning, focus-ring/border gradient rendering, shadow CSD behavior, window rules, and keybinding properties (`allow-when-locked`, `repeat=false`, `cooldown-ms`, `allow-inhibiting=false`, `hotkey-overlay-title`).
- **Complete Feature Coverage**: Starting from upstream's canonical file guarantees no standard Niri sections (`mouse`, `trackpoint`, `/-output`, `shadow`, `struts`, `hotkey-overlay`, `screenshot-path`, `animations`, `window-rule`) or standard binds (`toggle-overview`, `show-hotkey-overlay`, column consumption/expulsion, preset width/height cycling, floating/tabbed toggles, mouse wheel scrolling, screenshots, monitor power-off) are accidentally omitted.

### Alternatives Considered

- **Appending a few comments to the existing 110-line `config.kdl`**: Would leave out numerous upstream sections (`/-output`, `shadow`, `struts`, `animations`, `screenshot-path`, `window-rule`, mouse-wheel binds, floating/tabbed binds) and fail `FR-001` / `SC-001`. Rejected.

---

## 2. Input & Layout Personalization Merge

### Decision

Preserve the user's active `input` and `layout` settings within the upstream blocks while keeping upstream's surrounding comments and fallback/example options:

1. **`input.keyboard`**:
   - Keep `layout "us,fr"`, `variant "intl,"`, and `options "grp:alt_shift_toggle"` inside `xkb { ... }`, alongside upstream's explanatory comments.
   - Enable `numlock` on startup as in upstream `default-config.kdl`.
2. **`input.touchpad`, `mouse`, `trackpoint`**:
   - Keep `tap` and `natural-scroll` active in `touchpad` along with all commented-out libinput examples (`off`, `dwt`, `dwtp`, `drag`, `drag-lock`, `accel-speed`, `accel-profile`, `pinch-sensitivity`, `scroll-method`, `disabled-on-external-mouse`).
   - Include `mouse`, `trackpoint`, `// warp-mouse-to-focus`, and `// focus-follows-mouse max-scroll-amount="0%"` from upstream.
3. **`layout`**:
   - Keep `gaps 8` (user preference vs upstream `16`).
   - Keep `center-focused-column "never"`.
   - Keep `preset-column-widths` with `proportion 0.33333`, `proportion 0.5`, `proportion 0.66667`, and `proportion 1.0` (preserving the user's full-width preset alongside upstream's `// fixed 1920` comment).
   - Keep `default-column-width { proportion 0.5; }` (with upstream's `// default-column-width {}` comment).
   - Keep `focus-ring` with `width 2`, `active-color "#cba6f7"`, and `inactive-color "#45475a"` (Catppuccin Mocha palette), while preserving upstream's comments on color formats and `active-gradient` / `inactive-gradient`.
   - Keep `border` disabled via `off`, while including upstream's reference properties (`width 4`, `active-color "#ffc87f"`, `inactive-color "#505050"`, `urgent-color "#9b0000"`, and gradient comments) inside the block so enabling borders later only requires commenting out `off`.
   - Include upstream's `shadow` and `struts` blocks and comments verbatim.
4. **Top-Level Settings**:
   - Keep `prefer-no-csd` active (uncommented) with upstream's detailed explanation.
   - Include `hotkey-overlay`, `screenshot-path`, and `animations` blocks from upstream.

### Rationale

- Retains the exact visual look and feel (`8px` gaps, `2px` Catppuccin Mauve focus ring, no CSD, `1.0` preset width) and bilingual keyboard behavior while making all advanced layout sub-blocks (`shadow`, `struts`, gradients, `border` parameters) immediately available for future tweaking.

---

## 3. Window Rules (`window-rule`) for WezTerm & Firefox

### Decision

Include the upstream `window-rule` blocks, matching both `^org\.wezfurlong\.wezterm$` and `"wezterm"` in the WezTerm rule:

```kdl
window-rule {
    match app-id=r#"^org\.wezfurlong\.wezterm$"#
    match app-id="wezterm"
    default-column-width {}
}
```

Along with the active Firefox Picture-in-Picture floating rule (`match app-id=r#"firefox$"# title="^Picture-in-Picture$"`) and the two commented-out `/-window-rule` examples (password manager screen-capture block-out and rounded corners).

### Rationale

- Upstream specifically includes the WezTerm `window-rule` (`default-column-width {}`) to work around WezTerm's initial configure bug in Niri. Adding `match app-id="wezterm"` alongside `^org\.wezfurlong\.wezterm$` ensures the rule matches regardless of whether WezTerm sets its Wayland `app-id` to the reverse-DNS name or short name.

---

## 4. Keybinding Harmonization (Noctalia, WezTerm & Upstream Niri Conventions)

### Decision

Harmonize the `binds` section according to the clarified specification (`FR-008`, `FR-009`, `FR-010`):

1. **Terminal & Noctalia Shell Binds (`FR-008`)**:
   - `Mod+Return hotkey-overlay-title="Open a Terminal: wezterm" { spawn "wezterm"; }`
   - `Mod+T hotkey-overlay-title="Open a Terminal: wezterm" { spawn "wezterm"; }`
   - `Mod+Space hotkey-overlay-title="Run an Application: noctalia launcher" { spawn "noctalia" "msg" "panel-toggle" "launcher"; }`
   - `Mod+D hotkey-overlay-title="Run an Application: noctalia launcher" { spawn "noctalia" "msg" "panel-toggle" "launcher"; }`
   - `Mod+N hotkey-overlay-title="Toggle Control Center: noctalia" { spawn "noctalia" "msg" "panel-toggle" "control-center"; }`
   - `Mod+Shift+E hotkey-overlay-title="Session Menu: noctalia" { spawn "noctalia" "msg" "panel-toggle" "session"; }`
   - `Super+Alt+L hotkey-overlay-title="Lock the Screen: noctalia" { spawn "noctalia" "msg" "session" "lock"; }`
2. **Directional & Workspace Modifiers (`FR-009` Clarification 1)**:
   - `Mod+Left/Down/Up/Right` and `Mod+H/J/K/L`: Focus column/window (`focus-column-left`, `focus-window-down`, `focus-window-up`, `focus-column-right`).
   - `Mod+Ctrl+Left/Down/Up/Right` and `Mod+Ctrl+H/J/K/L`: Move column/window within workspace (`move-column-left`, `move-window-down`, `move-window-up`, `move-column-right`).
   - `Mod+Shift+Left/Down/Up/Right` and `Mod+Shift+H/J/K/L`: Focus monitor (`focus-monitor-left/down/up/right`).
   - `Mod+Shift+Ctrl+Left/Down/Up/Right` and `Mod+Shift+Ctrl+H/J/K/L`: Move column to monitor (`move-column-to-monitor-left/down/up/right`).
   - `Mod+1..9`: `focus-workspace 1..9`.
   - `Mod+Ctrl+1..9`: `move-column-to-workspace 1..9` (upstream default).
   - `Mod+Shift+1..9`: `move-window-to-workspace 1..9` (preserved user bind).
3. **Escape Hatch & Quit (`FR-008` Clarification 2 & `FR-009`)**:
   - `Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }` (upstream default).
   - `Ctrl+Alt+Delete { quit; }` (upstream default; `Mod+Shift+E` opens Noctalia's session panel, while `// Mod+Shift+E { quit; }` is documented in comments).
4. **Audio, Media, Brightness & Hardware Keys (`FR-010`)**:
   - Keep `XF86AudioRaiseVolume` (`5%+ -l 1.0`), `XF86AudioLowerVolume` (`5%-`), `XF86AudioMute`, and `XF86AudioMicMute` with `allow-when-locked=true`.
   - Add upstream `XF86AudioPlay/Pause/Stop/Prev/Next` (`playerctl`), `XF86MonBrightnessUp/Down` (`brightnessctl`), `XF86TouchpadToggle` (`toggle-touchpad`), and `Super+Alt+S` (`orca`).

### Rationale

- Eliminates all duplicate keybinding collisions while preserving 100% of Noctalia/WezTerm integration and unlocking 100% of upstream Niri's multi-monitor, column/window sizing, overview, tabbed/floating, mouse-wheel, and screenshot shortcuts.
