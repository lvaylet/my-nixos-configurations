# Feature Specification: Replace `sgdf-utils` with `sgdf-tools` API on Homelab

**Feature Branch**: `039-replace-sgdf-tools-api`

**Created**: 2026-11-01

**Status**: Draft

**Input**: User description: "Remplace `sgdf-utils` exposé sur <https://sgdf.homelab.vaylet.fr> par l'API de <https://github.com/lvaylet/sgdf-tools>. Expose sur le même endpoint pour ne pas perturber les scripts ou les workflows n8n existants."

## Clarifications

### Session 2026-11-01

- Q: How should existing SQLite database files (`sgdf.db` / legacy `sgdf-utils` state) be handled during the replacement? → A: Delete any existing database (`sgdf.db` and legacy `/persistent/var/lib/sgdf-utils` data); the new `sgdf-tools` database schema is completely different and starts fresh.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Seamless Endpoint Continuity for Scripts and n8n Workflows (Priority: P1)

As an automation operator running n8n workflows and administrative scripts against `https://sgdf.homelab.vaylet.fr`, I want the legacy `sgdf-utils` service to be replaced by the `sgdf-tools` API service (`sgdf-api`) on the exact same HTTPS endpoint (`https://sgdf.homelab.vaylet.fr`), so that existing n8n workflows, CLI scripts, and WAHA/Google Contacts integrations continue communicating through the established domain without reconfiguring endpoint URLs or DNS records.

**Why this priority**: Preserving `https://sgdf.homelab.vaylet.fr` as the canonical HTTPS endpoint is the core requirement to avoid breaking external scripts and containerized n8n automation pipelines while upgrading the underlying backend to `sgdf-tools`.

**Independent Test**: Evaluate the `homelab` system configuration to confirm the legacy `sgdf-utils` service is removed, the new `sgdf-tools` API service is enabled and bound exclusively to localhost, and the reverse proxy routes `https://sgdf.homelab.vaylet.fr` to the local `sgdf-tools` API listener.

**Acceptance Scenarios**:

1. **Given** the updated `homelab` configuration is active, **When** a client or n8n workflow sends an HTTPS request to `https://sgdf.homelab.vaylet.fr/health`, **Then** the reverse proxy forwards the request to the local `sgdf-tools` API service and returns a `200 OK` response.
2. **Given** an authorized n8n workflow or script configured with Bearer token authentication, **When** it queries `https://sgdf.homelab.vaylet.fr` API endpoints (such as Google Contacts export or WhatsApp differential audit routes), **Then** the `sgdf-tools` API processes the request and returns the expected response over HTTPS.
3. **Given** the `homelab` system configuration, **When** inspected for legacy artifacts, **Then** all references to `sgdf-utils` (flake inputs, service definitions, host imports, and reverse proxy bindings) are completely removed and replaced by `sgdf-tools`.

---

### User Story 2 - Persistent Database & Automatic Secret Bootstrapping Across Reboots (Priority: P2)

As a homelab administrator running an ephemeral root filesystem (`tmpfs`), I want the `sgdf-tools` state directory (holding the SQLite database and authentication token environment file) to be preserved on persistent storage (`/persistent`) with a dedicated static system user and automatic first-boot token generation, so that imported SGDF member/parent records and API credentials survive system reboots without manual intervention or mount permission conflicts.

**Why this priority**: `homelab` uses an impermanent root filesystem where unpreserved `/var/lib/*` directories are wiped on every reboot, and systemd's `DynamicUser` mechanism conflicts with persistent bind mounts.

**Independent Test**: Evaluate `homelab` preservation rules and systemd service configuration to verify that the state directory is registered under `/persistent` with a static user/group (`0750`), `DynamicUser` is disabled, and the `preStart` routine generates a secret authentication token on first boot if none exists.

**Acceptance Scenarios**:

1. **Given** the `sgdf-tools` API service starts for the first time on `homelab`, **When** the environment file containing `SGDF_AUTH_TOKEN` does not yet exist in the state directory, **Then** the service automatically generates a strong random token with `0600` file permissions owned by the service user before launching the API server.
2. **Given** SGDF intranet data has been imported into the SQLite database and `SGDF_AUTH_TOKEN` has been initialized, **When** `homelab` reboots, **Then** both the database file and the authentication token file remain intact under `/persistent` and the service starts cleanly after local filesystems are mounted.

---

### User Story 3 - Synchronized Living Documentation & Dual-Shell Operational Commands (Priority: P3)

As a repository maintainer and operator, I want `README.md` to reflect the migration from `sgdf-utils` to `sgdf-tools` across all service tables, reverse proxy mappings, persistent storage paths, and token retrieval/CLI instructions (with both Bash and Fish variants), so that operational documentation stays accurate and copy-paste ready.

**Why this priority**: Required by Constitution Principle VI (Living Documentation & Dual-Shell Parity) whenever a service is added, modified, or removed.

**Independent Test**: Inspect `README.md` to confirm all occurrences of `sgdf-utils` are replaced with `sgdf-tools` (`sgdf-api`), the endpoint `https://sgdf.homelab.vaylet.fr` and state paths are documented accurately, and shell commands include both Bash and Fish blocks where appropriate.

**Acceptance Scenarios**:

1. **Given** `README.md` in the repository root, **When** reviewing the Homelab services table, reverse proxy table, and post-deployment setup guide, **Then** `sgdf-tools` replaces `sgdf-utils` with accurate descriptions of its capabilities (intranet import, Google Contacts export, WhatsApp audit via WAHA/n8n), storage path, and Bearer token retrieval commands.
2. **Given** operational commands in `README.md`, **When** shell syntax is presented, **Then** explicit **Bash** and **Fish** blocks are provided.

---

### Edge Cases

- **Impermanence & `DynamicUser` Bind-Mount Conflict**: The upstream `sgdf-tools` NixOS module sets `DynamicUser = true` by default, which causes systemd to create `/var/lib/private/sgdf-tools` symlinks that fail when `/var/lib/sgdf-tools` is already a bind mount from `/persistent`. Overriding `DynamicUser` to `false` and assigning a dedicated static system user and group prevents startup failures.
- **Mount Ordering on Boot**: The service must wait for `local-fs.target` so that the `/persistent` bind mount for the state directory is active before the pre-start script checks or creates the environment file and before SQLite migrations run.
- **Missing Environment File on First Boot**: Systemd's `EnvironmentFile` directive fails before `ExecStartPre` runs unless prefixed with `-`. Prefixing the path with `-` ensures the first-boot bootstrap script can create the file before the main process starts.
- **Loopback Port Conflict Avoidance**: The local port used by the `sgdf-tools` API service on `127.0.0.1` must not conflict with any other service running on `homelab` (such as WAHA on `3001`, Uptime Kuma on `3002`, OpenCode on `4096`, Code Server on `4444`, n8n on `5679`, qBittorrent on `8080`, Filebrowser on `8081`, Jellyfin on `8096`, Home Assistant on `8123`, or Portainer on `9443`).
- **Incompatible Legacy Database Schema Cleanup**: Because the `sgdf-tools` SQLite schema is completely different from the legacy database, any pre-existing `sgdf.db` or legacy `/persistent/var/lib/sgdf-utils` database file can be deleted rather than migrated so `sgdf-tools` initializes a clean database schema on startup.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository flake configuration MUST replace the `sgdf-utils` input (`github:lvaylet/sgdf-utils`) with `sgdf-tools` (`github:lvaylet/sgdf-tools`), configured to follow the repository's primary `nixpkgs` input.
- **FR-002**: The system MUST provide a declarative service module for `sgdf-tools` under `modules/services/` and enable it on the `homelab` host while removing the obsolete `sgdf-utils` service module and host reference.
- **FR-003**: The `sgdf-tools` API service MUST bind strictly to the local loopback interface (`127.0.0.1`) on a non-conflicting port and MUST NOT expose its internal HTTP port directly on external network interfaces.
- **FR-004**: The reverse proxy on `homelab` MUST route `https://sgdf.homelab.vaylet.fr` (`sgdf.${vars.homelabDomain}`) to the local `sgdf-tools` API listener, preserving the exact external URL used by scripts and n8n workflows.
- **FR-005**: The `sgdf-tools` service MUST run under a dedicated static system user and group (with `DynamicUser` disabled) and store its fresh SQLite database (`sgdf.db`) and secret environment file (`sgdf-tools.env`) in `/var/lib/sgdf-tools`, preserved under `/persistent` with `0750` permissions, without retaining or migrating any legacy database file.
- **FR-006**: On service startup, if `/var/lib/sgdf-tools/sgdf-tools.env` does not exist or is empty, the system MUST automatically generate a random 64-character hexadecimal `SGDF_AUTH_TOKEN` entry with `0600` permissions owned by the service user.
- **FR-007**: The `sgdf-cli` command-line tool (`sgdf`) from `sgdf-tools` MUST be installed in the system environment on `homelab` so administrators and local maintenance scripts can interact with the API directly on the host.
- **FR-008**: `README.md` MUST be updated in the same branch to replace `sgdf-utils` documentation with `sgdf-tools`, documenting the preserved `https://sgdf.homelab.vaylet.fr` endpoint, persistent storage path (`/var/lib/sgdf-tools`), Bearer token authentication (`SGDF_AUTH_TOKEN`), legacy database cleanup, and dual Bash/Fish operational commands.

### Key Entities

- **SGDF Tools API Service (`services.sgdf-api`)**: The native HTTP REST service from `github:lvaylet/sgdf-tools` providing SGDF intranet export ingestion, legal representative deduplication, Google Contacts export, and WhatsApp differential audits, bound to localhost and exposed via `https://sgdf.homelab.vaylet.fr`.
- **Persistent State Directory (`/var/lib/sgdf-tools`)**: Preserved directory mapped to `/persistent/var/lib/sgdf-tools` (`0750`) storing the SQLite database (`sgdf.db`) and the auto-generated Bearer token file (`sgdf-tools.env`).
- **Reverse Proxy Endpoint (`https://sgdf.homelab.vaylet.fr`)**: The stable HTTPS virtual host serving as the single entry point for n8n workflows, remote CLI clients, and automation scripts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `homelab` system configuration evaluates cleanly with the `sgdf-tools` service enabled, `sgdf.homelab.vaylet.fr` proxied to the local `sgdf-tools` API port, and zero remaining references to `sgdf-utils` in active configuration modules.
- **SC-002**: 100% of repository quality gates (formatting, static linting, dead-code checks, and flake evaluation checks) pass with exit code `0`.
- **SC-003**: After deployment on `homelab`, `https://sgdf.homelab.vaylet.fr/health` returns `200 OK` and authenticated API endpoints respond using the persisted `SGDF_AUTH_TOKEN` across system reboots.
- **SC-004**: `README.md` is 100% synchronized with the `sgdf-tools` replacement and provides dual Bash/Fish command blocks where applicable.

## Assumptions

- Wildcard DNS `*.homelab.vaylet.fr` and TLS certificates on `homelab` already cover `sgdf.homelab.vaylet.fr`, requiring no external DNS or certificate provisioning changes.
- Any pre-existing `sgdf.db` or legacy `sgdf-utils` database can be deleted outright because the `sgdf-tools` database schema is completely different and initializes a fresh database on startup, after which canonical SGDF intranet `.xls` exports are imported via `sgdf import`.
- Upstream `github:lvaylet/sgdf-tools` exports `nixosModules.default` (`services.sgdf-api`) and `packages.<system>.sgdf-cli` as documented in its repository.
