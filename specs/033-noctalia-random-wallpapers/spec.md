# Feature Specification: Dynamic Random Noctalia Wallpapers on `desktop-pc`

**Feature Branch**: `033-noctalia-random-wallpapers`

**Created**: 2026-10-30

**Status**: Draft

**Input**: User description: "Je veux que le wallpaper de Noctalia soit pris au hasard dans un répertoire `assets/wallpapers` de ce dépôt, au démarrage ou à la demande. Supprime les anciens chemins statiques vers le Nix Store. Utilise une couleur de fond par défaut en accord avec le thème Nord. Ajoute des raccourcis à Noctalia pour piocher et appliquer immédiatement un nouveau fond d'écran aléatoire, et pour ouvrir le panneau sélecteur graphique de Noctalia."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Versioned Wallpaper Directory & Startup Random Selection (Priority: P1)

As a desktop user on `desktop-pc`, I want Noctalia to pick a wallpaper randomly from a dedicated versioned directory (`assets/wallpapers`) upon session startup, and display a harmonious Nord background color if the directory is empty, without relying on stale, hardcoded `/nix/store/...` paths, so that my desktop background is never blank, broken, or unmaintained across system updates and garbage collection cycles.

**Why this priority**: Currently, `modules/desktop/dotfiles/noctalia.toml` contains static paths to a non-existent `/nix/store/...-noctalia-5.1.0/` derivation, causing the desktop wallpaper to fail to render and leave a black screen. Removing the hardcoded store paths and establishing a declarative directory source restores a functional, visually appealing desktop session.

**Independent Test**: Can be verified by evaluating `nixosConfigurations.desktop-pc.config.home-manager.users.laurent.home.file."Pictures/wallpapers".source` to confirm it points to `assets/wallpapers`, verifying `modules/desktop/dotfiles/noctalia.toml` declares `directory = "~/Pictures/wallpapers"` and fallback `fill_color = "#2e3440"`, and starting a session to confirm a random wallpaper or Nord fallback color is displayed.

**Acceptance Scenarios**:

1. **Given** one or more images reside in `assets/wallpapers/`, **When** the desktop session initializes on `desktop-pc`, **Then** Noctalia automatically selects and renders a random wallpaper across all connected displays.
2. **Given** `modules/desktop/dotfiles/noctalia.toml` is inspected, **When** reviewing the `[wallpaper]` section, **Then** all previous hardcoded `/nix/store/...` references (`path = "/nix/store/..."`) are completely absent.
3. **Given** `assets/wallpapers/` contains no image files (only `.gitkeep`), **When** the desktop session initializes, **Then** Noctalia renders the Nord Polar Night fallback background color (`#2e3440`) instead of a blank or failed visual surface.

---

### User Story 2 - On-Demand Wallpaper Randomization & Graphical Picker Shortcuts (Priority: P2)

As a desktop user on `desktop-pc`, I want dedicated keyboard shortcuts to cycle wallpapers on demand and open Noctalia's interactive wallpaper picker panel, so that I can quickly switch my visual environment without typing terminal commands or navigating file dialogues.

**Why this priority**: Users need immediate interactive control to change the wallpaper when working or to browse their wallpaper collection visually without waiting for an automated timer or rebooting the session.

**Independent Test**: Can be tested by validating the Niri compositor configuration with `nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl` to confirm `Mod+Shift+W` triggers `noctalia msg wallpaper-random` and `Mod+Ctrl+W` triggers `noctalia msg panel-toggle wallpaper`.

**Acceptance Scenarios**:

1. **Given** an active desktop session on `desktop-pc`, **When** the user presses `Mod+Shift+W`, **Then** Noctalia triggers its `wallpaper-random` IPC action and transitions immediately to another randomly selected wallpaper from `~/Pictures/wallpapers`.
2. **Given** an active desktop session on `desktop-pc`, **When** the user presses `Mod+Ctrl+W`, **Then** Noctalia toggles the graphical wallpaper panel overlay, displaying thumbnails of available wallpapers in `~/Pictures/wallpapers`.

---

### Edge Cases

- **Non-image files in wallpaper directory**: The directory contains `.gitkeep` (or other non-image files). Noctalia's internal directory scanner must ignore non-image files and only select valid image candidates (`.png`, `.jpg`, `.jpeg`, `.webp`, `.jxl`).
- **No images present in directory**: If the folder contains zero image files, startup automation skips image selection and applies the configured fallback `fill_color = "#2e3440"`, preventing shell crashes.
- **Accidental continuous rotation during work**: The user requested random selection at startup or on demand, not continuous periodic switching while working. Setting `interval_seconds` to a 24-hour cycle (`86400`) ensures that automated background switching does not disrupt active user workflows during typical desktop sessions.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create and version a directory at `assets/wallpapers/` in the repository with a `.gitkeep` file to ensure Git tracking.
- **FR-002**: System MUST link `assets/wallpapers/` to `~/Pictures/wallpapers` in the user's home directory via Home Manager (`modules/desktop/session.nix`).
- **FR-003**: System MUST remove all obsolete hardcoded `/nix/store/...` paths (`[wallpaper.default]` and `[wallpaper.last]`) from `modules/desktop/dotfiles/noctalia.toml`.
- **FR-004**: System MUST configure Noctalia in `modules/desktop/dotfiles/noctalia.toml` with `directory = "~/Pictures/wallpapers"`, `enabled = true`, `fill_mode = "crop"`, `fill_color = "#2e3440"` (Nord Polar Night), and `[wallpaper.automation]` with `enabled = true`, `order = "random"`, `recursive = true`, and `interval_seconds = 86400`.
- **FR-005**: System MUST configure Niri compositor keybindings in `modules/desktop/dotfiles/niri/config.kdl`:
  - `Mod+Shift+W`: spawns `noctalia msg wallpaper-random`
  - `Mod+Ctrl+W`: spawns `noctalia msg panel-toggle wallpaper`
- **FR-006**: System MUST update repository documentation in `README.md` to document the wallpaper directory path (`assets/wallpapers`), Home Manager symlink (`~/Pictures/wallpapers`), and Niri wallpaper shortcuts.

### Key Entities

- **Wallpaper Directory (`assets/wallpapers/`)**: Versioned repository folder containing wallpaper images, linked to `~/Pictures/wallpapers` in user storage.
- **Noctalia Wallpaper Configuration (`[wallpaper]`)**: Declarative configuration section in `modules/desktop/dotfiles/noctalia.toml` controlling wallpaper source, display mode, Nord fallback color, and random startup selection.
- **Niri Wallpaper Keybindings**: IPC shortcut definitions in `modules/desktop/dotfiles/niri/config.kdl` linking keyboard combinations to Noctalia wallpaper actions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nixosConfigurations.desktop-pc.config` evaluates and builds cleanly with zero errors or unresolved store paths.
- **SC-002**: 100% of repository quality gates (`nix fmt .`, `nix flake check`, and Niri configuration validation) pass with exit code `0`.
- **SC-003**: Initial session launch displays a wallpaper chosen randomly from `~/Pictures/wallpapers`, or falls back to `#2e3440` if no images are present.
- **SC-004**: Triggering `Mod+Shift+W` immediately switches the wallpaper in under 1 second, and `Mod+Ctrl+W` toggles the wallpaper picker panel overlay in under 500 milliseconds.

## Assumptions

- The user will populate `assets/wallpapers/` with their desired image files (`.png`, `.jpg`, `.webp`).
- Noctalia 5.x IPC commands (`wallpaper-random` and `panel-toggle wallpaper`) operate reliably over the Wayland session socket.
