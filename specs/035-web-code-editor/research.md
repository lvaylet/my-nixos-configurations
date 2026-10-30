# Research & Technical Decisions: Remote Web Code Editor on Homelab

**Feature**: `035-web-code-editor`
**Date**: 2026-10-30
**Status**: Completed

## Executive Summary

The objective is to install a secure, web-accessible code editor on the `homelab` server so that code can be viewed, edited, and verified remotely from a browser when SSH access is not available (e.g. from restricted corporate workstations, tablets, or unauthenticated client environments).

The design decisions below resolve all technical questions regarding editor selection, service architecture, network and reverse proxy topology, authentication delegation, and impermanent filesystem state preservation.

---

## 1. Web Code Editor Engine Selection

### Decision

Deploy **`code-server`** (v4.x by Coder) via the built-in NixOS service module (`services.code-server`).

### Rationale

- **NixOS Native Module**: NixOS provides first-class support via `services.code-server`, eliminating custom systemd unit boilerplate or container runtime overhead.
- **Full VS Code Experience**: Full desktop-grade web IDE featuring an interactive file explorer, syntax highlighting for Nix, Markdown, Lua, Python, Shell, integrated Git diffing, search, and integrated web terminal.
- **Ecosystem & Extensions**: Compatible with the Open VSX registry for extensions (e.g. Nix IDE, Nord theme, GitLens alternatives).
- **Direct Host Execution**: Runs natively as a systemd service under the user `laurent:users`, avoiding container volume mapping friction and enabling direct access to the Nix development environment (`just`, `nh`, `nix`, `git`).
- **Telemetry & Updates**: Built-in options `services.code-server.disableTelemetry = true;` and `services.code-server.disableUpdateCheck = true;` ensure compliance with privacy and immutable NixOS package management.

### Alternatives Considered

- **`openvscode-server` (Gitpod)**: Also packaged in NixOS (`services.openvscode-server`). However, it primarily relies on connection tokens rather than full session persistence flexibility, has a less mature standalone service ecosystem on NixOS, and requires more manual configuration for custom default directory paths.
- **FileBrowser Quantum Built-in Editor**: Already available at `https://fb.homelab.vaylet.fr`. Lacks an integrated terminal, syntax language servers (LSP), Git diff tools, and multi-file project workspace navigation.
- **Containerized Coder / Theia**: Requires container orchestration (Podman), introduces overhead, and creates permission/UID translation complexity when interacting with local Git repositories in `/home/laurent/workspace`.

---

## 2. Authentication & Network Access Model

### Decision

Configure `code-server` with **`auth = "none"`** and delegate 100% of perimeter authentication and access control to the **private Tailscale overlay network** and **Caddy HTTPS reverse proxy**.

### Rationale

- **Zero Double-Authentication Friction**: The user is already authenticated via Tailscale identity and device ACLs to reach the `homelab` private CGNAT IP (`100.127.199.88`). Requiring a second application password inside the browser session is redundant and degrades usability from mobile or locked-down devices.
- **Perimeter Isolation**: DNS for `*.homelab.vaylet.fr` resolves strictly to `100.127.199.88`. No public internet ports (WAN) are forwarded on the router. Non-Tailnet traffic cannot route to or resolve `code.homelab.vaylet.fr`.
- **In-Transit Encryption**: Caddy reverse proxy automatically provisions a trusted wildcard TLS certificate via Cloudflare DNS-01 challenge (`skip_install_trust`), ensuring that all traffic in the browser is encrypted via HTTPS with zero certificate warnings.
- **Local Loopback Binding**: `code-server` binds strictly to `127.0.0.1:4444`, preventing direct unauthenticated socket access from non-localhost network interfaces.

### Alternatives Considered

- **Password Authentication (`auth = "password"`)**: Requires generating and persisting a password file (`/var/lib/...`) or password hash. While more defensive, it introduces friction on every login, especially since the service is already strictly tailnet-isolated.
- **HTTP Basic Auth in Caddy**: Adds an extra browser popup modal before loading the page. Less ergonomic than native Tailscale overlay protection.

---

## 3. Workspace Root & Environment Integration

### Decision

Configure the initial workspace root to **`/home/laurent`** and provide the standard NixOS development toolchain in the service's `extraPackages`.

### Rationale

- **Comprehensive Workspace Access**: Opening `/home/laurent` gives immediate access to:
  - Repository checkouts (`/home/laurent/workspace/github.com/lvaylet/my-nixos-configurations`)
  - User configuration and dotfiles (`/home/laurent/.config`)
  - Transient scripts and downloads
- **Integrated Terminal Tooling**: By configuring `extraPackages = with pkgs; [ bash coreutils direnv git just nh nix nixos-rebuild ripgrep ];`, the integrated terminal in `code-server` can immediately execute repository workflows (`just check`, `just test homelab`, `just fmt`, `git status`) without relying on global path leakage.
- **Least Privilege User Context**: Runs under `User = "laurent"`, `Group = "users"` matching the user's UID/GID, avoiding permission conflicts when creating or editing files in user workspaces.

### Alternatives Considered

- **Scoped to `my-nixos-configurations` only**: Restricts the editor to a single repository. If the user wants to inspect other projects, notes, or home configs, they would have to manually open other folders.
- **System Root (`/`)**: Runs the risk of cluttering system directories and requires root privileges, violating least privilege principles.

---

## 4. State Preservation Across Impermanent Reboots

### Decision

Preserve `code-server` user data and configuration directories under `/persistent/home/laurent` using `preservation.preserveAt."/persistent".users.${vars.userName}.directories`:

- `.local/share/code-server` (extensions, user data, workspace storage, backlogged sessions)
- `.config/code-server` (user settings, keybindings)

### Rationale

- **Constitution Compliance (Principle I & II)**: `homelab` runs with an ephemeral root filesystem on `tmpfs`. Unpreserved files in `/home/laurent` or `/var` are wiped on reboot.
- **Seamless Reboots**: Preserving `.local/share/code-server` and `.config/code-server` ensures that installed extensions, themes, editor state, and opened tabs persist across system updates and generation reboots (`just switch homelab`).
- **Standard Preservation Hierarchy**: Integrates into the existing declarative `preservation` submodule without modifying disko or disk partitioning.

### Alternatives Considered

- **Stateless Operation**: Let `code-server` reset on every boot. Rejected because users would have to reinstall extensions and reconfigure preferences after each reboot.

---

## 5. Dendritic Architecture & Host Composition

### Decision

Create a dedicated feature module `modules/services/code-server.nix` and enable it in `modules/hosts/homelab.nix` by adding `services.code-server` to the `features` list.

### Rationale

- Follows the dendritic pattern: zero inline service configuration in host files.
- Automatically discovered via `import-tree ./modules`.
- Colocates NixOS service configuration, Caddy reverse proxy integration, and preservation rules in a single, cohesive file.
