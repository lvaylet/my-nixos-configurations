# Feature Specification: Unified FiraCode Nerd Font Typography Across All Code & Terminal Views

**Feature Branch**: `020-firacode-nerd-font`

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "Utilise la police FiraCode Nerd Font à chaque fois que du code est affiché, par exemple dans VS Code (éditeur + terminal), WezTerm, Neovim..."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent Code Editor Typography and Ligatures (Priority: P1)

As a developer working on `desktop-pc`, I want every code editor in the stack (VS Code, Zed, and Neovim) to display source code, diffs, integrated terminals, debug consoles, and statusline icons using `FiraCode Nerd Font` with programming ligatures enabled, so that code is rendered with uniform glyph shapes, operator ligatures (`!=`, `==`, `->`, `=>`, `::`), and crisp Nerd Font symbols across all editing environments.

**Why this priority**: Code editors are the primary places where source code is read and written; any fallback to generic system fonts or missing ligatures breaks visual consistency when switching between VS Code, Zed, and Neovim.

**Independent Test**: Open a source file and an integrated terminal in VS Code, Zed, and Neovim; verify that each editor buffer, integrated terminal, debug/chat code pane, and icon bar renders text in `FiraCode Nerd Font` with active ligatures and zero missing icon glyphs.

**Acceptance Scenarios**:

1. **Given** VS Code is launched on `desktop-pc`, **When** the user opens a source code file, the integrated terminal, the debug console, or chat/inline code blocks, **Then** all code and terminal surfaces render in `FiraCode Nerd Font` with font ligatures enabled.
2. **Given** Zed Editor is launched on `desktop-pc`, **When** the user opens a code buffer or the built-in terminal drawer, **Then** both the editor buffer and the integrated terminal render in `FiraCode Nerd Font` with programming ligatures active instead of Zed's default bundled font.
3. **Given** Neovim is launched in a terminal emulator or a graphical Neovim client, **When** editing source files and viewing the statusline or file tree, **Then** code and Nerd Font icons render in `FiraCode Nerd Font` (via terminal inheritance in TUI mode and explicit `guifont` configuration in GUI mode).

---

### User Story 2 - Unified Terminal Emulator Typography (Priority: P1)

As a developer and command-line user on `desktop-pc`, I want all standalone terminal emulators configured in the stack (WezTerm and Ghostty) to use `FiraCode Nerd Font` with ligatures enabled by default, so that shell sessions, Starship prompts, CLI code viewers (`bat`), Git TUI diffs (`lazygit`), and terminal editors (`nvim`, `opencode`) always display code with identical typography.

**Why this priority**: Terminal emulators host Neovim, Fish, Starship, Bat, Lazygit, Yazi, and OpenCode; ensuring every terminal emulator uses `FiraCode Nerd Font` guarantees consistent code and glyph rendering across all CLI/TUI workflows.

**Independent Test**: Launch both WezTerm and Ghostty on `desktop-pc`, display a file containing programming ligatures (`->`, `=>`, `!==`, `>=`) using `bat` or `nvim`, and verify that both terminals render `FiraCode Nerd Font` ligatures and Starship/Nerd Font icons identically.

**Acceptance Scenarios**:

1. **Given** WezTerm is launched on `desktop-pc`, **When** shell prompts, source code, or TUI applications are displayed, **Then** text is rendered using `FiraCode Nerd Font` with OpenType/HarfBuzz ligatures (`calt`, `clig`, `liga`) enabled.
2. **Given** Ghostty is launched on `desktop-pc`, **When** shell prompts, source code, or TUI applications are displayed, **Then** text is rendered using `FiraCode Nerd Font` with programming ligatures enabled by default.

---

### User Story 3 - System-Wide Default Monospace Fallback & Living Documentation (Priority: P2)

As a workstation user and repository maintainer, I want `FiraCode Nerd Font` registered as the system/user default `monospace` font family in Fontconfig and documented in `README.md`, so that any application displaying code blocks without a dedicated font setting (such as web browsers rendering `<code>`/`<pre>` elements, Markdown previews, or system viewers) automatically resolves `monospace` to `FiraCode Nerd Font`, and repository documentation stays accurate.

**Why this priority**: Setting the Fontconfig `monospace` default closes the gap for applications that delegate code font selection to the desktop environment, while updating `README.md` satisfies the project's Living Documentation constitutional principle.

**Independent Test**: Query `fc-match monospace` on `desktop-pc` to verify it resolves to `FiraCode Nerd Font`, and run repository quality gates (`just fmt`, `just lint`, `just check`) to confirm clean evaluation and `README.md` parity.

**Acceptance Scenarios**:

1. **Given** an active user session on `desktop-pc`, **When** any application or web browser requests the generic `monospace` font family to display code blocks, **Then** Fontconfig resolves `monospace` to `FiraCode Nerd Font`.
2. **Given** the repository on the feature branch, **When** automated checks are run and `README.md` is inspected, **Then** all checks pass with zero errors/warnings and `README.md` documents the unified `FiraCode Nerd Font` typography across the stack.

---

### Edge Cases

- **Terminal Neovim vs. Graphical Neovim Clients**: Terminal Neovim cannot override the font of its parent terminal emulator, so terminal emulators (WezTerm, Ghostty, VS Code terminal, Zed terminal) must supply `FiraCode Nerd Font`, while Neovim's `vim.opt.guifont` must also be set to `"FiraCode Nerd Font:h12"` so standalone GUI clients (e.g., Neovide, goneovim, nvim-qt) render the same font.
- **Shared Neovim Configuration on Headless `homelab`**: Setting `vim.opt.guifont` in the shared `modules/core/dotfiles/nvim/lua/config/options.lua` file is a harmless no-op in headless terminal/SSH sessions on `homelab` and must not pull any graphical font packages onto the `homelab` NixOS closure.
- **Generic `monospace` Resolution Order**: Because `modules/desktop/fonts.nix` installs multiple Nerd Fonts (`fira-code`, `jetbrains-mono`, `meslo-lg`), Fontconfig might otherwise pick another installed monospace font unless `FiraCode Nerd Font` is explicitly prioritized in `fonts.fontconfig.defaultFonts.monospace`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The desktop font module (`modules/desktop/fonts.nix`) MUST install `nerd-fonts.fira-code`, enable Fontconfig discovery, and configure `FiraCode Nerd Font` as the primary default `monospace` font family (`fonts.fontconfig.defaultFonts.monospace`).
- **FR-002**: VS Code (`modules/desktop/editors.nix`) MUST configure `"FiraCode Nerd Font"` across all code and terminal surfaces, including `"editor.fontFamily"` (with `"editor.fontLigatures" = true`), `"terminal.integrated.fontFamily"` (with `"terminal.integrated.fontLigatures.enabled" = true`), `"debug.console.fontFamily"`, `"scm.inputFontFamily"`, and `"chat.editor.fontFamily"`.
- **FR-003**: Zed Editor (`modules/desktop/editors.nix`) MUST declaratively configure `buffer_font_family = "FiraCode Nerd Font"` (with OpenType calt/ligatures enabled) for code editing buffers and `terminal.font_family = "FiraCode Nerd Font"` for its integrated terminal.
- **FR-004**: WezTerm (`modules/desktop/terminal.nix`) MUST configure `FiraCode Nerd Font` (`wezterm.font('FiraCode Nerd Font')`) with HarfBuzz ligature features (`calt=1`, `clig=1`, `liga=1`) enabled.
- **FR-005**: Ghostty (`modules/desktop/apps.nix`) MUST declaratively configure `font-family = "FiraCode Nerd Font"` in its settings so all terminal output and ligatures match WezTerm.
- **FR-006**: The shared Neovim/LazyVim configuration (`modules/core/dotfiles/nvim/lua/config/options.lua`) MUST set `vim.opt.guifont = "FiraCode Nerd Font:h12"` for GUI Neovim clients while remaining free of X11/Wayland package dependencies on `homelab`.
- **FR-007**: `README.md` MUST be updated within the same branch to reflect the unified `FiraCode Nerd Font` configuration across editors, terminals, and default monospace rendering.

### Key Entities

- **Monospace Code Surface**: Any editor buffer, integrated terminal, standalone terminal emulator, debug console, diff viewer, or generic `monospace` text block that displays source code or command-line output.
- **Typography Profile**: The combination of the `FiraCode Nerd Font` family, programming ligature features (`calt`, `clig`, `liga`), and Nerd Font v3 symbol glyphs applied across desktop and editor modules.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of configured code editors (VS Code, Zed, Neovim) and terminal emulators (WezTerm, Ghostty, plus VS Code and Zed integrated terminals) on `desktop-pc` declaratively use `FiraCode Nerd Font`.
- **SC-002**: System monospace font resolution (`fc-match monospace`) on `desktop-pc` resolves directly to `FiraCode Nerd Font` rather than falling back to JetBrains Mono, Meslo LG, or DejaVu Sans Mono.
- **SC-003**: 100% of programming ligature sequences (e.g., `!=`, `==`, `->`, `=>`, `::`) and Nerd Font status/file icons render without missing glyph boxes across VS Code, Zed, WezTerm, Ghostty, and Neovim immediately after system activation.
- **SC-004**: Both `desktop-pc` and `homelab` configurations build and pass all automated repository quality checks (`just fmt`, `just lint`, `just check`) with a 100% pass rate and `README.md` updated in parity.

## Assumptions

- `FiraCode Nerd Font` (the proportional-icon Nerd Font variant with programming ligatures) is preferred as the primary font identifier, with `FiraCode Nerd Font Mono` available as a secondary fallback in Fontconfig's `defaultFonts.monospace` list if an application strictly requires fixed-advance icon cells.
- General UI chrome elements that display natural language labels rather than code (such as Noctalia bar/notification labels or web browser proportional body text) continue using their standard sans-serif UI fonts, while all code, terminal, and monospace contexts use `FiraCode Nerd Font`.
- Existing font sizes (`12` in VS Code and Neovim GUI, `11.5` in WezTerm) are preserved, and sensible matching defaults are used where not previously specified.
