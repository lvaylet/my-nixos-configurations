# Niri Configuration & Keybindings Contract

**Feature**: `014-update-niri-config`
**Target File**: `modules/desktop/dotfiles/niri/config.kdl`

## 1. Structural Contract

`modules/desktop/dotfiles/niri/config.kdl` MUST contain the following top-level nodes and comments in alignment with upstream `resources/default-config.kdl`:

1. **Header Comments**: KDL format introduction, `/-` node comment explanation, and wiki link (`https://niri-wm.github.io/niri/Configuration:-Introduction`).
2. **`input` Block**:
   - `keyboard`: `xkb` (`layout "us,fr"`, `variant "intl,"`, `options "grp:alt_shift_toggle"` + upstream comments) and `numlock`.
   - `touchpad`: `tap`, `natural-scroll`, and upstream commented libinput options.
   - `mouse`: upstream commented libinput options.
   - `trackpoint`: upstream commented libinput options.
   - Commented `warp-mouse-to-focus` and `focus-follows-mouse max-scroll-amount="0%"`.
3. **`/-output "eDP-1"` Block**: Commented-out (`/-`) output template with `mode`, `scale`, `transform`, and `position` comments.
4. **`layout` Block**:
   - `gaps 8`
   - `center-focused-column "never"`
   - `preset-column-widths`: `proportion 0.33333`, `proportion 0.5`, `proportion 0.66667`, `proportion 1.0`, and `// fixed 1920`.
   - Commented `preset-window-heights { }`.
   - `default-column-width { proportion 0.5; }` and commented `default-column-width {}`.
   - `focus-ring`: `width 2`, `active-color "#cba6f7"`, `inactive-color "#45475a"`, plus upstream comments and gradient examples.
   - `border`: `off`, `width 4`, `active-color "#ffc87f"`, `inactive-color "#505050"`, `urgent-color "#9b0000"`, plus upstream gradient comments.
   - `shadow`: `softness 30`, `spread 5`, `offset x=0 y=5`, `color "#0007"`, plus upstream `// on` and `// draw-behind-window true` comments.
   - `struts`: commented `left`, `right`, `top`, `bottom` examples.
5. **Startup & Session Nodes**:
   - `spawn-at-startup "noctalia"` with upstream startup & `spawn-sh-at-startup` comments.
   - `hotkey-overlay` block (`// skip-at-startup`).
   - Active `prefer-no-csd` with upstream comments.
   - `screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"` and commented `screenshot-path null`.
   - `animations` block (`// off`, `// slowdown 3.0`).
6. **`window-rule` Nodes**:
   - Active WezTerm rule (`match app-id=r#"^org\.wezfurlong\.wezterm$"#`, `match app-id="wezterm"`, `default-column-width {}`).
   - Active Firefox Picture-in-Picture rule (`match app-id=r#"firefox$"# title="^Picture-in-Picture$"`, `open-floating true`).
   - Commented `/-window-rule` for password managers (`block-out-from "screen-capture"`).
   - Commented `/-window-rule` for rounded corners (`geometry-corner-radius 12`, `clip-to-geometry true`).
7. **`binds` Block**:
   - Complete set of harmonized custom (Noctalia, WezTerm) and upstream Niri keybindings with zero duplicate active chords.

---

## 2. Verification Contract

- `niri validate -c modules/desktop/dotfiles/niri/config.kdl` MUST return exit status `0`.
- `just check` (`nix flake check`) MUST return exit status `0`.
