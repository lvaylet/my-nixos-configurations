# Feature Specification: Desktop Environment Migration to Niri and Noctalia (NNN Stack)

**Feature Branch**: `feat-migrate-to-niri-and-noctalia`

**Created**: 2026-10-08

**Status**: Draft

**Input**: User description: "Remplace l environnement de bureau COSMIC par une combinaison de Niri et Noctalia (la fameuse stack NNN pour NixOS), avec WezTerm comme terminal, Fish comme shell et FiraCode Nerd Font (avec ligatures) comme police, dans le terminal et dans Neovim."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Interactive Wayland Desktop Session with Niri & Noctalia (Priority: P1)

As a workstation user, I want to authenticate at the system display manager and enter a fluid, scrollable-tiling Wayland desktop environment powered by Niri and Noctalia, so that I have an intuitive, high-performance, and distraction-free workspace with integrated status indicators, window navigation, and an application launcher.

**Why this priority**: Foundational core capability. Replacing the COSMIC desktop environment with the Niri compositor and Noctalia desktop shell is the primary objective of this migration; without a functional graphical session, downstream terminal and editor workflows cannot be utilized visually.

**Independent Test**: Can be fully tested by booting or logging into the workstation, selecting the graphical session, and confirming that the Niri scrollable-tiling window manager starts alongside Noctalia's desktop shell (panel, status bar, and launcher) without graphical glitches or crashes.

**Acceptance Scenarios**:

1. **Given** a powered-on workstation at the graphical login screen, **When** the user logs in, **Then** a smooth Wayland desktop session starts running Niri with Noctalia's bar and shell elements displayed.
2. **Given** an active desktop session, **When** the user opens multiple application windows, **Then** windows are automatically organized in Niri's infinite scrollable-tiling layout and can be navigated horizontally using standard directional shortcuts.
3. **Given** an active desktop session, **When** the user activates the application launcher keybinding, **Then** Noctalia presents an interactive application search interface allowing rapid fuzzy searching and launching of installed applications.
4. **Given** an active desktop session, **When** system events occur (audio volume change, battery status, workspace switching), **Then** Noctalia's status bar updates visual indicators accurately in real time.

---

### User Story 2 - Modern Terminal Workflow with WezTerm & Fish Shell (Priority: P1)

As a software developer, I want to launch WezTerm as my default terminal emulator and interact through the Fish shell, so that I benefit from rapid terminal rendering, intelligent autosuggestions, syntax highlighting, and an ergonomic CLI experience out of the box.

**Why this priority**: Essential daily productivity interface. The terminal emulator and interactive shell form the developer's primary interactive control surface for development, system administration, and command execution.

**Independent Test**: Can be fully tested by pressing the terminal launcher shortcut in the desktop session, verifying that WezTerm opens immediately, and confirming that an interactive Fish shell prompt is presented with command highlighting and autosuggestions active.

**Acceptance Scenarios**:

1. **Given** an active desktop session, **When** the user invokes the terminal hotkey or launches the terminal from the application menu, **Then** WezTerm launches promptly as the primary terminal emulator.
2. **Given** an opened WezTerm window, **When** the interactive prompt appears, **Then** the shell environment is Fish, displaying command prompts and history navigation.
3. **Given** typing commands at the Fish prompt, **When** valid or invalid commands are typed, **Then** syntax highlighting visually distinguishes valid commands from invalid ones, and inline autosuggestions suggest matching history entries.
4. **Given** background or automated scripts requiring POSIX compatibility, **When** scripts are executed via system invocations, **Then** standard POSIX/bash execution remains unaffected by the interactive user shell choice.

---

### User Story 3 - Cohesive Typography with FiraCode Nerd Font & Ligatures (Priority: P2)

As a developer and code reader, I want FiraCode Nerd Font with active typographical ligatures configured consistently across both WezTerm and the Neovim editor, so that programming symbols, mathematical arrows, and comparison operators render legibly and aesthetically across all text editing and command-line tasks.

**Why this priority**: Enhances visual ergonomics, reduces cognitive strain when scanning code, and ensures a unified aesthetic identity across terminal and editor environments.

**Independent Test**: Can be fully tested by opening WezTerm and Neovim, viewing code samples containing ligature-eligible character sequences (such as `!=`, `==`, `->`, `=>`, `::`, `<=>`), and verifying that ligatures render correctly and icons from Nerd Fonts display without missing glyph symbols.

**Acceptance Scenarios**:

1. **Given** a running WezTerm session, **When** characters such as `!=`, `==`, `->`, `=>`, or `<==>` are displayed on screen, **Then** they render as unified typographical ligatures using FiraCode Nerd Font.
2. **Given** an open file in Neovim within the terminal or graphical window, **When** editing code files containing comparison and lambda symbols, **Then** FiraCode Nerd Font ligatures render crisply without alignment distortions.
3. **Given** command-line tools displaying custom glyphs or statusline symbols (such as Git branch icons or filetype symbols), **When** displayed in WezTerm or Neovim's status bar, **Then** Nerd Font symbols render cleanly without fallback replacement boxes.

---

### User Story 4 - Clean Retirement of COSMIC Desktop & Service Hygiene (Priority: P2)

As a system maintainer, I want all COSMIC desktop packages, background daemons, and greeter configurations cleanly disabled and replaced, so that no residual background services consume resources, conflict with display management, or interfere with the new Wayland stack.

**Why this priority**: Prevents service contention, eliminates redundant resource consumption, and ensures system stability and cleanliness after migration.

**Independent Test**: Can be fully tested by querying active system services and processes after booting into the new desktop profile and verifying that no COSMIC desktop management services or orphaned greeters are active.

**Acceptance Scenarios**:

1. **Given** a system upgraded from the previous generation, **When** querying running system and user services, **Then** zero COSMIC-specific processes (desktop manager, greeter, or desktop applets) are running.
2. **Given** a need to revert changes due to unforeseen hardware or workflow issues, **When** selecting the prior system generation at boot time, **Then** the previous desktop generation remains bootable and intact through the system generation history.

---

### Edge Cases

- **Multiple Display Monitors**: When multi-monitor setups are connected, Niri and Noctalia must adapt workspaces and panel placement across available displays without crashing the Wayland session.
- **Display Scaling & HiDPI**: On high-DPI displays, FiraCode Nerd Font and desktop UI components must scale legibly without pixelation or clipped font glyphs.
- **Non-Wayland Native Applications**: Legacy applications running under X11 compatibility (XWayland) must display, receive keyboard/mouse input, and respect window management rules within Niri.
- **Non-Interactive Shell Scripts**: Automated scripts or tooling invoking `/bin/sh` or `/usr/bin/env bash` must execute using their respective standard interpreters and not fail due to Fish syntax differences.
- **Terminal Crash or Abrupt Disconnect**: Terminating a WezTerm window must cleanly terminate child Fish shell processes without leaving orphaned background sessions.
- **Neovim Terminal vs. GUI Mode**: Neovim running inside WezTerm must inherit font family and ligature rendering from WezTerm, while any standalone GUI instance must also configure FiraCode Nerd Font and ligature support consistently.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide an interactive Wayland desktop session powered by the Niri scrollable-tiling window manager.
- **FR-002**: The desktop session MUST integrate the Noctalia desktop shell to provide a status bar, system indicators (audio, network, battery), workspace visualization, and an application launcher.
- **FR-003**: The desktop session MUST completely disable and replace the previous COSMIC desktop manager and COSMIC display greeter.
- **FR-004**: The system MUST deploy a Wayland-compatible display manager or greeter capable of launching the Niri session upon user authentication.
- **FR-005**: WezTerm MUST be configured as the primary terminal emulator and made available via desktop keybindings and application menus.
- **FR-006**: Fish MUST be configured as the default interactive user shell for terminal sessions.
- **FR-007**: System-wide non-interactive scripting environments MUST retain POSIX/Bash compatibility for standard script execution.
- **FR-008**: FiraCode Nerd Font MUST be installed and registered in system font configuration.
- **FR-009**: WezTerm MUST be configured to use FiraCode Nerd Font with typographical ligatures explicitly enabled.
- **FR-010**: Neovim configuration MUST ensure FiraCode Nerd Font with typographical ligatures is rendered for code editing and status line glyphs.
- **FR-011**: The system configuration MUST maintain modular separation between system-level desktop services and user-level Home Manager desktop/tool configurations.
- **FR-012**: The system generation history MUST preserve prior generations to allow instant rollback to the previous desktop environment if necessary.

### Key Entities

- **Desktop Session Profile**: Represents the user's graphical environment definition, encapsulating the Wayland compositor (Niri), desktop shell and launcher (Noctalia), and display greeter.
- **Terminal Environment Profile**: Represents the terminal emulator configuration (WezTerm) and interactive command line shell (Fish), including color scheme, keybindings, and default shell arguments.
- **Typography Profile**: Encapsulates font families (FiraCode Nerd Font), font size, fallback fonts, and ligature rendering behaviors shared between terminal emulators and text editors.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Graphical desktop session boots to an interactive, fully responsive desktop state in under 5 seconds from login authentication.
- **SC-002**: 100% of tested standard programming ligatures (e.g., `==`, `!=`, `<=`, `>=`, `->`, `=>`, `<=>`) render as single cohesive glyphs in both WezTerm and Neovim.
- **SC-003**: Interactive Fish shell prompt in WezTerm renders in under 50 milliseconds upon terminal window launch.
- **SC-004**: Zero COSMIC background services, daemons, or greeter processes remain active in running process lists following desktop session activation.
- **SC-005**: 100% of existing POSIX/Bash automation scripts run without syntax failures or environment errors.
- **SC-006**: User can open, scroll through, and switch between at least 10 simultaneous application windows in Niri without stutter or compositor crashes.
- **SC-007**: System configuration passes all static analysis, code formatting, and evaluation gates with zero errors.

## Assumptions

- The target machine for desktop migration is the workstation profile (`desktop-pc`), where interactive graphical environments are deployed.
- Hardware graphics acceleration (Wayland-compatible GPU drivers) is functional and accessible to the Niri compositor.
- Fish shell is configured specifically for interactive user sessions, leaving system scripting environments and `/bin/sh` to standard POSIX-compliant interpreters.
- Display manager/greeter selection will be a lightweight, Wayland-native solution compatible with launching Niri desktop sessions.
- Home Manager modules will govern user-specific settings (WezTerm configuration, Fish shell options, user fonts) while system modules govern compositor and display manager services.
