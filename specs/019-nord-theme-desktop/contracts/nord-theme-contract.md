# Contract: System-Wide Nord Theme Configuration (`019-nord-theme-desktop`)

## 1. Desktop Session & Window Management Contract (`modules/desktop/session.nix`, `modules/core/base.nix`)

### 1.1 Noctalia (`modules/desktop/dotfiles/noctalia.toml`)
- `[theme]` MUST specify:
  - `source = "builtin"`
  - `builtin = "Nord"`
  - `mode = "dark"`
- `[theme.templates]` MUST specify:
  - `builtin_ids = []` (preventing runtime mutations of read-only Home Manager symlinks)

### 1.2 Niri (`modules/desktop/dotfiles/niri/config.kdl`)
- `layout.focus-ring` MUST specify:
  - `active-color "#88c0d0"`
  - `inactive-color "#4c566a"`
- `layout.border` MUST specify:
  - `active-color "#88c0d0"`
  - `inactive-color "#4c566a"`
  - `urgent-color "#bf616a"`

### 1.3 Tuigreet (`modules/desktop/session.nix`) & Limine (`modules/core/base.nix`)
- `services.greetd.settings.default_session.command` MUST include `--theme 'border=cyan;text=white;prompt=cyan;time=cyan;action=blue;button=cyan;container=black;input=white'`.
- `boot.loader.limine.style.wallpapers` MUST NOT contain `catppuccin-macchiato` or `nineish-catppuccin-macchiato`.

---

## 2. Terminal Emulators & Code Editors Contract (`modules/desktop/terminal.nix`, `modules/desktop/editors.nix`, `modules/core/dotfiles/nvim/`)

### 2.1 Terminals
- **WezTerm** (`modules/desktop/terminal.nix`): `config.color_scheme = 'nord'`.
- **Ghostty** (`modules/desktop/apps.nix`): `programs.ghostty.settings.theme = "Nord"`.

### 2.2 Editors
- **VS Code** (`modules/desktop/editors.nix`): `arcticicestudio.nord-visual-studio-code` in `extensions` and `"workbench.colorTheme" = "Nord"` in `userSettings`.
- **Neovim** (`modules/core/dotfiles/nvim/`):
  - `lua/plugins/colorscheme.lua` MUST declare `"gbprod/nord.nvim"` and configure `"LazyVim/LazyVim"` with `opts = { colorscheme = "nord" }`.
  - `lua/config/lazy.lua` MUST set `install = { colorscheme = { "nord", "habamax" } }`.
- **Zed Editor** (`modules/desktop/editors.nix`):
  - `extensions` MUST include `"nord"` (and exclude `"one-dark-pro"`).
  - `userSettings.theme` MUST set `dark = "Nord"`.

---

## 3. Shell, Prompt & TUI Utilities Contract (`modules/desktop/shell.nix`, `modules/desktop/apps.nix`, `modules/core/git.nix`)

- **Starship** (`modules/desktop/dotfiles/starship.toml`): `palette = 'nord'` with `[palettes.nord]` defining the 16 official Nord colors and all powerline segments referencing `[palettes.nord]` keys.
- **Fish** (`modules/desktop/shell.nix`): `interactiveShellInit` sets `fish_color_*` and `fish_pager_color_*` global variables to Nord hex values.
- **OpenCode** (`modules/desktop/apps.nix`): `programs.opencode.tui.theme = "nord"`.
- **Bat** (`modules/desktop/apps.nix`): `programs.bat.config.theme = "Nord"`.
- **Fzf** (`modules/desktop/apps.nix`): `programs.fzf.colors` maps UI elements to official Nord hex codes.
- **Yazi** (`modules/desktop/apps.nix`): `programs.yazi.theme` maps manager, tabs, status, and indicator styles to official Nord hex codes.
- **Btop** (`modules/desktop/apps.nix`): `programs.btop = { enable = true; settings.color_theme = "nord"; }`.
- **Lazygit** (`modules/core/git.nix`): `programs.lazygit.settings.gui.theme` maps border, selection, and text colors to official Nord hex codes.

---

## 4. Living Documentation Contract (`README.md`)

- `README.md` MUST be updated within the same branch to document the unified Nord visual theme across `desktop-pc` and shared CLI/editor modules.
