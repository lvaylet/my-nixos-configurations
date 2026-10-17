# Feature Specification: System-Wide Nord Theme Across the Desktop-PC Stack

**Feature Branch**: `019-nord-theme-desktop`

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "Applique le thème et les couleurs Nord au maximum de composants de la stack de `desktop-pc`, par exemple Noctalia, VS Code, WezTerm et Neovim."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unified Nord Graphical Session, Compositor, and Boot/Login Experience (Priority: P1)

As a `desktop-pc` user, I want the graphical desktop environment—from the bootloader and login screen to the Wayland window manager (Niri) and desktop shell (Noctalia)—to use the Arctic, bluish Nord color palette consistently, so that my entire workspace presents a cohesive, low-contrast dark visual identity without leftover Catppuccin or default themes.

**Why this priority**: The compositor, desktop shell panels/launcher/lockscreen, and login greeter frame every interaction on `desktop-pc`. Unifying them under the Nord palette establishes the foundational visual identity of the workstation.

**Independent Test**: Boot or switch the `desktop-pc` configuration, observe the login prompt, start the graphical session, open the application launcher, control center, and lockscreen, and focus/unfocus multiple tiled windows to verify that all surfaces, borders, focus rings, and accents render in official Nord colors (Polar Night backgrounds, Snow Storm text, Frost accents, and Aurora status colors).

**Acceptance Scenarios**:

1. **Given** an active graphical session on `desktop-pc`, **When** the desktop shell (bar, launcher, control center, notifications, and lockscreen) renders, **Then** it uses the Nord dark palette instead of Catppuccin Macchiato.
2. **Given** multiple tiled windows open in the window manager, **When** focus shifts between active and inactive windows or a window triggers an urgent state, **Then** the active focus ring/border displays in Nord Frost (`#88C0D0`), the inactive focus ring/border displays in Nord Polar Night (`#4C566A`), and urgent indicators display in Nord Aurora Red (`#BF616A`).
3. **Given** the system boot and login sequence, **When** the bootloader and console login greeter are displayed, **Then** Catppuccin-branded wallpapers are removed in favor of dark/cool-toned wallpapers and the login interface renders with Nord-aligned colors.

---

### User Story 2 - Consistent Nord Theme Across Terminal Emulators and Code Editors (Priority: P1)

As a developer working on `desktop-pc`, I want all terminal emulators (WezTerm, Ghostty) and code editors (VS Code, Neovim, Zed) configured in the stack to use the Nord color scheme by default, so that switching between terminals and editors never causes jarring color shifts or mismatched syntax highlighting.

**Why this priority**: Terminals and editors are the primary daily tools on `desktop-pc` and were explicitly highlighted in the request (VS Code, WezTerm, Neovim).

**Independent Test**: Launch WezTerm, Ghostty, VS Code, Neovim, and Zed on `desktop-pc` and open source files in each; verify that every application loads the Nord color scheme immediately upon launch without manual theme selection or leftover Catppuccin/TokyoNight/One Dark defaults.

**Acceptance Scenarios**:

1. **Given** WezTerm or Ghostty is launched on `desktop-pc`, **When** a terminal window opens, **Then** the terminal background (`#2E3440`), foreground (`#D8DEE9`), cursor, and 16 ANSI colors match the Nord palette.
2. **Given** Neovim is launched via `nvim`, `vi`, or `vim`, **When** the editor initializes its LazyVim interface and opens a code file, **Then** the `nord` colorscheme is active across the editor buffer, statusline, file explorer, and floating popups instead of `tokyonight`.
3. **Given** VS Code or Zed is launched on `desktop-pc`, **When** the editor window opens, **Then** VS Code retains its configured `Nord` color theme and Zed automatically loads the `Nord` extension and applies the `Nord` dark theme instead of `One Dark`.

---

### User Story 3 - Cohesive Nord Styling for Shell Prompt and CLI/TUI Utilities (Priority: P2)

As a power user spending significant time in the command line on `desktop-pc`, I want my interactive shell (Fish), prompt (Starship), and CLI/TUI utilities (OpenCode, Bat, Fzf, Yazi, Btop, Lazygit) to use the Nord palette, so that command-line workflows blend seamlessly with the terminal background and desktop theme.

**Why this priority**: Completes the visual unification inside terminal sessions by replacing hardcoded Catppuccin Macchiato palettes (such as in Starship and OpenCode) and default ANSI themes across TUI tools with Nord colors.

**Independent Test**: Open a terminal session on `desktop-pc`, inspect the Starship prompt and Fish command line, and run `opencode`, `bat`, `fzf`, `yazi`, `btop`, and `lazygit` to verify that each tool renders with the Nord color palette.

**Acceptance Scenarios**:

1. **Given** an interactive Fish shell session on `desktop-pc`, **When** the Starship prompt renders, **Then** all powerline segments (OS, user, directory, Git branch/status, language runtimes, environment, and time) and prompt characters use the custom `nord` palette rather than `catppuccin_macchiato`.
2. **Given** the user launches OpenCode TUI, Bat, Fzf, Yazi, Btop, or Lazygit, **When** each tool's interface or output is displayed, **Then** it uses the Nord theme or official Nord hex color mappings (`#2E3440`–`#B48EAD`) with zero references to Catppuccin.
3. **Given** the user types commands and triggers completions in Fish, **When** syntax tokens and completion pagers are highlighted, **Then** the colors match the Nord palette.

---

### User Story 4 - Declarative Reproducibility and Living Documentation Parity (Priority: P2)

As a maintainer of the NixOS repository, I want all Nord theme settings to be declared reproducibly in the repository's feature modules and reflected in `README.md`, so that the theme state survives reboots and rebuilds with zero manual post-install tweaks and the documentation stays accurate.

**Why this priority**: Ensures compliance with the project's core principles of declarative configuration, modular organization, and living documentation.

**Independent Test**: Run the repository's formatting, linting, and flake verification checks and inspect `README.md` to confirm that all references to visual theming reflect the unified Nord theme across the stack.

**Acceptance Scenarios**:

1. **Given** the repository checkout on the feature branch, **When** automated quality checks are executed, **Then** both `desktop-pc` and `homelab` configurations evaluate cleanly with zero errors, warnings, or dead code.
2. **Given** `README.md`, **When** inspected after the changes, **Then** component descriptions and architecture summaries accurately describe the Nord theme across the `desktop-pc` stack (and shared Neovim configuration) instead of Catppuccin or TokyoNight.

---

### Edge Cases

- **Noctalia Dynamic Template Override vs. Static Dotfiles**: Noctalia's configuration previously listed `builtin_ids = [ "niri", "wezterm" ]` under `[theme.templates]`, which can dynamically overwrite or conflict with declarative Niri and WezTerm configurations if a mismatched palette is selected. Noctalia's theme configuration must use the Nord palette and avoid conflicting with read-only declarative store symlinks.
- **Shared Neovim Configuration Across `desktop-pc` and `homelab`**: Because Neovim (`core.neovim`) and Git/Lazygit (`core.git`) are shared between `desktop-pc` and `homelab`, applying the Nord colorscheme to Neovim and Lazygit must work cleanly in headless SSH sessions on `homelab` without introducing any GUI or Home Manager dependencies on `homelab`.
- **Read-Only Neovim Configuration Directory**: Adding a Nord colorscheme plugin spec under the declarative Neovim dotfiles directory (`lua/plugins/`) must work seamlessly with Lazy.nvim's writable data directory (`~/.local/share/nvim`) and lockfile (`~/.local/share/nvim/lazy-lock.json`).
- **Contrast and Legibility on Powerline Segments**: When transitioning Starship prompt segments from pastel Catppuccin colors to Nord Aurora and Frost colors, foreground text on bright/medium segments must use dark Polar Night (`#2E3440`) to maintain high contrast and readability.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The desktop shell configuration (Noctalia) MUST be configured in dark mode using the Nord palette, replacing the `Catppuccin Macchiato Blue` palette.
- **FR-002**: The Wayland compositor configuration (Niri) MUST use Nord colors for window decorations, setting the active focus ring/border to Nord Frost (`#88C0D0`), the inactive focus ring/border to Nord Polar Night (`#4C566A`), and the urgent border to Nord Aurora Red (`#BF616A`).
- **FR-003**: The display manager greeter (Tuigreet) MUST be configured with a Nord-aligned terminal color theme for borders, text, prompts, and action indicators, and the bootloader (Limine) wallpaper list MUST exclude Catppuccin-branded wallpapers in favor of dark/cool-toned wallpapers harmonious with Nord.
- **FR-004**: Both terminal emulators in the `desktop-pc` stack (WezTerm and Ghostty) MUST be declaratively configured to use the `nord` color scheme by default.
- **FR-005**: All code editors in the `desktop-pc` stack MUST be declaratively configured to use the Nord theme:
  - VS Code MUST keep `arcticicestudio.nord-visual-studio-code` installed and `"workbench.colorTheme" = "Nord"` active.
  - Neovim (LazyVim) MUST include a declarative Nord colorscheme plugin specification and configure LazyVim to load `nord` as its default colorscheme.
  - Zed Editor MUST include the `nord` theme extension and set its dark/default theme to `Nord`.
- **FR-006**: The Starship shell prompt configuration MUST define and use a `nord` color palette built from the official Nord hex codes (`#2E3440` through `#B48EAD`), replacing `catppuccin_macchiato` across all prompt segments and character indicators.
- **FR-007**: Interactive CLI and TUI applications in the `desktop-pc` stack MUST be declaratively themed with Nord:
  - OpenCode TUI MUST set its theme to `nord` (replacing `catppuccin-macchiato`).
  - Bat MUST set its syntax highlighting theme to `Nord`.
  - Fzf MUST set its default color scheme options (`colors`) to official Nord hex values.
  - Yazi MUST configure its UI/theme colors to match the Nord palette.
  - Btop (aliased as `b` in the interactive shell) MUST be declaratively enabled and configured with `color_theme = "nord"`.
  - Lazygit MUST configure its UI theme colors (`gui.theme`) to use the Nord palette.
  - Fish shell MUST configure interactive syntax highlighting and completion pager colors aligned with the Nord palette.
- **FR-008**: Applying Nord themes to shared core modules (`core.neovim` and `core.git`) MUST NOT introduce graphical packages or Home Manager requirements onto the headless `homelab` host.
- **FR-009**: Project documentation (`README.md`) MUST be updated within the same branch to reflect the unified Nord theme across the `desktop-pc` stack and shared editor tools.

### Key Entities

- **Nord Color Palette**: The 16-color Arctic palette comprising four named groups: Polar Night (`#2E3440`, `#3B4252`, `#434C5E`, `#4C566A`), Snow Storm (`#D8DEE9`, `#E5E9F0`, `#ECEFF4`), Frost (`#8FBCBB`, `#88C0D0`, `#81A1C1`, `#5E81AC`), and Aurora (`#BF616A`, `#D08770`, `#EBCB8B`, `#A3BE8C`, `#B48EAD`).
- **Desktop Stack Component**: Any graphical shell, compositor, display greeter, terminal emulator, code editor, shell prompt, or TUI utility declared in the `desktop-pc` configuration.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of themed components in the `desktop-pc` stack (Noctalia, Niri, Tuigreet, Limine, WezTerm, Ghostty, VS Code, Neovim, Zed, Starship, Fish, OpenCode, Bat, Fzf, Yazi, Btop, and Lazygit) are declaratively configured to use the Nord color scheme or official Nord hex colors.
- **SC-002**: 0 active references to `catppuccin`, `tokyonight`, or `One Dark` remain in the active theme configurations of `desktop-pc` modules and dotfiles.
- **SC-003**: 100% of themed applications launch directly into the Nord visual theme on first start after system activation without requiring manual in-app theme selection by the user.
- **SC-004**: Both `desktop-pc` and `homelab` configurations build and pass all automated repository quality checks (`just fmt`, `just lint`, `just check`) with a 100% pass rate and `README.md` updated in parity.

## Assumptions

- The dark variant of the Nord theme (using Polar Night `#2E3440` as the primary background and Snow Storm `#D8DEE9`/`#ECEFF4` as primary foreground text) is the target aesthetic across all components, matching the existing `mode = "dark"` setting in Noctalia and dark themes previously used across the stack.
- Components in the `desktop-pc` stack that do not have a visual user interface or color theme concept (such as `direnv`, `fd`, `ripgrep`, `jq`, `pyenv`, `wl-clipboard`, partitioning CLI tools, and background system services like PipeWire, Bluetooth, Printing, or Tailscale) are naturally out of scope for visual theming.
- Google Chrome and Obsidian are installed as desktop applications via `desktop.apps`, but because their visual themes are managed inside mutable user profile/vault state rather than declarative Home Manager options in this setup, declarative theming focuses on the components managed via NixOS/Home Manager options and declarative dotfiles.
