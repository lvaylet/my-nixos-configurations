# Data Model: WAHA WhatsApp Automation Service for Homelab

**Branch**: `013-add-waha-service` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

This document formalizes the entities, configuration schemas, storage layout, relationships, and invariants for the WAHA WhatsApp automation service on `homelab`.

---

## 1. Entities & Configuration Schemas

### Entity 1: WAHA Service Feature Module (`modules/services/waha.nix`)

Represents the dendritic capability module encapsulating the OCI container runtime, Caddy reverse proxy virtual host, firewall rules, systemd lifecycle hooks, and declarative state preservation.

| Category | Option / Attribute | Value / Schema | Purpose |
| --- | --- | --- | --- |
| **Dendritic Identification** | `flake.modules.services.waha.nixos` | NixOS Module function `({ config, lib, vars, ... }: { ... })` | Auto-discovered feature module via `import-tree` |
| **OCI Container** | `virtualisation.oci-containers.containers.waha.image` | `"docker.io/devlikeapro/waha:latest"` | Official WAHA self-hosted OCI image |
| | `...volumes` | `[ "/var/lib/waha/sessions:/app/.sessions" "/var/lib/waha/media:/app/.media" ]` | Persistent session and media mounts |
| | `...ports` | `[ "127.0.0.1:3001:3000" ]` | Loopback-only TCP port mapping (host:container) |
| | `...environment.TZ` | `"Europe/Paris"` | Container timezone aligned with host (`FR-009`) |
| | `...environment.WAHA_BASE_URL` | `"https://waha.${vars.homelabDomain}"` | Canonical external base URL for generated links |
| | `...environment.WHATSAPP_RESTART_ALL_SESSIONS` | `"True"` | Auto-reconnect paired sessions on startup (`FR-006`) |
| | `...environmentFiles` | `[ "/var/lib/waha/waha.env" ]` | Persistent host secret file for API key & dashboard auth (`FR-008`) |
| **Systemd Lifecycle** | `systemd.services."podman-waha".after` | `[ "local-fs.target" ]` | Wait for persistent filesystem mounts (`FR-010`) |
| | `systemd.services."podman-waha".preStart` | Ensures `/var/lib/waha/{sessions,media}` and `0600` `/var/lib/waha/waha.env` exist | Prevents first-boot missing volume/env-file failures |
| **Reverse Proxy** | `services.caddy.enable` | `true` | Enables centralized Caddy reverse proxy |
| | `services.caddy.virtualHosts."waha.${vars.homelabDomain}".extraConfig` | `reverse_proxy 127.0.0.1:3001` | Routes `https://waha.homelab.vaylet.fr` to container (`FR-002`) |
| **Firewall** | `networking.firewall.allowedTCPPorts` | `[ 443 ]` | Allows inbound HTTPS traffic to Caddy |
| **Preservation** | `preservation.preserveAt."/persistent".directories` | `[ { directory = "/var/lib/waha"; mode = "0750"; } ]` | Persists sessions, media, and `waha.env` across reboots (`FR-005`) |

#### Relationships

- **Depends on**: `modules/services/podman.nix` for rootful Podman OCI container execution.
- **Depends on**: `modules/services/caddy.nix` for Cloudflare DNS-01 ACME TLS termination on `*.homelab.vaylet.fr`.
- **Depends on**: `modules/core/preservation.nix` for `/persistent` bind-mount persistence across ephemeral root reboots.
- **Depends on**: `modules/core/vars.nix` for `vars.homelabDomain` (`"homelab.vaylet.fr"`).
- **Integrates with**: `modules/services/n8n.nix` via HTTP API calls (`http://127.0.0.1:3001` or `https://waha.homelab.vaylet.fr`) and webhook callbacks.
- **Composed into**: `modules/hosts/homelab.nix` via `config.flake.modules.services.waha`.

---

### Entity 2: Homelab Host Composition (`modules/hosts/homelab.nix`)

Represents the target host configuration assembling hardware and feature modules.

| Attribute | Type | Current State | Target State | Validation Rule |
| --- | --- | --- | --- | --- |
| `features` | List of Modules | Enables `services.caddy`, `services.n8n`, `services.podman`, etc. | Adds `services.waha` in alphabetical order | Must only reference `config.flake.modules.*` |
| `extraModules` | List of Modules | Host-specific boot/SSH/hostname settings | Unchanged | Zero inline service definitions |

---

### Entity 3: Persistent Storage Layout (`/persistent/var/lib/waha`)

Represents the persistent directory structure on the `homelab` host.

```text
/persistent/var/lib/waha/
├── waha.env                   # Host-only environment file (API key, dashboard & Swagger credentials)
├── sessions/                  # Mounted into container at /app/.sessions
│   └── default/               # Default WhatsApp session authentication & token store
└── media/                     # Mounted into container at /app/.media
    └── ...                    # Sent/received WhatsApp attachments for SGDF workflows
```

#### Field Specifications & Permissions

| Path | Type | Mode | Persistence & Security Requirement |
| --- | --- | --- | --- |
| `/var/lib/waha` | Directory | `0750` | Preserved at `/persistent/var/lib/waha` |
| `/var/lib/waha/waha.env` | File | `0600` | Root-readable only on host; injected via `--env-file`, never mounted in container |
| `/var/lib/waha/sessions` | Directory | `0755` | Mounted at `/app/.sessions`; stores WhatsApp session auth state |
| `/var/lib/waha/media` | Directory | `0755` | Mounted at `/app/.media`; stores temporary/persistent WhatsApp media |

#### Supported Secret Environment Variables in `/var/lib/waha/waha.env`

| Variable | Purpose |
| --- | --- |
| `WAHA_API_KEY` | API key required in `X-Api-Key` header for all REST/n8n API requests |
| `WAHA_DASHBOARD_USERNAME` | Username for the WAHA web management dashboard (`/dashboard`) |
| `WAHA_DASHBOARD_PASSWORD` | Password for the WAHA web management dashboard (`/dashboard`) |
| `WHATSAPP_SWAGGER_USERNAME` | Username for the interactive OpenAPI/Swagger documentation (`/`) |
| `WHATSAPP_SWAGGER_PASSWORD` | Password for the interactive OpenAPI/Swagger documentation (`/`) |

---

### Entity 4: WhatsApp Session Lifecycle State

Represents the runtime state machine of a WhatsApp session managed by WAHA:

```text
STOPPED ──(start / auto-restart)──► STARTING ──(unpaired)──► SCAN_QR_CODE ──(QR / code paired)──► WORKING
   ▲                                    │                                                            │
   │                                    └──────────────(persisted credentials valid)─────────────────┘
   └───────────────────────────────────(stop / logout / unrecoverable auth failure)──────────────────┘
```

---

## 2. Invariants & Business Rules

1. **Loopback Binding Invariant**: The WAHA container port MUST bind exclusively to `127.0.0.1:3001:3000`; port `3000` or `3001` MUST NOT be opened in `networking.firewall.allowedTCPPorts`.
2. **State Preservation Invariant**: `/var/lib/waha` MUST be registered in `preservation.preserveAt."/persistent".directories` whenever the `waha` container is defined.
3. **Mount Order Invariant**: `systemd.services."podman-waha"` MUST order `after = [ "local-fs.target" ]` and initialize `/var/lib/waha/{sessions,media}` and `/var/lib/waha/waha.env` in `preStart`.
4. **Zero-Secrets Invariant**: No API keys or passwords may appear in `.nix` files; all sensitive credentials reside in `/var/lib/waha/waha.env` on the host.
5. **Target Isolation Invariant**: Enabling `services.waha` on `homelab` MUST NOT affect `desktop-pc` or `iso` evaluations.
