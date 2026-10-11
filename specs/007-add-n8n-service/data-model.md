# Data Model: n8n Workflow Automation Service for Homelab

**Branch**: `007-add-n8n-service` | **Date**: 2026-10-11 | **Spec**: [spec.md](spec.md)

This document formalizes the entities, data structures, attribute specifications, relationships, and validation constraints for the n8n automation service integration on `homelab`.

---

## 1. Entities & Configuration Schemas

### Entity 1: n8n Service Feature Module (`modules/services/n8n.nix`)
Represents the dendritic capability module encapsulating container runtime parameters, firewall allowances, systemd supervision, and declarative state preservation.

| Category | Option / Attribute | Value / Schema | Purpose |
|---|---|---|---|
| **Dendritic Identification** | `flake.modules.services.n8n.nixos` | NixOS Module function `({ config, lib, ... }: { ... })` | Exported module definition discovered via `import-tree` |
| **OCI Container** | `virtualisation.oci-containers.containers.n8n.image` | `"docker.io/n8nio/n8n:latest"` | Upstream container image |
| | `...volumes` | `[ "/var/lib/n8n:/home/node/.n8n" ]` | Persistent volume mount |
| | `...ports` | `[ "5678:5678" ]` | Exposed TCP port mapping (host:container) |
| | `...user` | `"1000:1000"` | Non-root container user (`node:node`) |
| | `...environment.TZ` | `"Europe/Paris"` | Container process timezone |
| | `...environment.GENERIC_TIMEZONE` | `"Europe/Paris"` | n8n workflow scheduling timezone |
| | `...environment.N8N_PORT` | `"5678"` | Internal application port |
| | `...environment.N8N_DEFAULT_BINARY_DATA_MODE` | `"filesystem"` | High-performance binary data storage |
| | `...environment.N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | `"true"` | Strict configuration permission check |
| **Systemd Lifecycle** | `systemd.services."podman-n8n".after` | `[ "local-fs.target" ]` | Mount ordering dependency |
| **Firewall** | `networking.firewall.allowedTCPPorts` | `[ 5678 ]` | Inbound TCP network access |
| **Preservation** | `preservation.preserveAt."/persistent".directories` | `[ { directory = "/var/lib/n8n"; user = "1000"; group = "1000"; mode = "0750"; } ]` | Declarative impermanence state mapping |

#### Relationships
- **Depends on**: `modules/services/podman.nix` for the Podman container runtime backend and container storage.
- **Depends on**: `modules/core/preservation.nix` for declarative bind-mounting into `/persistent`.
- **Composed into**: `modules/hosts/homelab.nix` via `config.flake.modules.services.n8n`.

---

### Entity 2: Homelab Host Composition (`modules/hosts/homelab.nix`)
Represents the host declaration that assembles hardware and enabled capabilities.

| Attribute | Type | Current State | Target State | Validation Rule |
|---|---|---|---|---|
| `features` | List of Modules | Contains `services.filebrowser`, `services.home-automation`, etc. | Appends `config.flake.modules.services.n8n` | Must only reference modules from `config.flake.modules` |
| `extraModules` | List of Modules | Host-specific overrides (hostname, GRUB, SSH) | Unchanged | Zero inline service definitions |

#### Relationships
- **Composes**: `modules/services/n8n.nix` alongside existing homelab services (`podman`, `filebrowser`, `home-automation`, `portainer`, `jellyfin`, `qbittorrent`).

---

### Entity 3: Persistent Storage Layout (`/persistent/var/lib/n8n`)
Represents the file hierarchy created and maintained by the n8n container across system reboots.

```text
/persistent/var/lib/n8n/
├── config                     # Application configuration settings
├── database.sqlite            # Primary SQLite database (workflows, credentials, execution history)
├── database.sqlite-wal        # Write-Ahead Log for concurrent SQLite transactions (transient)
├── database.sqlite-shm        # Shared memory file for SQLite WAL (transient)
└── binaryData/                # Stored workflow payload artifacts (when binary data mode is filesystem)
```

#### Field Specifications & Permissions

| Path | Type | Owner:Group | Mode | Persistence Requirement |
|---|---|---|---|---|
| `/var/lib/n8n` | Directory | `1000:1000` (`node:node`) | `0750` | Preserved at `/persistent/var/lib/n8n` |
| `/var/lib/n8n/database.sqlite` | File | `1000:1000` | `0600` | Critical state (workflows and credentials) |
| `/var/lib/n8n/config` | File | `1000:1000` | `0600` | Encryption key and instance identifiers |

---

### Entity 4: Workflow Automation Domain Model (Internal Application State)
Represents the application-level data objects managed by the n8n service within `database.sqlite`.

| Entity | Attributes | Description |
|---|---|---|
| **Workflow** | `id`, `name`, `active` (boolean), `nodes` (JSON), `connections` (JSON), `settings` (JSON), `createdAt`, `updatedAt` | Executable graph of automation triggers and actions |
| **Credential** | `id`, `name`, `type`, `data` (AES-256 encrypted string), `createdAt`, `updatedAt` | Encrypted third-party service credentials and API tokens |
| **Execution** | `id`, `workflowId`, `status` (`success`, `error`, `running`, `waiting`), `mode` (`manual`, `trigger`, `webhook`), `startedAt`, `stoppedAt`, `data` | Audit log and diagnostic trace of a workflow run |

---

## 2. Invariants & Business Rules

1. **State Preservation Invariant**: Whenever the n8n container is enabled, `/var/lib/n8n` MUST be registered in `preservation.preserveAt."/persistent".directories` with UID `1000` and GID `1000`.
2. **Mount Order Invariant**: `systemd.services."podman-n8n"` MUST specify `after = [ "local-fs.target" ]` to guarantee `/var/lib/n8n` is bind-mounted from `/persistent` before the container starts.
3. **Firewall Invariant**: Port `5678` MUST be explicitly added to `networking.firewall.allowedTCPPorts` whenever the service is enabled.
4. **Target Isolation Invariant**: The addition of `services.n8n` MUST NOT alter configurations or derivations for `desktop-pc` or `iso`.
