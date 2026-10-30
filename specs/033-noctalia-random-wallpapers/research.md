# Research: Dynamic Random Noctalia Wallpapers on `desktop-pc`

**Feature Branch**: `033-noctalia-random-wallpapers` | **Date**: 2026-10-30 | **Spec**: [spec.md](./spec.md)

## Research Findings & Architectural Decisions

### 1. Wallpaper Asset Storage & Deployment Pattern

- **Decision**: Store wallpaper image assets in `assets/wallpapers/` at the repository root, tracked via Git with a `.gitkeep` placeholder, and deploy them to `~/Pictures/wallpapers` using Home Manager (`home.file."Pictures/wallpapers".source = ../../assets/wallpapers;`) in `modules/desktop/session.nix`.
- **Rationale**:
  - Versioning wallpapers directly in the repository guarantees hermetic reproducibility and portability across machines.
  - Linking to `~/Pictures/wallpapers` provides a stable, user-accessible path complying with XDG conventions, ensuring that Noctalia, file pickers, and terminal tools can inspect or browse the wallpapers without dealing with transient `/nix/store/...` hashes.
  - Relative path `../../assets/wallpapers` from `modules/desktop/session.nix` resolves cleanly to the flake root and integrates into the Nix store derivation automatically during system build (`just switch`).
- **Alternatives Considered**:
  - *Hardcoding `/nix/store/...` paths in `noctalia.toml`*: Previous approach. Caused wallpapers to break (black screen) whenever `pkgs.noctalia` was bumped or garbage-collected. Rejected.
  - *Setting `programs.noctalia.settings.wallpaper.directory = "${../../assets/wallpapers}"` directly*: Stores the directory path as `/nix/store/<hash>-wallpapers` in `config.toml`. While hermetic, every image addition alters the store path and prevents simple user navigation in graphical file managers. Rejected in favor of the stable Home Manager symlink `~/Pictures/wallpapers`.

### 2. Startup-Only Random Wallpaper Selection & Periodic Rotation Prevention

- **Decision**: Configure Noctalia's `[wallpaper.automation]` with `enabled = true`, `order = "random"`, `recursive = true`, and `interval_seconds = 86400` (24 hours) in `modules/desktop/dotfiles/noctalia.toml`.
- **Rationale**:
  - In Noctalia 5.x (`src/shell/wallpaper/wallpaper.cpp`), `applyStartupAutomation()` is invoked upon shell startup whenever `wallpaper.automation.enabled == true`. It immediately scans the configured `directory`, collects image candidates, and sets a random wallpaper across all connected displays.
  - The user requirement specifically requests random selection "au démarrage ou à la demande" (at startup or on demand), not continuous background rotation while working.
  - Setting `interval_seconds = 0` causes Noctalia to rotate on every tick (1 second), which is disruptive. Setting `interval_seconds = 86400` (24h) guarantees that no mid-session automatic rotation occurs during typical desktop usage, while ensuring startup randomization runs reliably on every login.
- **Alternatives Considered**:
  - *Setting `automation.enabled = false` and calling a script at startup*: Unnecessary additional script or systemd user service when Noctalia's built-in automation already implements startup randomization natively.
  - *Small interval (e.g. 1800s)*: Violates the user's explicit preference for startup or on-demand changes only.

### 3. Fallback Fill Color & Empty Directory Handling

- **Decision**: Set `fill_color = "#2e3440"` (Nord0 - Polar Night) in `modules/desktop/dotfiles/noctalia.toml` under `[wallpaper]`.
- **Rationale**:
  - Aligns with the system-wide Nord theme established in spec `019-nord-theme-desktop` (where Niri, Tuigreet, Noctalia, Starship, and Limine all use Nord colors).
  - When `assets/wallpapers/` is initially empty or contains only `.gitkeep`, Noctalia's directory scanner discovers 0 image candidates. Instead of failing with a rendering error or displaying a black void, Noctalia renders the `fill_color` cleanly across the desktop.
- **Alternatives Considered**:
  - *Default fill color (`#111111` or empty)*: Disconnected from the Nord color palette (`#2e3440` Polar Night).

### 4. Interactive & On-Demand Desktop Shortcuts in Niri

- **Decision**: Define two dedicated keybindings in `modules/desktop/dotfiles/niri/config.kdl`:
  - `Mod+Shift+W`: `spawn "noctalia" "msg" "wallpaper-random"`
  - `Mod+Ctrl+W`: `spawn "noctalia" "msg" "panel-toggle" "wallpaper"`
- **Rationale**:
  - `Mod+W` in Niri is bound to `toggle-column-tabbed-display;`.
  - Neither `Mod+Shift+W` nor `Mod+Ctrl+W` is currently used in `config.kdl`.
  - `noctalia msg wallpaper-random` triggers Noctalia's IPC handler to pick another random image from `directory` and apply it with smooth shader transitions immediately.
  - `noctalia msg panel-toggle wallpaper` toggles the official Noctalia thumbnail panel, allowing the user to visually inspect and select wallpapers on demand.
  - Validated cleanly via `niri -- validate -c modules/desktop/dotfiles/niri/config.kdl`.
- **Alternatives Considered**:
  - *Rebinding `Mod+W`*: Would break Niri's upstream default for tabbed column display.
