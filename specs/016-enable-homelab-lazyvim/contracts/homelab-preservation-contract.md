# Interface Contract: Homelab Neovim State Preservation

**Branch**: `016-enable-homelab-lazyvim` | **Date**: 2026-10-15 | **Spec**: [spec.md](../spec.md)

This contract defines the user state persistence guarantees for Neovim/LazyVim on the impermanent `homelab` server in `modules/core/preservation.nix`.

---

## 1. Preserved User Directories (`modules/core/preservation.nix`)

Within `preservation.preserveAt."/persistent".users.${vars.userName}.directories`, the following entries MUST be declared:

```nix
users.${vars.userName} = {
  directories = [
    ".ssh"
    ".config/gh" # GitHub CLI authentication and configuration
    ".local/share/fish" # Fish shell history and universal variables
    ".local/share/nvim" # LazyVim plugins, lockfile, and Tree-sitter parsers
    ".local/state/nvim" # Neovim undo history, ShaDa, and session state
  ];
};
```

---

## 2. Filesystem Lifecycle Guarantees

| Path | Management Mechanism | Reboot Behavior on `homelab` |
| --- | --- | --- |
| `~/.config/nvim` | Home Manager (`xdg.configFile."nvim".source`) | Recreated automatically on boot/activation as a read-only symlink to the Nix store |
| `~/.local/share/nvim` | `preservation` (`/persistent/home/laurent/.local/share/nvim`) | Persisted across reboots (retains `lazy.nvim`, plugins, `lazy-lock.json`, Tree-sitter parsers) |
| `~/.local/state/nvim` | `preservation` (`/persistent/home/laurent/.local/state/nvim`) | Persisted across reboots (retains undo history, ShaDa, swap/session data) |
| `~/.cache/nvim` | Ephemeral (`tmpfs`) | Cleared on reboot; regenerated automatically by Neovim on demand |
