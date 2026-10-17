# Implementation Plan: System-Wide Nord Theme Across the Desktop-PC Stack

**Branch**: `019-nord-theme-desktop` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/019-nord-theme-desktop/spec.md`

## Summary

Unify the visual identity of the `desktop-pc` stack (and shared CLI/editor modules) around the official 16-color Arctic **Nord** palette (`#2E3440`–`#B48EAD`), replacing disparate Catppuccin Macchiato/Mocha, TokyoNight, and One Dark configurations across 17 components:
1. **Desktop Session, Compositor, Greeter & Bootloader**: Switch Noctalia (`modules/desktop/dotfiles/noctalia.toml`) to its built-in `"Nord"` dark palette (`source = "builtin"`, `builtin = "Nord"`, `mode = "dark"`, `templates.builtin_ids = []`), update Niri focus-ring and border colors (`modules/desktop/dotfiles/niri/config.kdl`) to Nord Frost (`#88c0d0`), Polar Night (`#4c566a`), and Aurora Red (`#bf616a`), pass a Nord-aligned `--theme` to Tuigreet (`modules/desktop/session.nix`), and replace Catppuccin wallpapers in Limine (`modules/core/base.nix`) with dark/blue NixOS artwork wallpapers.
2. **Terminal Emulators & Code Editors**: Switch WezTerm (`modules/desktop/terminal.nix`) to `color_scheme = 'nord'`, configure Ghostty (`modules/desktop/apps.nix`) with `settings.theme = "Nord"`, retain VS Code's `Nord` theme (`modules/desktop/editors.nix`), switch Zed (`modules/desktop/editors.nix`) to the `nord` extension and `Nord` dark theme, and add a declarative `gbprod/nord.nvim` plugin spec (`modules/core/dotfiles/nvim/lua/plugins/colorscheme.lua` + `lua/config/lazy.lua`) setting LazyVim's colorscheme to `nord`.
3. **Interactive Shell, Prompt & TUI Utilities**: Replace the `catppuccin_macchiato` palette in Starship (`modules/desktop/dotfiles/starship.toml`) with a `[palettes.nord]` definition and Nord powerline segment colors, configure Fish syntax highlighting and pager colors (`modules/desktop/shell.nix`), set OpenCode TUI theme to `nord`, Bat theme to `Nord`, Fzf `colors` to Nord hex codes, Yazi `theme` to Nord hex codes, enable Btop with `color_theme = "nord"` (`modules/desktop/apps.nix`), and configure Lazygit's `gui.theme` with Nord colors (`modules/core/git.nix`).
4. **Living Documentation**: Update `README.md` within the same branch to reflect the unified Nord theme across the stack.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable), Lua (Neovim/LazyVim & WezTerm), TOML (Noctalia & Starship), KDL (Niri)

**Primary Dependencies**:
- `noctalia` (`github:noctalia-dev/noctalia`, built-in `"Nord"` palette)
- `home-manager` (`github:nix-community/home-manager` program modules: `wezterm`, `ghostty`, `vscode`, `zed-editor`, `starship`, `fish`, `opencode`, `bat`, `fzf`, `yazi`, `btop`, `lazygit`)
- `programs.niri` & `services.greetd` (`pkgs.tuigreet`)
- `programs.neovim` with LazyVim & `gbprod/nord.nvim`

**Storage**: N/A (100% declarative NixOS and Home Manager configuration files and store symlinks)

**Testing**:
- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix check`, `deadnix`)
- Host evaluation checks:
  - `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`
  - `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`
  - `nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath`
- Hermetic sandbox checks: `just check` (`nix flake check`)

**Target Platform**: `x86_64-linux` (`desktop-pc` primary target; shared `core.neovim` and `core.base` also evaluated on `homelab`)

**Project Type**: Infrastructure as Code / NixOS & Home Manager Configuration (Dendritic Pattern)

**Performance Goals**:
- Zero network calls required by Noctalia for palette resolution (`source = "builtin"` instead of `source = "community"`).
- Instantaneous theme loading at application startup with zero manual post-install intervention (`SC-003`).

**Constraints**:
- Strict Dendritic Pattern compliance (`modules/core/` and `modules/desktop/`).
- `homelab` MUST retain `enableHomeManager = false` with zero GUI package bleed (`FR-008`).
- Noctalia template hooks (`builtin_ids`) must be empty (`[]`) so Noctalia does not attempt to overwrite read-only Home Manager store symlinks for Niri and WezTerm.
- `README.md` synchronized in the same branch (`FR-009`).

**Scale/Scope**:
- 8 modified Nix/config files: `modules/core/base.nix`, `modules/core/git.nix`, `modules/desktop/apps.nix`, `modules/desktop/editors.nix`, `modules/desktop/session.nix`, `modules/desktop/shell.nix`, `modules/desktop/terminal.nix`, `modules/core/dotfiles/nvim/lua/config/lazy.lua`
- 3 modified dotfile configs: `modules/desktop/dotfiles/noctalia.toml`, `modules/desktop/dotfiles/niri/config.kdl`, `modules/desktop/dotfiles/starship.toml`
- 1 new Neovim plugin spec: `modules/core/dotfiles/nvim/lua/plugins/colorscheme.lua`
- 1 updated documentation file: `README.md`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic Configuration** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` or `/etc` drift | **PASS** | All 17 component themes are declared via NixOS/Home Manager options and version-controlled dotfiles. Disabling Noctalia's imperative `builtin_ids` template hooks eliminates runtime mutation of `$HOME/.config`. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | Theme settings are colocated within their respective domain modules (`core/base.nix`, `core/git.nix`, `core/neovim.nix`, `desktop/session.nix`, `desktop/terminal.nix`, `desktop/editors.nix`, `desktop/shell.nix`, `desktop/apps.nix`). `modules/hosts/desktop-pc.nix` requires no inline overrides. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | All modified `.nix`, `.lua`, `.toml`, `.kdl`, and `.md` files adhere to repository formatting and static analysis checks (`just fmt`, `just lint`, `just check`). |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | Pure visual theme configuration; zero secrets or credentials involved. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Evaluation of `desktop-pc`, `homelab`, and `iso` derivations plus `just check` are enforced in `quickstart.md`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronized with branch changes; dual Bash/Fish syntax when shell-specific | **PASS** | `README.md` is updated in the same branch to reflect the Nord theme across desktop and shared modules. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in a dedicated feature branch associated with a PR | **PASS** | Active work is isolated on dedicated branch `019-nord-theme-desktop`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/019-nord-theme-desktop/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── nord-theme-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
├── core/
│   ├── base.nix                                # Modified: replace Catppuccin Limine wallpapers with dark/blue Nord-harmonious wallpapers
│   ├── git.nix                                 # Modified: add Nord gui.theme to programs.lazygit.settings
│   └── dotfiles/
│       └── nvim/
│           └── lua/
│               ├── config/
│               │   └── lazy.lua                # Modified: set install.colorscheme = { "nord", "habamax" }
│               └── plugins/
│                   └── colorscheme.lua         # New: gbprod/nord.nvim plugin spec + LazyVim colorscheme = "nord"
└── desktop/
    ├── apps.nix                                # Modified: Nord theme for ghostty, opencode, bat, fzf, yazi, btop
    ├── editors.nix                             # Modified: Nord extension & theme for zed-editor; retain VS Code Nord
    ├── session.nix                             # Modified: add Nord-aligned --theme to tuigreet
    ├── shell.nix                               # Modified: add Nord syntax & pager color variables to Fish
    ├── terminal.nix                            # Modified: set WezTerm color_scheme = 'nord'
    └── dotfiles/
        ├── noctalia.toml                       # Modified: source = "builtin", builtin = "Nord", builtin_ids = []
        ├── starship.toml                       # Modified: palette = 'nord' + [palettes.nord] + Nord segment styles
        └── niri/
            └── config.kdl                      # Modified: Nord Frost/Polar Night/Aurora focus-ring & border colors
README.md                                       # Modified: document unified Nord theme across desktop-pc and shared Neovim
```

**Structure Decision**:
Preserves the repository's existing Dendritic module layout without introducing unnecessary wrapper modules. Each component's Nord theme is declared directly in the module or dotfile that owns that component.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| *None* | All changes strictly adhere to Constitution Principles I–VII | N/A |
