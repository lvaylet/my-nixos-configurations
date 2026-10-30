# Implementation Plan: Unified FiraCode Nerd Font Typography Across All Code & Terminal Views

**Branch**: `020-firacode-nerd-font` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/020-firacode-nerd-font/spec.md`

## Summary

Ensure `FiraCode Nerd Font` (with OpenType programming ligatures and Nerd Font v3 glyphs) is used consistently across every application and surface that displays source code or terminal text on `desktop-pc` (and shared editor configurations):

1. **System/User Fontconfig Monospace Default (`modules/desktop/fonts.nix`)**: Configure `fonts.fontconfig.defaultFonts.monospace = [ "FiraCode Nerd Font" "FiraCode Nerd Font Mono" ]` alongside `nerd-fonts.fira-code` so any application requesting the generic `monospace` font family (web browsers rendering `<code>`/`<pre>`, Markdown viewers, GTK/Qt dialogs) automatically uses `FiraCode Nerd Font`.
2. **Code Editors (`modules/desktop/editors.nix` & `modules/core/dotfiles/nvim/lua/config/options.lua`)**:
   - **VS Code**: Retain `"editor.fontFamily" = "FiraCode Nerd Font"` (`"editor.fontLigatures" = true`) and `"terminal.integrated.fontFamily" = "FiraCode Nerd Font"` (`"terminal.integrated.fontLigatures.enabled" = true`), and extend `FiraCode Nerd Font` to auxiliary code views (`"debug.console.fontFamily"`, `"scm.inputFontFamily"`, `"chat.editor.fontFamily"`).
   - **Zed Editor**: Configure `buffer_font_family = "FiraCode Nerd Font"`, `buffer_font_size = 12`, `buffer_font_features = { calt = true; }`, and `terminal = { font_family = "FiraCode Nerd Font"; font_size = 12; }` in `programs.zed-editor.userSettings`.
   - **Neovim / LazyVim**: Set `vim.opt.guifont = "FiraCode Nerd Font:h12"` in `modules/core/dotfiles/nvim/lua/config/options.lua` for graphical Neovim clients while terminal Neovim inherits `FiraCode Nerd Font` from the host terminal emulator.
3. **Terminal Emulators (`modules/desktop/terminal.nix` & `modules/desktop/apps.nix`)**:
   - **WezTerm**: Retain `config.font = wezterm.font('FiraCode Nerd Font')`, `config.font_size = 11.5`, and `config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }`.
   - **Ghostty**: Add `font-family = "FiraCode Nerd Font"` and `font-feature = [ "calt" "clig" "liga" ]` to `programs.ghostty.settings`.
4. **Living Documentation (`README.md`)**: Update `README.md` within the same branch to document the unified `FiraCode Nerd Font` typography across editors, terminals, and Fontconfig defaults.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable), Lua (Neovim/LazyVim & WezTerm)

**Primary Dependencies**:

- `pkgs.nerd-fonts.fira-code` (`modules/desktop/fonts.nix`)
- `home-manager` (`fonts.fontconfig`, `programs.vscode`, `programs.zed-editor`, `programs.wezterm`, `programs.ghostty`)
- `programs.neovim` with LazyVim (`modules/core/neovim.nix` & `modules/core/dotfiles/nvim/`)

**Storage**: N/A (100% declarative NixOS and Home Manager configuration files and store symlinks)

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix check`, `deadnix`)
- Host evaluation checks:
  - `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`
  - `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`
  - `nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath`
- Hermetic sandbox checks: `just check` (`nix flake check`)

**Target Platform**: `x86_64-linux` (`desktop-pc` primary target; shared `core.neovim` also evaluated on `homelab`)

**Project Type**: Infrastructure as Code / NixOS & Home Manager Configuration (Dendritic Pattern)

**Performance Goals**:

- Zero runtime font downloading or imperative cache generation outside Nix build/activation.
- Hardware-accelerated OpenType ligature shaping (`calt`, `clig`, `liga`) at 60+ FPS across GPU terminals (WezTerm, Ghostty) and editors (VS Code, Zed, Neovim).

**Constraints**:

- Strict Dendritic Pattern compliance (`modules/core/` and `modules/desktop/`).
- `homelab` MUST retain `enableHomeManager = false` with zero GUI font package bleed (`FR-006`).
- `programs.ghostty.settings` MUST pass Ghostty's build-time `ghostty +validate-config` check.
- `README.md` synchronized in the same branch (`FR-007`).

**Scale/Scope**:

- 3 modified Nix modules: `modules/desktop/fonts.nix`, `modules/desktop/editors.nix`, `modules/desktop/apps.nix` (plus verification of `modules/desktop/terminal.nix`)
- 1 modified Lua dotfile: `modules/core/dotfiles/nvim/lua/config/options.lua`
- 1 updated documentation file: `README.md`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic Configuration** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` or `/etc` drift | **PASS** | All font installations, Fontconfig default aliases, and application typography settings are declared via Home Manager options and version-controlled dotfiles. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | Font and typography settings are colocated within `desktop/fonts.nix`, `desktop/editors.nix`, `desktop/terminal.nix`, `desktop/apps.nix`, and `core/dotfiles/nvim/`. `modules/hosts/desktop-pc.nix` requires no inline changes. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | All modified `.nix`, `.lua`, and `.md` files adhere to repository formatting and static analysis checks (`just fmt`, `just lint`, `just check`). |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | Pure typography configuration; zero secrets or credentials involved. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Evaluation of `desktop-pc`, `homelab`, and `iso` derivations plus `just check` are enforced in `quickstart.md`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronized with branch changes; dual Bash/Fish syntax when shell-specific | **PASS** | `README.md` is updated in the same branch to document the unified `FiraCode Nerd Font` typography across the stack. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in a dedicated feature branch associated with a PR | **PASS** | Work will be isolated on dedicated branch `020-firacode-nerd-font` and associated with a PR targeting `main`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/020-firacode-nerd-font/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── firacode-typography-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
├── core/
│   └── dotfiles/
│       └── nvim/
│           └── lua/
│               └── config/
│                   └── options.lua             # Modified: set vim.opt.guifont = "FiraCode Nerd Font:h12"
└── desktop/
    ├── apps.nix                                # Modified: set font-family = "FiraCode Nerd Font" & font-feature in programs.ghostty.settings
    ├── editors.nix                             # Modified: add FiraCode Nerd Font to Zed buffer/terminal and VS Code debug/scm/chat code views
    ├── fonts.nix                               # Modified: set fonts.fontconfig.defaultFonts.monospace = [ "FiraCode Nerd Font" "FiraCode Nerd Font Mono" ]
    └── terminal.nix                            # Verified: WezTerm font('FiraCode Nerd Font') and harfbuzz_features
README.md                                       # Modified: document unified FiraCode Nerd Font typography across editors, terminals, and monospace defaults
```

**Structure Decision**:
Preserves the repository's existing Dendritic module layout without introducing new modules. Each component's font and ligature settings are declared directly in the module or dotfile that owns that component.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| *None* | All changes strictly adhere to Constitution Principles I–VII | N/A |
