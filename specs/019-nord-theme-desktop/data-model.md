# Data Model: System-Wide Nord Theme Across the Desktop-PC Stack

**Feature Branch**: `019-nord-theme-desktop` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

## Entities & Color Mapping Model

### 1. Nord Color Palette (`NordPalette`)

The canonical 16-color palette serving as the single source of truth across all declarative configurations:

| Nord ID | Semantic Group | Hex Code | Role in `desktop-pc` Stack |
| --- | --- | --- | --- |
| `nord0` | Polar Night | `#2E3440` | Primary background (terminals, editors, Fzf `bg`, Starship segment text contrast) |
| `nord1` | Polar Night | `#3B4252` | Elevated surface, selection background (`bg+`), statusbars, Noctalia `surfaceVariant` |
| `nord2` | Polar Night | `#434C5E` | Active line highlight, secondary selection surface |
| `nord3` | Polar Night | `#4C566A` | Inactive window focus ring/border (Niri), Fzf/Lazygit border, Fish comments & autosuggestions |
| `nord4` | Snow Storm | `#D8DEE9` | Primary foreground text (terminals, editors, Fzf `fg`, Lazygit `defaultFgColor`) |
| `nord5` | Snow Storm | `#E5E9F0` | Secondary bright text, terminal white |
| `nord6` | Snow Storm | `#ECEFF4` | Emphasized/highlighted text (`fg+`), cursor color, Noctalia `onSurface` |
| `nord7` | Frost | `#8FBCBB` | Primary cyan-teal accent, Noctalia `primary`, Fzf `hl+` |
| `nord8` | Frost | `#88C0D0` | Primary ice-blue accent, Niri active focus ring/border, Lazygit active border, Fzf `hl` & `pointer` |
| `nord9` | Frost | `#81A1C1` | Secondary arctic blue accent, Fzf `prompt`, Lazygit `optionsTextColor`, Fish commands |
| `nord10` | Frost | `#5E81AC` | Deep ocean blue accent, Noctalia `tertiary`/`hover`, Fzf `header` |
| `nord11` | Aurora | `#BF616A` | Error / urgent state (Niri `urgent-color`, Lazygit `unstagedChangesColor`, Starship OS/error) |
| `nord12` | Aurora | `#D08770` | Warning / secondary accent (Starship `directory` segment, Fish parameters) |
| `nord13` | Aurora | `#EBCB8B` | Caution / search / Git state (Starship `git` segment, Fzf `info`, Lazygit search border) |
| `nord14` | Aurora | `#A3BE8C` | Success / strings / toolchains (Starship language segment, Fzf `marker`, Fish strings) |
| `nord15` | Aurora | `#B48EAD` | Special / time / numbers (Starship `time` segment, Fzf `spinner`) |

---

### 2. Desktop Stack Component Theme Matrix (`ComponentThemeMapping`)

| Component | Module / Dotfile Path | Configuration Mechanism | Target Nord Value |
| --- | --- | --- | --- |
| **Noctalia** | `modules/desktop/dotfiles/noctalia.toml` | `[theme]` TOML table | `source = "builtin"`, `builtin = "Nord"`, `mode = "dark"`, `templates.builtin_ids = []` |
| **Niri** | `modules/desktop/dotfiles/niri/config.kdl` | `layout.focus-ring` & `layout.border` | `active-color "#88c0d0"`, `inactive-color "#4c566a"`, `urgent-color "#bf616a"` |
| **Tuigreet** | `modules/desktop/session.nix` | `services.greetd.settings.default_session.command` | `--theme 'border=cyan;text=white;prompt=cyan;time=cyan;action=blue;button=cyan;container=black;input=white'` |
| **Limine** | `modules/core/base.nix` | `boot.loader.limine.style.wallpapers` | `mosaic-blue`, `nineish-dark-gray`, `simple-blue`, `simple-dark-gray-bootloader`, `waterfall` |
| **WezTerm** | `modules/desktop/terminal.nix` | `programs.wezterm.extraConfig` | `config.color_scheme = 'nord'` |
| **Ghostty** | `modules/desktop/apps.nix` | `programs.ghostty.settings` | `theme = "Nord"` |
| **VS Code** | `modules/desktop/editors.nix` | `programs.vscode.profiles.default` | `arcticicestudio.nord-visual-studio-code` + `"workbench.colorTheme" = "Nord"` |
| **Neovim** | `modules/core/dotfiles/nvim/lua/plugins/colorscheme.lua` & `lua/config/lazy.lua` | LazyVim plugin spec & install fallback | `gbprod/nord.nvim` + `colorscheme = "nord"` |
| **Zed** | `modules/desktop/editors.nix` | `programs.zed-editor` | `extensions = [ "nord" ... ]`, `theme = { mode = "dark"; light = "One Light"; dark = "Nord"; }` |
| **Starship** | `modules/desktop/dotfiles/starship.toml` | `palette` & `[palettes.nord]` | `palette = 'nord'` + Nord Aurora/Frost segment styles |
| **Fish** | `modules/desktop/shell.nix` | `programs.fish.interactiveShellInit` | `set -g fish_color_*` & `set -g fish_pager_color_*` with Nord hex codes |
| **OpenCode** | `modules/desktop/apps.nix` | `programs.opencode.tui` | `theme = "nord"` |
| **Bat** | `modules/desktop/apps.nix` | `programs.bat.config` | `theme = "Nord"` |
| **Fzf** | `modules/desktop/apps.nix` | `programs.fzf.colors` | Nord hex attribute set (`#2e3440` – `#b48ead`) |
| **Yazi** | `modules/desktop/apps.nix` | `programs.yazi.theme` | Nord hex attribute set for `mgr`, `status`, `tabs`, `which`, `notify`, `filetype` |
| **Btop** | `modules/desktop/apps.nix` | `programs.btop` | `enable = true`, `settings.color_theme = "nord"` |
| **Lazygit** | `modules/core/git.nix` | `programs.lazygit.settings.gui.theme` | Nord hex attribute set for borders, selection, and text |

---

## Validation Rules & Invariants

1. **Zero Non-Nord Active Theme References**: Active configuration files in `modules/desktop/` and `modules/core/` must contain zero active references to `catppuccin`, `tokyonight`, or `One Dark` (`SC-002`).
2. **Ghostty Config Validation**: `programs.ghostty.settings.theme = "Nord"` must pass Ghostty's build/activation validator (`ghostty +validate-config`) against `/share/ghostty/themes/Nord`.
3. **Host Isolation Invariant**: `homelab` must continue to evaluate with `enableHomeManager = false` and zero desktop GUI packages (`FR-008`, `SC-004`).
