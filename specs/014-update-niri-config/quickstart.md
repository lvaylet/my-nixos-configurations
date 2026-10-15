# Quickstart Validation Guide: Update Niri Configuration with Upstream Defaults and Documentation

**Branch**: `014-update-niri-config` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This guide provides step-by-step procedures (compatible with both **Bash** and **Fish** shells) to validate that the updated `modules/desktop/dotfiles/niri/config.kdl` satisfies all functional requirements, contracts, and repository quality gates.

---

## Prerequisites

1. Working copy of `my-nixos-configurations` on branch `014-update-niri-config`.
2. Nix with Flakes enabled (`nix-command flakes`).
3. `just` task runner installed.

---

## Scenario 1: Validate Niri KDL Configuration Syntax & Schema

Verify that `modules/desktop/dotfiles/niri/config.kdl` parses cleanly with Niri's built-in validator and contains zero duplicate keybindings or invalid options.

**Bash / Fish**:

```sh
# Validate using niri directly (if in PATH) or via nix run:
nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl
```

**Expected Outcome**:

- Outputs `config is valid` and exits with code `0`.

---

## Scenario 2: Verify Preserved Customizations & Upstream Sections

Confirm that personal customizations (`noctalia`, `wezterm`, `us,fr` keyboard layout, `gaps 8`, `#cba6f7` focus ring, `prefer-no-csd`) and upstream sections (`/-output`, `shadow`, `struts`, `hotkey-overlay`, `screenshot-path`, `animations`, `window-rule`, `binds`) are present.

**Bash / Fish**:

```sh
# Check key personal settings and upstream sections in config.kdl:
rg -n 'spawn-at-startup "noctalia"|layout "us,fr"|gaps 8|active-color "#cba6f7"|prefer-no-csd|screenshot-path|toggle-overview|toggle-keyboard-shortcuts-inhibit' modules/desktop/dotfiles/niri/config.kdl
```

**Expected Outcome**:

- Matches all expected directives in `modules/desktop/dotfiles/niri/config.kdl`.

---

## Scenario 3: Verify Code Formatting & Static Analysis

Verify that all repository Nix expressions and tracked files adhere to formatting and lint rules.

**Bash / Fish**:

```sh
# 1. Format repository files
just fmt

# 2. Run static linters (deadnix & statix)
just lint
```

**Expected Outcome**:

- `just fmt` and `just lint` complete with exit code `0` and zero warnings.

---

## Scenario 4: Validate Flake Evaluation & Hermetic Sandbox Checks

Ensure that the `desktop-pc` configuration evaluates cleanly and all pre-commit hooks pass in the hermetic Nix sandbox.

**Bash / Fish**:

```sh
# 1. Evaluate desktop-pc system toplevel derivation
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath

# 2. Run full flake check suite
just check
```

**Expected Outcome**:

- `nix eval` returns a valid `.drv` store path.
- `just check` passes all hooks (`alejandra`, `statix`, `deadnix`, `ripsecrets`, `trufflehog`, trailing whitespace, end-of-file fixer) with exit code `0`.

---

## Scenario 5: Live Session Activation Test on `desktop-pc`

Apply the updated configuration temporarily (or permanently) on `desktop-pc`:

**Bash / Fish**:

```sh
# Test activation without updating bootloader entries:
just test configuration="desktop-pc"

# Or switch permanently:
just switch configuration="desktop-pc"
```

**Expected Outcome**:

- Niri hot-reloads `~/.config/niri/config.kdl` automatically without restarting the session.
- Pressing `Mod+Shift+Slash` displays the Hotkey Overlay including the WezTerm and Noctalia titles.
- Pressing `Mod+O` toggles the Niri Overview.
- Pressing `Mod+Return` or `Mod+T` opens WezTerm.
- Pressing `Mod+Space` or `Mod+D` toggles the Noctalia launcher.
- Pressing `Super+Alt+L` locks the screen via Noctalia.
