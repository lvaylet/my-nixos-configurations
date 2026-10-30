# Contract: Unified FiraCode Nerd Font Typography (`020-firacode-nerd-font`)

## 1. System & User Fontconfig Contract (`modules/desktop/fonts.nix`)

- `home.packages` MUST include `pkgs.nerd-fonts.fira-code`.
- `fonts.fontconfig` MUST specify:
  - `enable = true;`
  - `defaultFonts.monospace = [ "FiraCode Nerd Font" "FiraCode Nerd Font Mono" ];`

---

## 2. Code Editors Contract (`modules/desktop/editors.nix`, `modules/core/dotfiles/nvim/`)

### 2.1 VS Code (`modules/desktop/editors.nix`)

`programs.vscode.profiles.default.userSettings` MUST specify:

- `"editor.fontFamily" = "FiraCode Nerd Font";`
- `"editor.fontLigatures" = true;`
- `"terminal.integrated.fontFamily" = "FiraCode Nerd Font";`
- `"terminal.integrated.fontLigatures.enabled" = true;`
- `"debug.console.fontFamily" = "FiraCode Nerd Font";`
- `"scm.inputFontFamily" = "FiraCode Nerd Font";`
- `"chat.editor.fontFamily" = "FiraCode Nerd Font";`

### 2.2 Zed Editor (`modules/desktop/editors.nix`)

`programs.zed-editor.userSettings` MUST specify:

- `buffer_font_family = "FiraCode Nerd Font";`
- `buffer_font_size = 12;`
- `buffer_font_features = { calt = true; };`
- `terminal = { font_family = "FiraCode Nerd Font"; font_size = 12; };`

### 2.3 Neovim / LazyVim (`modules/core/dotfiles/nvim/lua/config/options.lua`)

`lua/config/options.lua` MUST specify:

- `vim.opt.guifont = "FiraCode Nerd Font:h12"`

---

## 3. Terminal Emulators Contract (`modules/desktop/terminal.nix`, `modules/desktop/apps.nix`)

### 3.1 WezTerm (`modules/desktop/terminal.nix`)

`programs.wezterm.extraConfig` MUST specify:

- `config.font = wezterm.font('FiraCode Nerd Font')`
- `config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }`

### 3.2 Ghostty (`modules/desktop/apps.nix`)

`programs.ghostty.settings` MUST specify:

- `font-family = "FiraCode Nerd Font";`
- `font-feature = [ "calt" "clig" "liga" ];`

---

## 4. Living Documentation Contract (`README.md`)

- `README.md` MUST be updated within the same branch to document the unified `FiraCode Nerd Font` typography across editors, terminal emulators, and Fontconfig default monospace resolution.
