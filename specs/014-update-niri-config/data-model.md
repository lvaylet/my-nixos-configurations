# Data Model: Update Niri Configuration with Upstream Defaults and Documentation

**Branch**: `014-update-niri-config` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This document formalizes the configuration structure, section schemas, custom overrides, and invariants for `modules/desktop/dotfiles/niri/config.kdl`.

---

## 1. Configuration Entities & Section Schemas

### Entity 1: Niri Configuration File (`modules/desktop/dotfiles/niri/config.kdl`)

Deployed declaratively via Home Manager (`xdg.configFile."niri/config.kdl".source = ./dotfiles/niri/config.kdl` in `modules/desktop/session.nix`).

| Top-Level Section | Upstream Baseline | Active Customizations / Overrides | Status |
| --- | --- | --- | --- |
| `input` | `keyboard` (`xkb`, `numlock`), `touchpad` (`tap`, `natural-scroll`), `mouse`, `trackpoint`, commented `warp-mouse-to-focus` & `focus-follows-mouse` | `xkb` sets `layout "us,fr"`, `variant "intl,"`, `options "grp:alt_shift_toggle"`; `numlock` active; `touchpad` sets `tap` and `natural-scroll` | Active + Full Comments |
| `/-output "eDP-1"` | Commented-out (`/-`) example node with `mode`, `scale`, `transform`, `position` | Preserved verbatim as commented-out (`/-`) reference block | Commented Example (`/-`) |
| `layout` | `gaps`, `center-focused-column`, `preset-column-widths`, `default-column-width`, `focus-ring`, `border`, `shadow`, `struts` | `gaps 8`; `preset-column-widths` adds `proportion 1.0`; `focus-ring` uses `width 2`, `active-color "#cba6f7"`, `inactive-color "#45475a"`; `border` has `off` | Active + Full Comments |
| `spawn-at-startup` | `spawn-at-startup "waybar"` + comments for `spawn-sh-at-startup` | Replaced with `spawn-at-startup "noctalia"` while preserving upstream startup comments | Active + Full Comments |
| `hotkey-overlay` | `hotkey-overlay { // skip-at-startup }` | Preserved verbatim from upstream | Active + Full Comments |
| `prefer-no-csd` | Commented out (`// prefer-no-csd`) in upstream | Active (`prefer-no-csd` uncommented) with upstream comments preserved | Active + Full Comments |
| `screenshot-path` | `"~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"` | Preserved verbatim from upstream with `null` example comment | Active + Full Comments |
| `animations` | `animations { // off; // slowdown 3.0 }` | Preserved verbatim from upstream | Active + Full Comments |
| `window-rule` | Active WezTerm & Firefox PiP rules + 2 commented `/-window-rule` examples | Active WezTerm rule matches `^org\.wezfurlong\.wezterm$` and `"wezterm"`; Firefox PiP floating rule active; password-manager & rounded-corner examples kept as `/-window-rule` | Active + Commented Examples |
| `binds` | Full upstream keybindings & inline comments | Harmonized with Noctalia IPC & WezTerm shortcuts (see Entity 2) | Active + Full Comments |

---

### Entity 2: Harmonized Keybinding Matrix (`binds`)

| Category | Keybinding(s) | Action / Command | Origin |
| --- | --- | --- | --- |
| **Help & Overview** | `Mod+Shift+Slash` | `show-hotkey-overlay` | Upstream |
| | `Mod+O` (`repeat=false`) | `toggle-overview` | Upstream |
| **Terminal** | `Mod+Return`, `Mod+T` | `spawn "wezterm"` | Custom + Upstream key |
| **Application Launcher** | `Mod+Space`, `Mod+D` | `spawn "noctalia" "msg" "panel-toggle" "launcher"` | Custom (`Noctalia`) |
| **Control Center** | `Mod+N` | `spawn "noctalia" "msg" "panel-toggle" "control-center"` | Custom (`Noctalia`) |
| **Session & Lock** | `Mod+Shift+E` | `spawn "noctalia" "msg" "panel-toggle" "session"` | Custom (`Noctalia`) |
| | `Super+Alt+L` | `spawn "noctalia" "msg" "session" "lock"` | Clarified (`Noctalia` on upstream key) |
| | `Ctrl+Alt+Delete` | `quit` | Upstream |
| | `Mod+Shift+P` | `power-off-monitors` | Upstream |
| **Shortcut Inhibitor** | `Mod+Escape` (`allow-inhibiting=false`) | `toggle-keyboard-shortcuts-inhibit` | Clarified (Upstream) |
| **Accessibility** | `Super+Alt+S` (`allow-when-locked=true`) | `spawn-sh "pkill orca \|\| exec orca"` | Upstream |
| **Audio & Media** | `XF86AudioRaiseVolume` (`allow-when-locked=true`) | `spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" "-l" "1.0"` | Custom step + Upstream limit |
| | `XF86AudioLowerVolume` (`allow-when-locked=true`) | `spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"` | Custom |
| | `XF86AudioMute` (`allow-when-locked=true`) | `spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"` | Custom + Upstream |
| | `XF86AudioMicMute` (`allow-when-locked=true`) | `spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"` | Custom + Upstream |
| | `XF86AudioPlay/Pause/Stop/Prev/Next` (`allow-when-locked=true`) | `spawn-sh "playerctl ..."` | Upstream |
| **Brightness & Touchpad** | `XF86MonBrightnessUp/Down` (`allow-when-locked=true`) | `spawn "brightnessctl" "--class=backlight" "set" "+10%" / "10%-"` | Upstream |
| | `XF86TouchpadToggle` (`repeat=false`) | `toggle-touchpad` | Upstream |
| **Window Close** | `Mod+Q` (`repeat=false`), `Alt+F4` (`repeat=false`) | `close-window` | Custom + Upstream |
| **Column/Window Focus** | `Mod+Left/Down/Up/Right`, `Mod+H/J/K/L` | `focus-column-left`, `focus-window-down`, `focus-window-up`, `focus-column-right` | Custom + Upstream |
| | `Mod+Home`, `Mod+End` | `focus-column-first`, `focus-column-last` | Upstream |
| **Column/Window Move** | `Mod+Ctrl+Left/Down/Up/Right`, `Mod+Ctrl+H/J/K/L` | `move-column-left`, `move-window-down`, `move-window-up`, `move-column-right` | Clarified (Upstream) |
| | `Mod+Ctrl+Home`, `Mod+Ctrl+End` | `move-column-to-first`, `move-column-to-last` | Upstream |
| **Monitor Focus & Move** | `Mod+Shift+Left/Down/Up/Right`, `Mod+Shift+H/J/K/L` | `focus-monitor-left/down/up/right` | Clarified (Upstream) |
| | `Mod+Shift+Ctrl+Left/Down/Up/Right`, `Mod+Shift+Ctrl+H/J/K/L` | `move-column-to-monitor-left/down/up/right` | Clarified (Upstream) |
| **Workspace Navigation** | `Mod+Page_Down/Page_Up`, `Mod+U/I` | `focus-workspace-down/up` | Upstream |
| | `Mod+Ctrl+Page_Down/Page_Up`, `Mod+Ctrl+U/I` | `move-column-to-workspace-down/up` | Upstream |
| | `Mod+Shift+Page_Down/Page_Up`, `Mod+Shift+U/I` | `move-workspace-down/up` | Upstream |
| | `Mod+WheelScrollDown/Up` (`cooldown-ms=150`) | `focus-workspace-down/up` | Upstream |
| | `Mod+Ctrl+WheelScrollDown/Up` (`cooldown-ms=150`) | `move-column-to-workspace-down/up` | Upstream |
| | `Mod+WheelScrollRight/Left`, `Mod+Shift+WheelScrollDown/Up` | `focus-column-right/left` | Upstream |
| | `Mod+Ctrl+WheelScrollRight/Left`, `Mod+Ctrl+Shift+WheelScrollDown/Up` | `move-column-right/left` | Upstream |
| | `Mod+1..9` | `focus-workspace 1..9` | Custom + Upstream |
| | `Mod+Ctrl+1..9` | `move-column-to-workspace 1..9` | Clarified (Upstream) |
| | `Mod+Shift+1..9` | `move-window-to-workspace 1..9` | Clarified (Custom) |
| **Column/Window Sizing & Layout** | `Mod+BracketLeft/Right` | `consume-or-expel-window-left/right` | Upstream |
| | `Mod+Comma`, `Mod+Period` | `consume-window-into-column`, `expel-window-from-column` | Upstream |
| | `Mod+R`, `Mod+Shift+R` | `switch-preset-column-width`, `switch-preset-column-width-back` | Upstream |
| | `Mod+Ctrl+Shift+R`, `Mod+Ctrl+R` | `switch-preset-window-height`, `reset-window-height` | Upstream |
| | `Mod+F`, `Mod+Shift+F`, `Mod+M`, `Mod+Ctrl+F` | `maximize-column`, `fullscreen-window`, `maximize-window-to-edges`, `expand-column-to-available-width` | Custom + Upstream |
| | `Mod+C`, `Mod+Ctrl+C` | `center-column`, `center-visible-columns` | Custom + Upstream |
| | `Mod+Minus`, `Mod+Equal` | `set-column-width "-10%"`, `set-column-width "+10%"` | Upstream |
| | `Mod+Shift+Minus`, `Mod+Shift+Equal` | `set-window-height "-10%"`, `set-window-height "+10%"` | Upstream |
| | `Mod+V`, `Mod+Shift+V` | `toggle-window-floating`, `switch-focus-between-floating-and-tiling` | Upstream |
| | `Mod+W` | `toggle-column-tabbed-display` | Upstream |
| **Screenshots** | `Print`, `Ctrl+Print`, `Alt+Print` | `screenshot`, `screenshot-screen`, `screenshot-window` | Upstream |

---

## 2. Invariants & Validation Rules

1. **KDL Syntax & Schema Validity**: `niri validate -c modules/desktop/dotfiles/niri/config.kdl` MUST exit with code `0`.
2. **Uniqueness Invariant**: No two active keybindings inside `binds { ... }` may share the same key chord and modifier combination.
3. **Commented Example Invariant**: Example blocks that are hardware-specific (`/-output "eDP-1"`) or optional global overrides (`/-window-rule` for KeePassXC/Secrets and rounded corners) MUST remain prefixed with `/-`.
4. **Noctalia Exclusivity Invariant**: `spawn-at-startup "waybar"`, `spawn "alacritty"`, `spawn "fuzzel"`, and `spawn "swaylock"` MUST NOT be active; their roles are fulfilled by `noctalia` and `wezterm`.
