# Feature Specification: Update Niri Configuration with Upstream Defaults and Documentation

**Feature Branch**: `014-update-niri-config`

**Created**: 2026-10-15

**Status**: Draft

**Input**: User description: "Mets à jour la configuration de Niri dans @modules/desktop/dotfiles/niri/config.kdl pour reprendre un maximum de paramètres et de commentaires de la configuration par défaut dans https://github.com/niri-wm/niri/blob/main/resources/default-config.kdl. Conserve les spécificités de ma configuration, par exemple l'usage de Noctalia et WezTerm."

## Clarifications

### Session 2026-10-15

- Q: Quelle convention de modificateurs souhaites-tu utiliser pour déplacer les fenêtres/colonnes et changer de moniteur avec `H/J/K/L`, les flèches et `1..9` ? (FR-009) → A: Adopter la convention amont de Niri (`Mod+Ctrl` déplace les fenêtres/colonnes avec `H/J/K/L`, flèches et `1..9`, `Mod+Shift` change le focus de moniteur `focus-monitor-*`, tout en conservant `Mod+Shift+1..9` pour `move-window-to-workspace`).
- Q: Comment souhaites-tu gérer le raccourci `Mod+Escape`, qui verrouille actuellement la session via Noctalia dans ta configuration mais sert à désactiver l'inhibition des raccourcis clavier (`toggle-keyboard-shortcuts-inhibit`) dans la configuration par défaut de Niri ? (FR-008) → A: Suivre la convention amont de Niri : utiliser `Super+Alt+L` pour verrouiller l'écran via Noctalia et réserver `Mod+Escape` à `toggle-keyboard-shortcuts-inhibit`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Comprehensive Upstream Niri Capabilities & Inline Reference Documentation (Priority: P1)

As a desktop workstation user and system maintainer, I want my Niri configuration to incorporate the full structure, default parameters, window rules, keybindings, and inline explanatory comments from the official upstream Niri default configuration, so that I can use all standard Niri capabilities (overview, column/window manipulation, monitor management, mouse/touchpad scrolling, screenshots, media/brightness controls, and window rules) and customize settings directly from self-documenting inline comments without consulting external documentation.

**Why this priority**: Directly fulfills the core goal of enriching the minimal configuration with upstream Niri's complete feature set and inline documentation while keeping the configuration self-explanatory and maintainable.

**Independent Test**: Open `modules/desktop/dotfiles/niri/config.kdl` and verify that all major sections from the upstream default configuration (`input`, `/-output`, `layout`, `spawn-at-startup`, `hotkey-overlay`, `prefer-no-csd`, `screenshot-path`, `animations`, `window-rule`, and `binds`) are present with their explanatory comments and commented-out examples, and that the Niri session loads the configuration cleanly without syntax or validation errors.

**Acceptance Scenarios**:

1. **Given** the updated Niri configuration file, **When** a maintainer inspects each top-level section (`input`, `output`, `layout`, `spawn-at-startup`, `hotkey-overlay`, `prefer-no-csd`, `screenshot-path`, `animations`, `window-rule`, `binds`), **Then** all upstream inline explanations, wiki links, and commented-out examples (`//` and `/-`) are present and accurately structured.
2. **Given** an active Niri desktop session using the updated configuration, **When** the user invokes standard upstream Niri actions (such as toggling the overview with `Mod+O`, displaying the hotkey overlay with `Mod+Shift+Slash`, cycling column widths with `Mod+R`, consuming/expelling windows, toggling floating or tabbed modes, scrolling workspaces with the mouse wheel, or taking screenshots with `Print`), **Then** each action executes as expected.

---

### User Story 2 - Seamless Preservation of Personal Desktop Stack Customizations (Priority: P1)

As a daily user of the Niri, Noctalia, and WezTerm desktop environment, I want all my existing personal customizations—including Noctalia startup and IPC shortcuts, WezTerm terminal launching, US-International and French keyboard layout switching, custom layout gaps, preset column widths, Catppuccin focus-ring styling, and server-side decoration preferences—to remain intact and active after adopting the upstream configuration template, so that my established workflow and visual identity experience zero regression.

**Why this priority**: Preserving personal workflow specificities is a strict requirement; losing Noctalia integration, WezTerm shortcuts, keyboard layouts, or visual styling would break the user's daily desktop experience.

**Independent Test**: Start a desktop session with the updated configuration and verify that Noctalia starts automatically, keyboard layouts switch via `Alt+Shift`, `Mod+Return` (and `Mod+T`) opens WezTerm, `Mod+Space` and `Mod+D` toggle the Noctalia launcher, `Mod+N` opens the Noctalia control center, `Mod+Shift+E` opens the Noctalia session panel, `Super+Alt+L` locks the screen via Noctalia, and window gaps (`8`) and focus-ring colors (`#cba6f7` / `#45475a`, width `2`) match the user's personalized styling.

**Acceptance Scenarios**:

1. **Given** a fresh login into the Niri session, **When** startup processes initialize, **Then** `noctalia` launches automatically as the desktop shell instead of `waybar`.
2. **Given** an active desktop session, **When** the user presses `Mod+Return` (or `Mod+T`), `Mod+Space` or `Mod+D`, `Mod+N`, `Mod+Shift+E`, or `Super+Alt+L`, **Then** WezTerm and the corresponding Noctalia panels/session lock are triggered immediately.
3. **Given** an active desktop session with open windows, **When** inspecting window layout and input behavior, **Then** keyboard layout switching (`us` intl / `fr` via `Alt+Shift`), touchpad tap and natural scroll, `8px` gaps, `1.0` full-width preset option, `prefer-no-csd`, and the `2px` `#cba6f7` / `#45475a` focus ring remain active.

---

### User Story 3 - Application Window Rules and Hardware Media/Brightness Ergonomics (Priority: P2)

As a workstation user, I want built-in window rules for WezTerm and Firefox Picture-in-Picture as well as full hardware media, volume, brightness, and touchpad toggle keybindings, so that applications size and float properly out of the box and hardware function keys work reliably even when the session is locked.

**Why this priority**: Improves day-to-day polish by fixing WezTerm's initial window sizing quirk via Niri's official window rule, floating video Picture-in-Picture windows automatically, and enabling full media/hardware key support.

**Independent Test**: Launch a new WezTerm window and a Firefox Picture-in-Picture window to confirm proper initial tiling and floating behavior, and test audio volume/mute keys to confirm they adjust PipeWire/WirePlumber state both in an unlocked and locked session.

**Acceptance Scenarios**:

1. **Given** the upstream WezTerm window rule is active, **When** a new WezTerm window is spawned, **Then** Niri applies `default-column-width {}` to work around WezTerm's initial configure behavior cleanly.
2. **Given** a Firefox browser window playing video, **When** the user pops out the Picture-in-Picture player, **Then** Niri automatically opens the Picture-in-Picture window in floating mode.
3. **Given** an active or locked desktop session, **When** the user presses audio volume, mute, microphone mute, media playback, or brightness keys, **Then** the corresponding system audio, media player, or backlight action is executed.

---

### Edge Cases

- **Keybinding Overlaps Between Custom and Upstream Defaults**: Where the user's existing configuration and upstream defaults bind the same key combination to different actions (for example, `Mod+D` for launcher, `Mod+Shift+E` for session menu, `Mod+Escape` for session lock, or `Mod+Shift+...` vs `Mod+Ctrl+...` for window/column movement and monitor focus), the configuration must resolve bindings without duplicate active key definitions while keeping both custom Noctalia/WezTerm actions and upstream Niri capabilities accessible.
- **Keyboard Layout Toggle vs. Launcher Shortcut**: Upstream comments show `Mod+Space` as an example for `switch-layout "next"`, whereas the user's configuration uses `Alt+Shift` (`grp:alt_shift_toggle`) in XKB and binds `Mod+Space` to the Noctalia launcher; the upstream layout-switch binds must remain commented out so `Mod+Space` continues to trigger the Noctalia launcher without layout-switching side effects.
- **Commented-Out Example Nodes (`/-`)**: Upstream example blocks such as `/-output "eDP-1"` and `/-window-rule` for password managers and rounded corners must remain commented out using KDL's `/-` syntax so they serve as ready-to-use documentation without forcing hardcoded laptop monitor settings or unwanted global window rules.
- **Optional External CLI Utilities in Upstream Binds**: Upstream binds reference standard utilities (`wpctl`, `playerctl`, `brightnessctl`, `orca`) that only execute when the corresponding hardware/key is pressed; their presence in `binds` must not prevent Niri from starting or validating its configuration.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Niri configuration file (`modules/desktop/dotfiles/niri/config.kdl`) MUST adopt the complete structural organization, inline documentation comments (`//`), wiki reference URLs, and commented-out example nodes (`/-`) from the official upstream Niri default configuration (`resources/default-config.kdl`).
- **FR-002**: The `input` section MUST preserve the user's XKB keyboard configuration (`layout "us,fr"`, `variant "intl,"`, `options "grp:alt_shift_toggle"`) and active `touchpad` settings (`tap`, `natural-scroll`), while adding upstream's `numlock` setting, inline comments, and commented-out options for `touchpad`, `mouse`, `trackpoint`, `warp-mouse-to-focus`, and `focus-follows-mouse`.
- **FR-003**: The configuration MUST include the upstream commented-out `/-output "eDP-1"` block and its complete documentation regarding output discovery (`niri msg outputs`), resolution/refresh rate modes, fractional scaling, rotation transforms, and logical coordinate positioning.
- **FR-004**: The `layout` section MUST preserve the user's personalized layout values—specifically `gaps 8`, `center-focused-column "never"`, `preset-column-widths` containing `proportion 0.33333`, `proportion 0.5`, `proportion 0.66667`, and `proportion 1.0`, `default-column-width { proportion 0.5; }`, `focus-ring` with `width 2`, `active-color "#cba6f7"`, and `inactive-color "#45475a"`, and `border` disabled with `off`—while incorporating all upstream layout comments, default reference properties inside `border`, and the upstream `shadow` and `struts` blocks.
- **FR-005**: The startup section MUST preserve `spawn-at-startup "noctalia"` in place of upstream's `waybar` while retaining upstream's explanatory comments on `spawn-at-startup`, XDG desktop autostart, and `spawn-sh-at-startup`.
- **FR-006**: The configuration MUST keep `prefer-no-csd` active (uncommented) while retaining its upstream explanatory comments, and MUST include the upstream `hotkey-overlay`, `screenshot-path`, and `animations` sections with their respective settings and comments.
- **FR-007**: The configuration MUST include the upstream `window-rule` blocks and comments, specifically:
  - Active rule matching WezTerm (`match app-id=r#"^org\.wezfurlong\.wezterm$"#` and `match app-id="wezterm"`) with `default-column-width {}`.
  - Active rule matching Firefox Picture-in-Picture (`match app-id=r#"firefox$"# title="^Picture-in-Picture$"`) with `open-floating true`.
  - Commented-out (`/-window-rule`) example rules for blocking password managers from screen capture and enabling rounded window corners (`geometry-corner-radius`).
- **FR-008**: The `binds` section MUST preserve all user-specific shortcuts for WezTerm and Noctalia IPC integration, enriched with `hotkey-overlay-title` descriptions where appropriate:
  - `Mod+Return` (and `Mod+T`) to spawn `wezterm`.
  - `Mod+Space` and `Mod+D` to toggle the Noctalia application launcher (`spawn "noctalia" "msg" "panel-toggle" "launcher"`).
  - `Mod+N` to toggle the Noctalia control center (`spawn "noctalia" "msg" "panel-toggle" "control-center"`).
  - `Mod+Shift+E` to toggle the Noctalia session menu (`spawn "noctalia" "msg" "panel-toggle" "session"`).
  - `Super+Alt+L` to lock the session via Noctalia (`spawn "noctalia" "msg" "session" "lock"`, replacing upstream's `swaylock`).
- **FR-009**: The `binds` section MUST incorporate the full set of upstream Niri window, column, workspace, and monitor management bindings and comments, including:
  - Hotkey overlay (`Mod+Shift+Slash`) and Overview toggle (`Mod+O repeat=false`).
  - Window close (`Mod+Q repeat=false`, `Alt+F4 repeat=false`).
  - Directional column/window focus (`Mod+Left/Down/Up/Right` and `Mod+H/J/K/L`).
  - Column/window movement (`Mod+Ctrl+Left/Down/Up/Right` and `Mod+Ctrl+H/J/K/L`), first/last column focus and movement (`Mod+Home/End`, `Mod+Ctrl+Home/End`), and multi-monitor focus and movement (`Mod+Shift+Left/Down/Up/Right`, `Mod+Shift+H/J/K/L`, `Mod+Shift+Ctrl+...`).
  - Workspace focus and column/workspace movement (`Page_Down/Page_Up`, `U/I`, mouse wheel binds with `cooldown-ms=150`, touchpad scroll comments, and numeric workspace binds `1..9` for focus, `Mod+Ctrl+1..9` for moving columns, and `Mod+Shift+1..9` preserved for moving windows to workspaces).
  - Column/window layout manipulation: `consume-or-expel-window-left/right` (`Mod+BracketLeft/Right`), `consume-window-into-column` (`Mod+Comma`), `expel-window-from-column` (`Mod+Period`), preset width/height switching (`Mod+R`, `Mod+Shift+R`, `Mod+Ctrl+Shift+R`, `Mod+Ctrl+R`), maximizing (`Mod+F`, `Mod+Shift+F`, `Mod+M`, `Mod+Ctrl+F`), centering (`Mod+C`, `Mod+Ctrl+C`), fine width/height adjustments (`Mod+Minus/Equal`, `Mod+Shift+Minus/Equal`), floating toggle (`Mod+V`, `Mod+Shift+V`), and tabbed column display (`Mod+W`).
  - Screenshots (`Print`, `Ctrl+Print`, `Alt+Print`), keyboard shortcuts inhibitor toggle (`Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }`), quit confirmation (`Ctrl+Alt+Delete`), and monitor power-off (`Mod+Shift+P`).
- **FR-010**: The `binds` section MUST include upstream audio, media, brightness, touchpad toggle, and screen reader bindings (`XF86AudioRaiseVolume`, `XF86AudioLowerVolume`, `XF86AudioMute`, `XF86AudioMicMute`, `XF86AudioPlay`, `XF86AudioPause`, `XF86AudioStop`, `XF86AudioPrev`, `XF86AudioNext`, `XF86MonBrightnessUp`, `XF86MonBrightnessDown`, `XF86TouchpadToggle`, `Super+Alt+S`) with their upstream properties and comments.
- **FR-011**: The updated configuration MUST pass KDL syntax validation and all repository quality gates (`just fmt`, `just lint`, `just check`) without errors.

### Key Entities

- **Niri Configuration File (`config.kdl`)**: The declarative KDL configuration file deployed via Home Manager to `~/.config/niri/config.kdl`, defining compositor behavior, visual styling, rules, and keybindings.
- **Desktop Shell & Terminal Integration**: The startup declarations, window rules, and IPC keybindings linking Niri with the Noctalia desktop shell (`noctalia`) and WezTerm (`wezterm`).
- **Upstream Reference Documentation**: The inline comments (`//`) and commented-out KDL nodes (`/-`) sourced from Niri's official `default-config.kdl` that document available options, value formats, and usage examples.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of top-level sections and subsections from Niri's upstream `default-config.kdl` (`input`, `/-output`, `layout`, `spawn-at-startup`, `hotkey-overlay`, `prefer-no-csd`, `screenshot-path`, `animations`, `window-rule`, and `binds`) are present with their inline documentation in `modules/desktop/dotfiles/niri/config.kdl`.
- **SC-002**: 100% of existing personal customizations (Noctalia startup and IPC keybindings, WezTerm terminal keybindings, `us,fr` XKB configuration, `gaps 8`, `proportion 1.0` preset column width, Catppuccin focus-ring styling, and active `prefer-no-csd`) are preserved and operational.
- **SC-003**: 0 duplicate keybinding conflicts or KDL syntax errors exist in `modules/desktop/dotfiles/niri/config.kdl`.
- **SC-004**: 100% pass rate on repository formatting, static analysis, and flake check gates (`just fmt`, `just lint`, `just check`).

## Assumptions

- Upstream Niri's standard modifier convention (`Mod+Ctrl+...` for moving columns/windows within a workspace and `Mod+Shift+...` for focusing monitors, alongside `Mod+Shift+Ctrl+...` for moving columns across monitors) is adopted to unlock the full set of upstream multi-monitor bindings, while preserving `Mod+Shift+1..9` (`move-window-to-workspace`) alongside upstream's `Mod+Ctrl+1..9` (`move-column-to-workspace`).
- For terminal launching, both the user's `Mod+Return` shortcut and upstream's `Mod+T` shortcut are configured to launch `wezterm` (replacing upstream's `alacritty`).
- For screen locking, upstream's `Super+Alt+L` shortcut triggers Noctalia's screen lock (`noctalia msg session lock`), while `Mod+Escape` (`allow-inhibiting=false`) is reserved for upstream's `toggle-keyboard-shortcuts-inhibit` escape hatch.
- For volume control (`XF86AudioRaiseVolume` / `XF86AudioLowerVolume`), the user's `5%` step (`5%+` / `5%-` with `-l 1.0` upper limit) or upstream's `wpctl` invocation is retained with `allow-when-locked=true`.
