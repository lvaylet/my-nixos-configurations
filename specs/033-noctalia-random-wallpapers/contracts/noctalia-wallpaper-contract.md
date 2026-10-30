# Contract: Noctalia Wallpaper Architecture & Niri Keybindings (`033-noctalia-random-wallpapers`)

## 1. Asset Storage & User Environment Contract (`modules/desktop/session.nix`, `assets/wallpapers/`)

- The repository root MUST maintain an `assets/wallpapers/` directory tracked in Git containing `.gitkeep`.
- `modules/desktop/session.nix` (`homeManager` configuration for `desktop-pc`) MUST declare:

  ```nix
  home.file."Pictures/wallpapers".source = ../../assets/wallpapers;
  ```

- Evaluated `nixosConfigurations.desktop-pc.config.home-manager.users.laurent.home.file."Pictures/wallpapers".source` MUST point to the Nix store derivation containing `assets/wallpapers`.

---

## 2. Noctalia Desktop Shell Configuration Contract (`modules/desktop/dotfiles/noctalia.toml`)

- `modules/desktop/dotfiles/noctalia.toml` MUST NOT contain:
  - `[wallpaper.default]`
  - `[wallpaper.last]`
  - Any reference to `/nix/store/`
- `modules/desktop/dotfiles/noctalia.toml` MUST declare:

  ```toml
  [wallpaper]
  directory = "~/Pictures/wallpapers"
  enabled = true
  fill_color = "#2e3440"
  fill_mode = "crop"

  [wallpaper.automation]
  enabled = true
  interval_seconds = 86400
  order = "random"
  recursive = true
  ```

- `fill_color` MUST match Nord0 Polar Night (`#2e3440`).
- `directory` MUST reference `~/Pictures/wallpapers`.

---

## 3. Niri Compositor Keybindings Contract (`modules/desktop/dotfiles/niri/config.kdl`)

- `modules/desktop/dotfiles/niri/config.kdl` MUST declare the following bindings within the `binds { ... }` block:
  - `Mod+Shift+W hotkey-overlay-title="Random Wallpaper: noctalia" { spawn "noctalia" "msg" "wallpaper-random"; }`
  - `Mod+Ctrl+W hotkey-overlay-title="Wallpaper Picker: noctalia" { spawn "noctalia" "msg" "panel-toggle" "wallpaper"; }`
- Existing bindings MUST NOT be altered or removed:
  - `Mod+W` MUST remain bound to `toggle-column-tabbed-display;`.
  - `Mod+Space` / `Mod+D` MUST remain bound to the Noctalia launcher.
  - `Mod+N` MUST remain bound to the Noctalia control center.
  - `Mod+Shift+E` MUST remain bound to the Noctalia session menu.

---

## 4. Living Documentation Contract (`README.md`)

- `README.md` MUST document:
  - The `assets/wallpapers/` directory and its `~/Pictures/wallpapers` deployment mapping.
  - The `Mod+Shift+W` (random wallpaper) and `Mod+Ctrl+W` (wallpaper picker) Niri shortcuts.
