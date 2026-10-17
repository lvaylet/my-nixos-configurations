# Quickstart & Validation Guide: Shared System-Level Neovim Configuration

**Branch**: `017-share-neovim-config` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

This guide provides runnable validation checks to verify that the shared `core.neovim` module works across both `desktop-pc` and `homelab` without Home Manager on `homelab`.

---

## 1. Static Analysis, Formatting & Flake Check

Run the repository quality gates from the workspace root:

```bash
just fmt
just lint
just check
```

**Expected Outcome**:
- `alejandra`, `statix`, and `deadnix` complete with 0 warnings or errors.
- `nix flake check` evaluates all host configurations (`desktop-pc`, `homelab`, `iso`) and pre-commit hooks with exit code `0`.

---

## 2. Verify System-Level Neovim Evaluation on Both Hosts

Verify that both `desktop-pc` and `homelab` enable `programs.neovim` at the NixOS system level and register the `L+ /home/laurent/.config/nvim` tmpfiles rule:

```bash
# Check programs.neovim.enable on homelab and desktop-pc
nix eval .#nixosConfigurations.homelab.config.programs.neovim.enable
nix eval .#nixosConfigurations.desktop-pc.config.programs.neovim.enable

# Verify tmpfiles rule for ~/.config/nvim on homelab
nix eval --json .#nixosConfigurations.homelab.config.systemd.tmpfiles.rules

# Verify Neovim persistence directories on homelab
nix eval --json .#nixosConfigurations.homelab.config.preservation.preserveAt.\"/persistent\".users.laurent.directories
```

**Expected Outcome**:
- Both `programs.neovim.enable` evaluations return `true`.
- `systemd.tmpfiles.rules` includes `"L+ /home/laurent/.config/nvim - - - - /nix/store/...-nvim"`.
- Preserved directories on `homelab` include `".local/share/nvim"` and `".local/state/nvim"`.

---

## 3. Runtime Verification After Activation

After activating the configuration (`just test` or `just switch`):

```bash
# 1. Verify symlink target
ls -ld ~/.config/nvim

# 2. Verify aliases and default editor
echo $EDITOR
nvim --version
vim --version
vi --version

# 3. Launch LazyVim
nvim
```

**Expected Outcome**:
- `~/.config/nvim` is a symlink pointing to the `/nix/store/...-nvim` directory containing `init.lua`, `stylua.toml`, and `lua/`.
- `$EDITOR` is `nvim`, and `vim`/`vi` resolve to Neovim.
- `nvim` starts the LazyVim dashboard cleanly with all external tools (`rg`, `fd`, `gcc`, `make`, `tree-sitter`, `git`) available in `PATH`.
