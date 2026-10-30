# Data Model: Dynamic Random Noctalia Wallpapers on `desktop-pc`

**Feature Branch**: `033-noctalia-random-wallpapers` | **Date**: 2026-10-30 | **Spec**: [spec.md](./spec.md)

## Entities & Configuration Schemas

### 1. Wallpaper Asset Directory (`assets/wallpapers/`)

The repository directory containing user-provided static wallpaper images.

| Attribute | Type | Description |
|-----------|------|-------------|
| **Path** | String / Path | `assets/wallpapers/` relative to repository root |
| **Git Tracking** | File | `.gitkeep` ensures the folder is tracked when empty |
| **Supported Image Formats** | Set of MIME/Extensions | `.png`, `.jpg`, `.jpeg`, `.webp`, `.jxl` |
| **Lifecycle** | Declarative Git asset | Version-controlled, packaged into Nix store on evaluation |

### 2. Home Manager Wallpaper Symlink (`~/Pictures/wallpapers`)

The user-level symlink provisioned by Home Manager on `desktop-pc`.

| Attribute | Type | Description |
|-----------|------|-------------|
| **Target Path** | String | `~/Pictures/wallpapers` (`$HOME/Pictures/wallpapers`) |
| **Source Expression** | Nix Path | `../../assets/wallpapers` declared in `modules/desktop/session.nix` |
| **Home Manager Option** | NixOS Option | `home-manager.users.${vars.userName}.home.file."Pictures/wallpapers".source` |
| **Target Host** | Host | `desktop-pc` |

### 3. Noctalia Wallpaper Configuration (`[wallpaper]`)

The declarative TOML settings managed in `modules/desktop/dotfiles/noctalia.toml`.

| Section / Key | Type | Value | Purpose |
|---------------|------|-------|---------|
| `[wallpaper]` | Table | — | Wallpaper service top-level configuration |
| `enabled` | Boolean | `true` | Enables native Noctalia wallpaper management |
| `directory` | String (Path) | `"~/Pictures/wallpapers"` | Folder scanned for wallpaper candidates and GUI panel thumbnails |
| `fill_mode` | String (Enum) | `"crop"` | Aspect-preserving scale and center cropping |
| `fill_color` | String (Hex) | `"#2e3440"` | Nord0 (Polar Night) fallback color when directory is empty |
| `[wallpaper.automation]` | Table | — | Automatic wallpaper selection table |
| `enabled` | Boolean | `true` | Activates startup automation (`applyStartupAutomation`) |
| `order` | String (Enum) | `"random"` | Randomizes candidate image selection |
| `recursive` | Boolean | `true` | Recursively includes subdirectories |
| `interval_seconds` | Integer | `86400` | 24-hour interval preventing automatic mid-session rotation |

#### Deprecated & Removed Keys

| Previous Key | Reason for Removal |
|--------------|-------------------|
| `[wallpaper.default].path` | Removed. Previously pointed to a stale `/nix/store/...-noctalia-5.1.0/` path causing black screen on desktop startup. |
| `[wallpaper.last].path` | Removed. Stale `/nix/store/...` path replaced by dynamic startup automation. |

### 4. Niri Compositor Keybindings (`binds`)

Declarative keybinding definitions added to `modules/desktop/dotfiles/niri/config.kdl`.

| Key Combination | Action / IPC Command | Description |
|-----------------|----------------------|-------------|
| `Mod+Shift+W` | `spawn "noctalia" "msg" "wallpaper-random"` | Picks and applies a new random wallpaper from `~/Pictures/wallpapers` across all screens |
| `Mod+Ctrl+W` | `spawn "noctalia" "msg" "panel-toggle" "wallpaper"` | Toggles Noctalia's graphical wallpaper selection panel overlay |
