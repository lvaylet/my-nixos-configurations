# Feature Specification: Remote Web Code Editor on Homelab

**Feature Branch**: `035-web-code-editor`

**Created**: 2026-10-30

**Status**: Ready for Planning

**Input**: User description: "Aide-moi à installer un éditeur de code en mode web sur `homelab` pour visualiser et éditer le code à distance quand je ne suis pas capable de me connecter en SSH. Quelles sont les options ?"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Remote Code Viewing and Editing via Web Browser (Priority: P1)

As a developer or administrator unable to establish an SSH connection (e.g., from a locked-down client device, restricted corporate network, or tablet), I want to open a web browser, navigate to a secure URL on `homelab` (`https://code.homelab.vaylet.fr`), and access a full-featured code editor with a file tree, syntax highlighting, and text editing capabilities, so that I can inspect, modify, and save code files remotely without relying on SSH client software.

**Why this priority**: Solves the primary user need: editing and inspecting code on `homelab` directly through a standard web browser when SSH is unavailable.

**Independent Test**: Connect from a Tailscale-authenticated device using a web browser, open `https://code.homelab.vaylet.fr`, browse the repository filesystem, make a change to a file, and verify that the file modification is saved reliably on disk.

**Acceptance Scenarios**:

1. **Given** an authorized client on the Tailscale network, **When** navigating to `https://code.homelab.vaylet.fr`, **Then** the `code-server` web interface loads cleanly with syntax highlighting, file explorer, and editor tabs.
2. **Given** an open file in the web editor, **When** the user modifies content and triggers save, **Then** changes are written to the target file on the host filesystem immediately.
3. **Given** an unauthorized connection attempt from outside the private Tailscale network, **When** requesting the editor URL, **Then** network routing drops or denies the connection, maintaining network-level perimeter isolation.

---

### User Story 2 - Integrated Terminal and Workspace Tools (Priority: P2)

As an operator working within the web code editor, I want access to an integrated web terminal and development tools (Git, Just, Nix CLI) within the context of my project workspace, so that I can run validation commands, test Nix configurations (`just test`, `just check`), and manage Git commits directly from the browser without a separate SSH terminal.

**Why this priority**: Enables complete development workflows (edit, validate, commit, format) from the web interface, avoiding the need for an external terminal emulator.

**Independent Test**: Open an integrated terminal tab inside the web code editor, run `git status` and `just --version`, and confirm commands execute under the `laurent` user environment and path.

**Acceptance Scenarios**:

1. **Given** an active web code editor session, **When** opening the integrated terminal, **Then** an interactive shell session opens in the user's home directory (`/home/laurent`).
2. **Given** an integrated shell session, **When** running repository maintenance commands (such as Git commands or checking flake status), **Then** commands execute with the operator's user environment and path.
3. **Given** the workspace root setting, **When** the editor launches, **Then** the initial explorer tree focuses on the user's home directory (`/home/laurent`), allowing immediate access to dotfiles, configurations, and repository directories.

---

### User Story 3 - Secure Remote Exposure and TLS Integration (Priority: P3)

As a security-conscious homelab administrator, I want the web code editor to be exposed exclusively through the centralized Caddy reverse proxy with valid TLS encryption and restricted to the private Tailscale overlay network, so that editor traffic is encrypted in transit and accessible without secondary password prompts when already authenticated on the Tailnet.

**Why this priority**: Protects sensitive configuration code and execution capabilities with TLS encryption while optimizing user experience through seamless, keyless access within the secure tailnet perimeter.

**Independent Test**: Access `https://code.homelab.vaylet.fr` from an authenticated Tailscale device, verify valid TLS encryption certificate via Cloudflare DNS challenge, verify automatic redirect from HTTP to HTTPS, and confirm that access is granted directly without additional password prompts.

**Acceptance Scenarios**:

1. **Given** a web client connecting over Tailscale, **When** accessing `http://code.homelab.vaylet.fr`, **Then** the reverse proxy automatically redirects the connection to `https://code.homelab.vaylet.fr`.
2. **Given** a connection attempt from a Tailscale-authenticated client, **When** accessing `https://code.homelab.vaylet.fr`, **Then** the editor interface opens immediately without requiring an additional password (`auth = "none"`).
3. **Given** the Caddy reverse proxy configuration on `homelab`, **When** evaluated, **Then** routing rules proxy traffic securely to the local `code-server` loopback port.

---

### User Story 4 - Ephemeral Boot Persistence and Service Continuity (Priority: P4)

As a homelab administrator managing an ephemeral root system with tmpfs and state preservation, I want the web editor's state (extensions, user preferences, session cache) to be preserved across reboots under designated persistent paths, so that personal customizations and session continuity remain intact after every system restart.

**Why this priority**: Guarantees operational reliability and prevents loss of editor settings or installed extensions across system reboots.

**Independent Test**: Configure a custom editor theme or extension, restart the homelab host, reconnect via browser, and verify that custom settings and extensions remain present.

**Acceptance Scenarios**:

1. **Given** custom editor settings or extensions configured in the web editor, **When** the host is rebooted, **Then** the settings and extensions survive the reboot via the `/persistent` storage layer.
2. **Given** system boot completion, **When** all startup targets are reached, **Then** the web editor service starts automatically without manual administrator intervention.
3. **Given** an unexpected service process exit, **When** the process terminates, **Then** the system supervisor restarts the daemon automatically.

---

### Edge Cases

- **Network Interruption During Save**: What happens when network connectivity drops while saving a file? The web editor must notify the user of pending unsaved changes and prevent silent data loss or file truncation.
- **Large File Viewing / Performance Limits**: What happens when viewing large logs or binary files? The editor should warn the user or stream content to avoid browser memory exhaustion.
- **Concurrent Web Sessions**: How does the system handle multiple browser tabs or devices accessing the same workspace simultaneously? The editor engine handles concurrent file reads and writes gracefully using workspace file change notifications.
- **Ephemeral Storage Reset**: Given that `homelab` uses tmpfs impermanence, what happens to editor cache and extensions? Critical data directories (`~/.local/share/code-server`, `~/.config/code-server`) must be preserved under `/persistent` to prevent state wipe on reboot.
- **Privilege Boundaries**: Does the editor execute commands as root or an unprivileged user? The editor must run under the standard user account (`laurent:users`) rather than root to maintain least-privilege security.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a web-based code editor service running on `homelab` powered by `code-server` via the native NixOS service module (`services.code-server`).
- **FR-002**: System MUST allow browsing directories, viewing source files with syntax highlighting, and editing text files through standard desktop and mobile web browsers.
- **FR-003**: System MUST expose an integrated interactive terminal inside the web interface running within the `laurent` user shell environment.
- **FR-004**: System MUST expose the web editor over HTTPS through the centralized Caddy reverse proxy on `https://code.homelab.vaylet.fr`.
- **FR-005**: System MUST redirect all unencrypted HTTP traffic targeting `code.homelab.vaylet.fr` to HTTPS.
- **FR-006**: System MUST delegate authentication and access control to the private Tailscale network overlay (`auth = "none"` in `code-server`), providing keyless access exclusively to authenticated Tailnet devices.
- **FR-007**: System MUST configure the initial workspace root to the primary user's home directory (`/home/laurent`), running under `laurent:users` with access to dotfiles, configurations, and repository workspaces.
- **FR-008**: System MUST preserve editor configuration, user preferences, session state, and extensions across reboots within the `/persistent` hierarchy.
- **FR-009**: System MUST run the web editor daemon as an unprivileged user (`laurent`) with appropriate systemd process management and automatic restarts.
- **FR-010**: System MUST document the service access URL, architecture, and management instructions in `README.md` with explicit Bash and Fish command variants.

### Key Entities *(include if feature involves data)*

- **Editor Workspace**: Represents the root filesystem hierarchy accessible within the web editor, centered at `/home/laurent` containing repository checkouts, dotfiles, and development projects.
- **Editor User State**: Represents user preferences, installed extensions, workspace state, and undo histories persisted across reboots under `/persistent/home/laurent`.
- **Tailnet Overlay Session**: Represents the secure connection established over the private Tailscale network, ensuring access is restricted to authenticated personal devices without secondary application password barriers.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can access the web editor and open a source file in under 5 seconds from a cold browser launch over Tailscale.
- **SC-002**: 100% of file edits made through the web editor are persisted to the server filesystem without file corruption or data loss.
- **SC-003**: 100% of web requests targeting the editor domain use valid HTTPS encryption with zero manual certificate warnings.
- **SC-004**: System recovers and restores web editor availability within 15 seconds after a service or host restart.
- **SC-005**: Terminal commands executed inside the web editor achieve parity with standard interactive shell performance and tools.

## Assumptions

- Access to `homelab` web services is conducted over the private Tailscale network overlay (`homelab.vaylet.fr` resolves to the Tailscale IP `100.127.199.88`).
- The primary user account on `homelab` is `laurent` (`users` group).
- Caddy handles edge TLS certificates via Cloudflare DNS-01 ACME automation.
- Impermanent `/` on tmpfs requires state preservation under `/persistent` for any persistent editor data.
- Subdomain `code.homelab.vaylet.fr` is used to expose `code-server`.
