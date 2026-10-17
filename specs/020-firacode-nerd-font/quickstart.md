# Quickstart & Validation Guide: Unified FiraCode Nerd Font Typography

**Feature Branch**: `020-firacode-nerd-font` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

## Prerequisites

- Nix with Flakes enabled (or Devbox)
- Repository checked out on branch `020-firacode-nerd-font`

## 1. Automated Static Analysis & Formatting

Format all Nix and Lua files and run static linters:

```sh
just fmt
just lint
```

**Expected Outcome**: Zero formatting diffs and zero warnings/errors from `alejandra`, `statix`, and `deadnix`.

## 2. Verify Declarative Font Options via `nix eval`

Verify that Fontconfig's default monospace font, VS Code settings, Zed settings, WezTerm config, and Ghostty settings evaluate to `FiraCode Nerd Font`:

```sh
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.fonts.fontconfig.defaultFonts.monospace --json
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.ghostty.settings --json
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.zed-editor.userSettings --json
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.programs.vscode.profiles.default.userSettings --json
```

**Expected Outcome**:
- `defaultFonts.monospace` returns `["FiraCode Nerd Font","FiraCode Nerd Font Mono"]`.
- `ghostty.settings` includes `"font-family":"FiraCode Nerd Font"` and `"font-feature":["calt","clig","liga"]`.
- `zed-editor.userSettings` includes `"buffer_font_family":"FiraCode Nerd Font"` and `"terminal":{"font_family":"FiraCode Nerd Font","font_size":12}`.
- `vscode.profiles.default.userSettings` includes `"FiraCode Nerd Font"` for `editor.fontFamily`, `terminal.integrated.fontFamily`, `debug.console.fontFamily`, `scm.inputFontFamily`, and `chat.editor.fontFamily`.

## 3. Flake Evaluation & Multi-Host Closure Verification

Verify that `desktop-pc`, `homelab`, and `iso` evaluate cleanly and pass all sandbox checks:

```sh
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath
just check
```

**Expected Outcome**: All evaluations return store derivation paths and `just check` exits with code `0`.

## 4. Live Desktop Verification (`desktop-pc`)

Test and activate the configuration on `desktop-pc`:

```sh
just test configuration="desktop-pc"
# Once verified:
just switch configuration="desktop-pc"
```

Verify `FiraCode Nerd Font` rendering across applications:
1. **Fontconfig Monospace Default**: Run `fc-match monospace` and confirm it outputs `FiraCodeNerdFont-Regular.ttf: "FiraCode Nerd Font" "Regular"`.
2. **VS Code & Zed**: Open a `.nix` or `.lua` file and the integrated terminal in both `code` and `zeditor`; confirm `FiraCode Nerd Font` ligatures (`!=`, `==`, `->`, `=>`) and Nerd Font icons render in both the editor buffer and integrated terminal.
3. **WezTerm, Ghostty & Neovim**: Open `wezterm` and `ghostty`, launch `nvim`, `bat`, and `lazygit`, and confirm identical `FiraCode Nerd Font` ligatures and statusline/file-tree icons.
