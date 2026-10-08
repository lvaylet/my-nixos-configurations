# Quickstart: NNN Stack Desktop Validation Guide

**Feature Branch**: `feat-migrate-to-niri-and-noctalia` | **Date**: 2026-10-08 | **Spec**: [spec.md](spec.md)

This guide documents runnable validation scenarios to verify that the Niri + Noctalia desktop environment, WezTerm terminal, Fish shell, and FiraCode Nerd Font ligatures function end-to-end.

---

## Prerequisites

- Local NixOS repository checkout on the `desktop-pc` workstation (or test system).
- Nix flakes enabled with `just` task runner available.
- Internet connectivity to resolve upstream flake inputs (`noctalia`).

---

## Scenario 1: Flake Evaluation & Static Quality Gates

Verify that all new Nix expressions format cleanly, adhere to linting rules, and evaluate without errors:

```bash
# 1. Format all Nix files
just fmt

# 2. Check for dead code and static warnings
just lint

# 3. Verify hermetic flake checks and pre-commit hooks
just check
```

**Expected Outcome**:
All checks pass with exit code `0`. No warnings, dead bindings, or syntax issues.

---

## Scenario 2: Dry-Run Configuration Build

Verify that the `desktop-pc` system derivation builds completely without evaluating broken dependencies or missing module imports:

```bash
# Build desktop-pc toplevel derivation
nix build .#nixosConfigurations.desktop-pc.config.system.build.toplevel --no-link
```

**Expected Outcome**:
The derivation builds successfully to completion. Niri, Greetd, Noctalia, WezTerm, Fish, and FiraCode Nerd Font are included in the system closure.

---

## Scenario 3: Non-Switching Live Activation Testing

Test the configuration safely in temporary state without modifying the default bootloader generation:

```bash
# Activate new desktop configuration in live test mode
just test configuration="desktop-pc"
```

**Expected Outcome**:
- System services switch cleanly without error.
- Greetd / tuigreet is initialized as the display greeter.
- Prior COSMIC desktop services (`cosmic-session`, `cosmic-greeter`) are inactive.

---

## Scenario 4: Desktop Session & Window Management Verification

Log into the workstation session:

1. Authenticate at the `tuigreet` prompt.
2. Verify Niri starts and displays the infinite horizontal scrollable workspace.
3. Verify Noctalia's top bar displays system indicators (audio, clock, battery/status).
4. Press `Mod+Return`: Verify WezTerm launches promptly.
5. Press `Mod+Space`: Verify Noctalia's application launcher appears with fuzzy search capability.
6. Open multiple windows and scroll horizontally using `Mod+H` and `Mod+L`.

**Expected Outcome**:
Smooth Wayland compositor rendering at native refresh rate with responsive shell and window controls.

---

## Scenario 5: Terminal & Shell Ergonomics Verification

In WezTerm:

1. Check interactive shell:
   ```fish
   echo $SHELL
   # Should report /run/current-system/sw/bin/fish or user fish path
   ```
2. Type an intentional syntax error (e.g. `nonexistentcmd`) and observe immediate red syntax highlighting.
3. Type a valid command (e.g. `git status`) and verify green highlighting and inline gray history autosuggestions.
4. Verify Starship prompt displays Git branch and directory status.

**Expected Outcome**:
Fish shell renders prompt in under 50ms with active autosuggestions and syntax highlighting.

---

## Scenario 6: Font Typography & Ligatures Verification

In WezTerm and Neovim:

1. In WezTerm, print common programming comparison and arrow sequences:
   ```bash
   printf "!= == === <= >= -> => <=> /* */\n"
   ```
2. Open a source file in Neovim:
   ```bash
   nvim test.nix
   ```
3. Type ligature sequences (`!=`, `->`, `==`, `=>`).

**Expected Outcome**:
- Character sequences merge visually into single cohesive ligature glyphs.
- Nerd Font icons in Neovim statusline (`lualine`) and file tree (`nvimTree`) display crisply with zero missing glyph boxes.

---

## Scenario 7: COSMIC Service Absence Audit

Verify that COSMIC background daemons are completely absent from running processes:

```bash
pgrep -l cosmic || echo "Zero COSMIC processes running"
```

**Expected Outcome**:
Command prints "Zero COSMIC processes running" with no active COSMIC daemons.
