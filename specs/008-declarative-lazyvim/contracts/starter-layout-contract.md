# Interface Contract: LazyVim Starter Layout & Configuration

**Branch**: `008-declarative-lazyvim` | **Date**: 2026-10-12 | **Spec**: [spec.md](../spec.md)

This contract defines the file structure, configuration schema, and behavioral requirements for the LazyVim starter baseline files located in `modules/desktop/dotfiles/nvim/`.

---

## 1. Directory & File Manifest

The configuration tree in `modules/desktop/dotfiles/nvim/` MUST contain the following files, replicating `https://github.com/LazyVim/starter`:

```text
modules/desktop/dotfiles/nvim/
├── init.lua
├── stylua.toml
└── lua/
    ├── config/
    │   ├── autocmds.lua
    │   ├── keymaps.lua
    │   ├── lazy.lua
    │   └── options.lua
    └── plugins/
        └── example.lua
```

---

## 2. File Contract Specifications

### 2.1. `init.lua`
- **Purpose**: Root initialization entrypoint.
- **Contract**:
  ```lua
  -- bootstrap lazy.nvim, LazyVim and your plugins
  require("config.lazy")
  ```

### 2.2. `lua/config/lazy.lua`
- **Purpose**: Bootstraps `lazy.nvim`, configures plugin specifications, and sets runtime parameters.
- **Contract Requirements**:
  1. Bootstraps `lazy.nvim` repository into `vim.fn.stdpath("data") .. "/lazy/lazy.nvim"` using `git clone` if not present.
  2. Prepends lazypath to `vim.opt.rtp`.
  3. Invokes `require("lazy").setup` with:
     - Plugin specs: `{ "LazyVim/LazyVim", import = "lazyvim.plugins" }` and `{ import = "plugins" }`.
     - Explicit writable lockfile: `lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json"`.
     - Defaults: `lazy = false`, `version = false`.
     - Checker: `enabled = true, notify = false`.
     - Performance: standard RTP disabled plugins.

### 2.3. `lua/config/options.lua`
- **Purpose**: Global options loaded before `lazy.nvim` startup.
- **Contract Requirements**:
  - Contains comment headers and optional user custom option overrides (`vim.opt`, `vim.g`).

### 2.4. `lua/config/keymaps.lua`
- **Purpose**: Custom keymaps loaded on the `VeryLazy` event.
- **Contract Requirements**:
  - Contains comment headers and optional user keybinding overrides.

### 2.5. `lua/config/autocmds.lua`
- **Purpose**: Custom autocommands loaded on the `VeryLazy` event.
- **Contract Requirements**:
  - Contains comment headers and optional user autocommand definitions.

### 2.6. `lua/plugins/example.lua`
- **Purpose**: Reference plugin overrides demonstrating how users add or modify plugins.
- **Contract Requirements**:
  - Valid Lua table returning plugin specifications according to standard `lazy.nvim` syntax.

### 2.7. `stylua.toml`
- **Purpose**: Code formatting configuration for Lua files.
- **Contract Requirements**:
  - Replicates upstream formatting rules.

---

## 3. Runtime Storage Guarantees

| Storage Category | Path | Writable | Description |
|---|---|---|---|
| Configuration | `~/.config/nvim/` | No (read-only symlink to Nix store) | Declarative immutable code |
| Lockfile | `~/.local/share/nvim/lazy-lock.json` | Yes | Pinned plugin commits |
| Plugins | `~/.local/share/nvim/lazy/` | Yes | Downloaded Git repositories |
| Parsers | `~/.local/share/nvim/treesitter/` | Yes | Compiled C parsers |
| Cache | `~/.cache/nvim/` | Yes | Transient logs and indexing |
