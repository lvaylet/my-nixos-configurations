# Quickstart & Validation Guide: System-Wide Nord Theme Across the Desktop-PC Stack

**Feature Branch**: `019-nord-theme-desktop` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

## Prerequisites

- Nix with Flakes enabled (or Devbox)
- Repository checked out on branch `019-nord-theme-desktop`

## 1. Automated Static Analysis & Formatting

Format all Nix and Lua files and run static linters:

```sh
just fmt
just lint
```

**Expected Outcome**: Zero formatting diffs and zero warnings/errors from `alejandra`, `statix`, and `deadnix`.

## 2. Verify Zero Residual Catppuccin / TokyoNight / One Dark Active Theme References

Check that no active theme configuration in `modules/` references the old color schemes:

```sh
rg -i 'catppuccin|tokyonight|one-dark|One Dark' modules/
```

**Expected Outcome**: Zero active theme matches in `modules/core/` and `modules/desktop/` (excluding any upstream commented-out reference comments if any).

## 3. Flake Evaluation & Multi-Host Closure Verification

Verify that `desktop-pc`, `homelab`, and `iso` evaluate cleanly:

```sh
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath
```

Verify that `homelab` still has Home Manager disabled:

```sh
nix eval .#nixosConfigurations.homelab.pkgs.system
```

Run the full hermetic sandbox check suite:

```sh
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

Verify the Nord theme across stack components:

1. **Noctalia & Niri**: Panels, launcher (`Mod+D`), control center (`Mod+N`), and window focus rings (`#88C0D0` active, `#4C566A` inactive) display in Nord colors.
2. **Terminals**: Launch `wezterm` and `ghostty`; confirm `#2E3440` Polar Night background and Nord ANSI palette.
3. **Editors**: Launch `code`, `nvim`, and `zeditor`; confirm all three load the Nord colorscheme automatically.
4. **Shell & TUI Tools**: In Fish, inspect the Starship powerline prompt and run `opencode`, `bat README.md`, `fzf`, `yazi`, `btop` (`b`), and `lazygit`; confirm all render with the Nord palette.
