# Quickstart Validation Guide: Declarative LazyVim Configuration

**Branch**: `008-declarative-lazyvim` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

This guide provides step-by-step procedures to validate that the declarative LazyVim integration satisfies all requirements, contracts, and quality gates.

---

## Prerequisites

1. Working copy of `my-nixos-configurations` on branch `feat-declarative-lazyvim`.
2. Nix with Flakes enabled (`nix-command flakes`).
3. `just` task runner installed.

---

## Scenario 1: Verify Code Formatting & Static Analysis

Verify that all updated Nix expressions and configuration files adhere to formatting rules and contain zero unused bindings or lint issues.

```bash
# 1. Format Nix expressions with alejandra
just fmt

# 2. Check for dead code (unused bindings) and syntax lints
just lint
```

**Expected Outcome**:
- All `.nix` files format cleanly with `alejandra`.
- `deadnix` and `statix check` complete with exit code 0 and zero warnings.

---

## Scenario 2: Validate Flake Evaluation Across Targets

Ensure that replacing `nvf` with declarative LazyVim evaluates cleanly across all system configurations without regressions.

```bash
# 1. Evaluate desktop-pc system toplevel derivation
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath

# 2. Ensure homelab target evaluates without regression
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath

# 3. Ensure iso target evaluates without regression
nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath

# 4. Run pre-commit sandbox checks
just check
```

**Expected Outcome**:
- All three evaluation commands succeed, returning valid store paths.
- `just check` (`nix flake check`) passes with exit code 0.

---

## Scenario 3: Verify Runtime Toolchain & Binary Availability

Verify that all upstream runtime dependencies specified in [cli-contract.md](contracts/cli-contract.md) are present in the user profile:

```bash
# 1. Verify editor binary and aliases
nvim --version
vim --version
vi --version

# 2. Verify upstream search and discovery tools
rg --version
fd --version

# 3. Verify compiler and build tools
gcc --version
make --version

# 4. Verify version control client
git --version

# 5. Verify Wayland clipboard integration
wl-copy --version
wl-paste --version
```

**Expected Outcome**:
- Each command returns a valid version string matching or exceeding minimum version requirements defined in [cli-contract.md](contracts/cli-contract.md).

---

## Scenario 4: Verify Starter Layout & Writable Lockfile Configuration

Verify that the declarative starter files are properly linked into the user's home configuration and that the lockfile points to writable storage:

```bash
# 1. Inspect ~/.config/nvim symlink
ls -la ~/.config/nvim/
# Expected: symlink pointing into the Nix store

# 2. Verify essential starter files are present
ls -la ~/.config/nvim/init.lua
ls -la ~/.config/nvim/lua/config/lazy.lua
ls -la ~/.config/nvim/lua/plugins/

# 3. Verify lockfile configuration in lazy.lua
grep -F 'lockfile' ~/.config/nvim/lua/config/lazy.lua
# Expected: lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json"
```

**Expected Outcome**:
- `~/.config/nvim` matches the layout specified in [starter-layout-contract.md](contracts/starter-layout-contract.md).
- The lockfile parameter is set to `vim.fn.stdpath("data") .. "/lazy-lock.json"`.

---

## Scenario 5: End-to-End Editor Launch & Plugin Initialization

Launch the editor in a terminal to verify the initial startup sequence and plugin bootstrap:

```bash
# Launch Neovim
nvim
```

**Expected Outcome**:
- LazyVim boots, automatically clones `lazy.nvim` into `~/.local/share/nvim/lazy/lazy.nvim` if not already present, loads the LazyVim starter UI, and presents the starter dashboard screen without errors.
- Pressing `<leader>ff` or `<space>ff` triggers file finding via `fd`.
- Pressing `<leader>sg` or `<space>sg` triggers live grep via `ripgrep`.
- Running `:Lazy` opens the Lazy.nvim dashboard showing installed and managed plugins.
