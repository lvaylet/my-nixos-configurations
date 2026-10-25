# Technical Research: OpenCode v2 on Homelab with Shared Configuration and Web Access

**Feature Branch**: `022-add-opencode-homelab` | **Date**: 2026-10-25

## Research Overview

This document resolves technical choices, architecture designs, and patterns required to implement OpenCode v2 on `homelab` while mutualizing configuration across `desktop-pc`, `macbook-air-m4-15`, and `homelab`, providing both terminal shell and browser-based access via `https://opencode.homelab.vaylet.fr`.

---

## Technical Decisions

### Decision 1: Packaging & Version Source for OpenCode v2

- **Decision**: Introduce `opencode` flake input pinned to `github:anomalyco/opencode/v2.1.4` (or `v2.*` release tag) in `flake.nix` with `inputs.nixpkgs.follows = "nixpkgs"`, consuming `packages.${system}.opencode` for both `x86_64-linux` (`homelab`, `desktop-pc`) and `aarch64-darwin` (`macbook-air-m4-15`).
- **Rationale**:
  - `nixpkgs` (unstable) currently packages OpenCode v1 (`opencode-1.18.35`). OpenCode v2 introduced a major architectural redesign including built-in web server mode (`opencode serve`), headless daemon operations, and enhanced ACP/MCP protocol integrations.
  - Upstream repository `anomalyco/opencode` provides an official Nix flake export (`packages.${system}.opencode` and `packages.${system}.default`) across `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`.
  - Pinning via `flake.lock` satisfies Constitution Principle I (Declarative & Hermetic Configuration) without maintaining fragile custom derivation wrappers or out-of-band npm installations.
- **Alternatives Considered**:
  - *Wait for upstream nixpkgs to package v2*: Rejected because v2 is required immediately for the user's homelab deployment.
  - *Local `buildNpmPackage` / Bun derivation in repository*: Rejected because building the monorepo with Bun and Node native modules requires complex derivation logic that is already maintained and tested upstream in `anomalyco/opencode`.
  - *OCI Container via Podman*: Evaluated, but running OpenCode inside an isolated container prevents direct shell execution on the host (`opencode` CLI in the user's terminal) and adds container runtime overhead for native terminal tooling. Using native Nix package provides both CLI and systemd daemon cleanly.

### Decision 2: Server Daemon & Web Service Architecture on `homelab`

- **Decision**: Run a dedicated systemd service `systemd.services.opencode-web` on `homelab` executing `opencode serve --hostname 127.0.0.1 --port 4096`.
- **Rationale**:
  - `opencode serve` starts the headless v2 server which hosts the bundled web application and REST/WebSocket API.
  - Binding to loopback `127.0.0.1:4096` prevents unencrypted exposure on local network interfaces while avoiding conflicts with existing homelab service ports:
    - `3000`: AdGuard Home
    - `3001`: WAHA
    - `3002`: Uptime Kuma
    - `5679`: n8n
    - `8080`: qBittorrent
    - `8081`: Filebrowser
    - `8096`: Jellyfin
    - `8123`: Home Assistant
    - `9443`: Portainer
  - Port `4096` is the standard default port for OpenCode web server in upstream documentation and Home Manager modules.
- **Alternatives Considered**:
  - *User-level systemd service (`systemd.user.services`)*: Rejected because `homelab` has `enableHomeManager = false;` and user lingering is not default; a system-level systemd service guarantees automatic startup upon host boot and clean integration with systemd supervision.
  - *Running `opencode web` in tmux/screen*: Rejected because imperative process management violates Constitution Principle I (Declarative & Hermetic Configuration) and lacks automatic recovery on failure or reboot.

### Decision 3: Reverse Proxy & TLS Exposure (`https://opencode.homelab.vaylet.fr`)

- **Decision**: Declare a Caddy virtual host `services.caddy.virtualHosts."opencode.${vars.homelabDomain}"` in `modules/services/opencode.nix` reverse-proxying `127.0.0.1:4096`.
- **Rationale**:
  - Homelab already runs a centralized Caddy reverse proxy (`modules/services/caddy.nix`) with Cloudflare DNS-01 ACME automated certificate provisioning (`vars.homelabDomain = "homelab.vaylet.fr"`).
  - Caddy natively handles HTTP/2, HTTP/3, TLS termination, and WebSocket proxying required by OpenCode's real-time streaming event feed.
  - Automatically redirects plaintext HTTP traffic on port 80 to HTTPS on port 443.
- **Alternatives Considered**:
  - *Nginx or Traefik*: Rejected to prevent introducing duplicate reverse proxy stacks; Caddy is the established homelab standard.
  - *Tailscale Funnel / Serve*: Evaluated, but Caddy with Cloudflare DNS-01 matches the architectural standard used by all other homelab services (`uptime.homelab.vaylet.fr`, `n8n.homelab.vaylet.fr`, etc.).

### Decision 4: Web Authentication & Secrets Management

- **Decision**: Secure the web interface using OpenCode's native server authentication via `OPENCODE_SERVER_PASSWORD` supplied through `EnvironmentFile = "-/var/lib/opencode/opencode.env"`.
- **Rationale**:
  - OpenCode v2 natively supports password protection for its web UI and API. When `OPENCODE_SERVER_PASSWORD` is defined, the web interface requires authentication (`username: opencode`, `password: <secret>`) and signs session cookies.
  - Loading from an `EnvironmentFile` stored on disk (mode `0600`, owned by the service user) guarantees zero plaintext secret exposure in the Nix store or Git commits (Constitution Principle IV).
  - A `preStart` script automatically generates a cryptographically secure random password if `opencode.env` does not exist on first boot (mirroring the proven pattern in `modules/services/n8n.nix`), while allowing the administrator to replace or override it at any time.
- **Alternatives Considered**:
  - *Caddy basic_auth in Nix configuration*: Rejected because password hashes or credentials would either need to be in the Nix store or configured separately, whereas OpenCode's native authentication provides session cookies and integrated web UI login prompts.
  - *No authentication*: Rejected as a critical security vulnerability; OpenCode has agentic execution capabilities and must never be exposed without access control.

### Decision 5: Configuration Mutualization Across Target Hosts

- **Decision**: Centralize OpenCode configuration under `modules/services/opencode.nix`, defining:
  1. `nixos`:
     - System package installation (`environment.systemPackages = [ opencodePackage ]`) for shell/CLI access.
     - Systemd service, Caddy vhost, and persistence rules when enabled on `homelab`.
     - Declarative configuration file (`opencode.json`) provisioned via `systemd.tmpfiles.rules` into `/home/${vars.userName}/.config/opencode/opencode.json`.
  2. `homeManager`:
     - Configures `programs.opencode` for Home Manager-managed hosts (`desktop-pc`, `macbook-air-m4-15`), setting `package = opencodePackage`, `tui.theme = "nord"`, and shared settings.
  3. `darwin`:
     - Exposes the package and shared settings for macOS.
  4. Refactor `modules/desktop/apps.nix` to delegate OpenCode configuration to the shared module rather than hardcoding per-machine settings.
- **Rationale**:
  - Directly fulfills Constitution Principle II: "Capabilities MUST be organized into cohesive, domain-grouped features under `modules/` (`core/`, `desktop/`, `services/`), colocating NixOS system services and Home Manager user environments within the same feature scope where applicable."
  - Guarantees that changes to shared settings (e.g. Nord theme, default models, agent rules) propagate consistently across all hosts without duplication.
- **Alternatives Considered**:
  - *Separate modules for server and desktop*: Rejected because separating them leads to configuration drift for shared properties like themes and model configs. Colocation in a dendritic module is the established repository pattern.

### Decision 6: State Preservation & Impermanence

- **Decision**: Configure `preservation.preserveAt."/persistent".directories` for `/var/lib/opencode` (owned by dedicated user `opencode:opencode`, mode `0750`).
- **Rationale**:
  - `homelab` mounts root on an ephemeral `tmpfs` wiping unpreserved state on reboot.
  - Preserving `/var/lib/opencode` retains OpenCode's embedded database (`sqlite`), agent session logs, project cache, and the `opencode.env` credential file across reboots.
  - For user interactive CLI sessions, user directory `/home/${vars.userName}/.local/share/opencode` can be preserved or symlinked to ensure prompt history is durable.
- **Alternatives Considered**:
  - *No persistence*: Rejected because losing sessions and authentication credentials on every reboot violates User Story 4 and Success Criterion SC-004.

---

## Constitution Compliance Matrix

| Constitution Principle | Requirement | Plan Resolution |
| --- | --- | --- |
| **I. Declarative & Hermetic** | Pinned flake inputs, no imperative state changes | `opencode` pinned via flake input; all service and user configs declared in Nix expressions. |
| **II. Dendritic Modularity** | Auto-discovered modules, feature colocation, zero inline host services | `modules/services/opencode.nix` colocates NixOS daemon, Home Manager configuration, and Caddy proxy; `homelab.nix` only references `services.opencode`. |
| **III. Shift-Left Quality** | `alejandra`, `statix`, `deadnix`, `just check` exit code 0 | All code will be formatted with `alejandra`, linted with `statix`/`deadnix`, and verified with `just check`. |
| **IV. Zero-Secrets Leakage** | No plaintext secrets in repo, secure runtime files | Password stored in runtime file `/var/lib/opencode/opencode.env` (mode 0600), never committed to git. |
| **V. Rigorous Verification** | `just check`, non-switching evaluation test | Flake evaluation, syntax checks, and dry-run tests verified prior to deployment. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` updated in same branch, dual Bash/Fish commands | `README.md` updated with OpenCode service entry, port mapping, and dual Bash/Fish command instructions. |
| **VII. Dedicated Branch & PR** | Branch isolation, no commits to `main` | Work conducted on dedicated branch `022-add-opencode-homelab`. |
