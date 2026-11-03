# Shell Aliases, Tools & Design System Reference

[← Back to README](../../README.md)

This document provides the exhaustive reference for shell shortcuts, developer tooling, and visual design standards configured across `desktop-pc`, `homelab`, and `macbook-air-m4-15`.

---

## Dual-Shell Environment (Bash & Fish Duality)

Managed NixOS (`desktop-pc`, `homelab`, `iso`) and Darwin (`macbook-air-m4-15`) hosts operate with a dual-shell architecture across user accounts and operational contexts:

- **Fish (`pkgs.fish`)**: Configured as the default interactive login shell for the primary user (`laurent`) across all hosts (`users.users.${vars.userName}.shell = pkgs.fish` in `modules/core/base.nix`), enriched with native Fish abbreviations (`programs.fish.shellAbbrs`) that expand inline and automatically provide full argument autocompletions without manual `complete -c` wrapper scripts.
- **Bash (`pkgs.bashInteractive`)**: Retained as the default login shell for `root`, the custom headless installer ISO (`modules/core/iso.nix`), non-NixOS bootstrap hosts, and `justfile` execution recipes.
- **Shared System-Wide Aliases & Abbreviations (`environment.shellAliases` & `programs.fish.shellAbbrs`)**: Declared once in `modules/core/base.nix` (`systemdAliases` and `gitAliases`) and shared across NixOS and Darwin, ensuring identical `systemctl`, `journalctl`, and `git` shortcuts whether logged in as `laurent` (Fish) or `root` (Bash).

---

## Service Management (`systemctl`)

| Alias | Command | Purpose / Example |
| --- | --- | --- |
| `sc` | `systemctl` | Base systemctl command (e.g. `sc list-units`) |
| `scs` / `sc-status` | `systemctl status` | Check service status (e.g. `scs jellyfin`) |
| `scr` / `sc-restart` | `systemctl restart` | Restart a service (e.g. `scr podman-homeassistant`) |
| `scl` / `sc-reload` | `systemctl reload` | Reload configuration without restart (e.g. `scl nginx`) |
| `sc-start` | `systemctl start` | Start a stopped service (e.g. `sc-start qbittorrent`) |
| `sc-stop` | `systemctl stop` | Stop a running service (e.g. `sc-stop podman-filebrowser`) |
| `sc-failed` | `systemctl --failed` | List all currently failed systemd units |

---

## Log Inspection (`journalctl`)

| Alias | Command | Purpose / Example |
| --- | --- | --- |
| `jc` | `journalctl` | Open systemd journal viewer |
| `logs` / `jcu` | `journalctl -u` | View logs for a specific unit (e.g. `logs jellyfin` or `jcu podman-portainer`) |
| `logsf` / `jcuf` | `journalctl -f -u` | Follow logs in real time for a unit (e.g. `logsf jellyfin`) |
| `jcf` | `journalctl -f` | Follow all system logs in real time |
| `jcb` | `journalctl -b` | View logs from the current boot only |
| `jce` | `journalctl -e` | Open journal and jump directly to the end |

---

## Git Aliases (Oh-My-Zsh Style)

Common Oh-My-Zsh style Git shortcuts available in both Bash and Fish, with native Fish autocompletion for branches, files, and options:

| Alias | Command | Purpose / Action |
| --- | --- | --- |
| `g` | `git` | Base git command |
| `gst` | `git status` | Show working tree status |
| `ga` / `gaa` | `git add` / `git add --all` | Stage changes (file autocompletion enabled) |
| `gco` / `gcb` | `git checkout` / `git checkout -b` | Checkout branch/commit (branch autocompletion enabled) |
| `gsw` / `gswc` | `git switch` / `git switch -c` | Switch branch (branch autocompletion enabled) |
| `gc` / `gcm` | `git commit --verbose` / `git commit --message` | Create commit |
| `gca` / `gcam` | `git commit --verbose --all` / `git commit --all --message` | Stage all and commit |
| `gc!` / `gca!` / `gcan!` | `git commit --verbose --amend` / `... --all --amend` / `... --all --no-edit --amend` | Amend previous commit (with or without editing message) |
| `gd` / `gds` | `git diff` / `git diff --staged` | Show unstaged or staged changes |
| `gl` / `gp` / `gpf` | `git pull` / `git push` / `git push --force-with-lease` | Sync with remote repository |
| `gb` / `gba` / `gbd` | `git branch` / `git branch --all` / `git branch --delete` | List or delete branches |
| `glo` / `glg` / `glp` | `git log --oneline --decorate` / `git log --stat` / `git log --patch` | View commit logs |
| `grb` / `grbi` / `grbc` / `grba` | `git rebase` / `--interactive` / `--continue` / `--abort` | Rebase operations |
| `gm` / `gmc` / `gma` | `git merge` / `--continue` / `--abort` | Merge operations |
| `gsta` / `gstp` / `gsts` / `gstd` | `git stash apply` / `pop` / `show --patch` / `drop` | Stash management |
| `grh` / `grhh` | `git reset` / `git reset --hard` | Reset working tree |
| `gclean` | `git clean --interactive -d` | Interactively clean untracked files and directories |

---

## Desktop Interactive Fish Extensions (`modules/desktop/shell.nix`)

On desktop workstations (`desktop-pc`), Home Manager extends Fish with Nord syntax/pager highlighting, modern CLI replacements, helper functions, and a declarative Nord-themed [Starship](https://starship.rs/) prompt (`~/.config/starship.toml`):

| Alias / Function | Command | Purpose / Action |
| --- | --- | --- |
| `ls` | `eza --group --group-directories-first --icons --header --time-style long-iso` | Directory listing with icons and ISO timestamps |
| `ll` / `la` | `eza ... --long` / `eza ... --long --all` | Detailed long listing (standard / including hidden files) |
| `llt` / `lat` | `eza ... --long --tree` / `eza ... --long --all --tree` | Recursive tree view (standard / including hidden files) |
| `cat` | `bat` | Syntax-highlighted file viewer (`Nord` theme) |
| `y` | `yazi` | Terminal file manager (`Nord` theme) |
| `b` | `btop` | Interactive system resource monitor (`nord` theme) |
| `d` | `ncdu --exclude /mnt --color dark` | Disk usage analyzer |
| `c` / `x` / `r` | `clear` / `exit` / `source ~/.config/fish/config.fish` | Session control and Fish config reload |
| `take <dir>` | `mkdir -p $argv[1]; and cd $argv[1]` | Create a directory and immediately `cd` into it |

---

## Unified Nord Visual Theme (`desktop-pc` & Shared Stack)

The `desktop-pc` workstation and shared CLI/editor modules use the Arctic, bluish **[Nord](https://www.nordtheme.com/)** color palette (`#2E3440`–`#B48EAD`) consistently across all layers of the stack:

- **Session, Compositor & Boot**: Noctalia desktop shell (`builtin = "Nord"` dark mode), Niri window focus rings and borders (`#88C0D0` active Frost, `#4C566A` inactive Polar Night, `#BF616A` urgent Aurora Red), Tuigreet KMS login screen, and Limine bootloader wallpapers.
- **Terminal Emulators**: WezTerm (`color_scheme = 'nord'`) and Ghostty (`theme = "Nord"`).
- **Code Editors**: Neovim/LazyVim (`gbprod/nord.nvim` with `colorscheme = "nord"`), VS Code and Code Server (`arcticicestudio.nord-visual-studio-code` via shared `modules/core/vscode.nix`), and Zed (`nord` extension with `Nord` dark theme).
- **Shell, Prompt & TUI Utilities**: Starship (`[palettes.nord]`), Fish syntax and pager colors, OpenCode TUI (`theme = "nord"`), Bat (`theme = "Nord"`), Fzf (`colors`), Yazi (`theme`), Btop (`color_theme = "nord"`), and Lazygit (`gui.theme`).

---

## Dynamic Noctalia Wallpapers (`desktop-pc`)

On `desktop-pc`, wallpapers are managed declaratively through the Git repository and rotated dynamically by Noctalia:

- **Versioned Asset Directory**: Images are versioned in `assets/wallpapers/` (tracked via `.gitkeep`) and deployed to `~/Pictures/wallpapers` via Home Manager (`modules/desktop/session.nix`).
- **Startup Randomization & Nord Fallback**: Noctalia is configured (`modules/desktop/dotfiles/noctalia.toml`) with `directory = "~/Pictures/wallpapers"`, `fill_mode = "crop"`, `fill_color = "#2e3440"` (Nord Polar Night fallback when the folder has no images), and `[wallpaper.automation]` (`order = "random"`, `interval_seconds = 86400`) to automatically select a random wallpaper on session startup without automatic mid-session timer disruptions.
- **Niri Desktop Keybindings**:
  - `Mod + Shift + W`: Picks and applies a new random wallpaper immediately (`noctalia msg wallpaper-random`).
  - `Mod + Ctrl + W`: Toggles Noctalia's interactive graphical wallpaper picker panel (`noctalia msg panel-toggle wallpaper`).

---

## Unified Code Typography: FiraCode Nerd Font (`modules/desktop/fonts.nix`)

Whenever source code or terminal text is displayed across the `desktop-pc` stack, **FiraCode Nerd Font** (`pkgs.nerd-fonts.fira-code`) is used with OpenType programming ligatures (`calt`, `clig`, `liga`) and Nerd Font v3 symbol glyphs enabled:

- **System & User Default `monospace` (`modules/desktop/fonts.nix`)**: Fontconfig (`fonts.fontconfig.defaultFonts.monospace`) prioritizes `FiraCode Nerd Font` (with `FiraCode Nerd Font Mono` as fallback) so web browsers, Markdown previews, and system viewers rendering generic `monospace` or `<code>`/`<pre>` blocks automatically use `FiraCode Nerd Font`.
- **Code Editors (`modules/desktop/editors.nix`, `modules/core/vscode.nix`, `modules/core/dotfiles/nvim/`)**:
  - **VS Code & Code Server**: Configured with `"FiraCode Nerd Font"` and ligatures across the code editor (`editor.fontFamily`), integrated terminal (`terminal.integrated.fontFamily`), debug console (`debug.console.fontFamily`), SCM input (`scm.inputFontFamily`), and chat code blocks (`chat.editor.fontFamily`) via shared `modules/core/vscode.nix`.
  - **Zed Editor**: Configured with `buffer_font_family = "FiraCode Nerd Font"` (`calt = true`) and `terminal.font_family = "FiraCode Nerd Font"`.
  - **Neovim / LazyVim**: Inherits `FiraCode Nerd Font` and ligatures from the parent terminal emulator in TUI mode and sets `vim.opt.guifont = "FiraCode Nerd Font:h12"` (`lua/config/options.lua`) for GUI clients.
- **Terminal Emulators (`modules/desktop/terminal.nix`, `modules/desktop/apps.nix`)**: Both **WezTerm** (`wezterm.font('FiraCode Nerd Font')`) and **Ghostty** (`font-family = "FiraCode Nerd Font"`) enable `calt`, `clig`, and `liga` ligature features by default.

---

## Harmonized VS Code & Code Server Configuration (`modules/core/vscode.nix`)

All GUI workstations (`desktop-pc`, `macbook-air-m4-15`) and remote server instances (`homelab`) share a single source of truth for Visual Studio Code and Code Server configurations:

- **Centralized Library (`config.flake.lib.vscode`)**: Declared in `modules/core/vscode.nix` and discovered automatically via `import-tree ./modules`, providing pre-packaged universal extensions (`GitHub Actions`, `GitHub Pull Requests and Issues`, `Nord` theme, `Markdownlint`, `Nix IDE`, `Nix`, `Alejandra`, `Even Better TOML`) and unified editor preferences.
- **Desktop Workstations (`modules/desktop/editors.nix`)**: Home Manager's `programs.vscode.profiles.default` directly references `outputs.lib.vscode.settings` and `outputs.lib.vscode.extensions pkgs`.
- **Homelab Code Server (`modules/services/code-server.nix`)**: Packages Code Server with all shared extensions pre-bundled using `pkgs.vscode-with-extensions.override`, enforcing `settings.json` via `systemd.tmpfiles.rules` (`L+`) pointing to the generated `/nix/store` derivation.

---

## Shared Modal Editor: Neovim & LazyVim (`modules/core/neovim.nix`)

All interactive hosts (`desktop-pc`, `homelab`, and `macbook-air-m4-15`) share a unified, system-level [LazyVim](https://www.lazyvim.org/) editing environment via `core.neovim` without requiring Home Manager on `homelab`:

- **System-Level Neovim Engine**: Configured via NixOS `programs.neovim` and Darwin `environment.systemPackages` (`defaultEditor = true`, `viAlias = true`, `vimAlias = true`), provisioning all upstream LazyVim CLI dependencies (`git`, `gcc`, `gnumake`, `ripgrep`, `fd`, `tree-sitter`, `curl`, `unzip`, `gnutar`, `gzip`) across all hosts.
- **Declarative Configuration Symlink**: Links `~/.config/nvim` to the shared starter files in `modules/core/dotfiles/nvim/` via `systemd.tmpfiles.rules` (`L+`) on Linux/NixOS and via Home Manager `xdg.configFile."nvim"` on macOS.
- **Impermanence State Persistence on `homelab` (`modules/core/preservation.nix`)**: Persists `.local/share/nvim` and `.local/state/nvim` under `/persistent/home/laurent` across reboots.

---

[← Back to README](../../README.md)
