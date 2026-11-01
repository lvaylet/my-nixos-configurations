# Phase 1 Data Model: Replace `sgdf-utils` with `sgdf-tools` API on Homelab

**Branch**: `039-replace-sgdf-tools-api` | **Date**: 2026-11-01 | **Spec**: [spec.md](spec.md)

## Entities & Configuration Schema

### 1. Flake Input (`inputs.sgdf-tools`)

 replaces `inputs.sgdf-utils` in `flake.nix`:

| Attribute | Value | Constraint |
| --- | --- | --- |
| `url` | `"github:lvaylet/sgdf-tools"` | Must track main branch of `lvaylet/sgdf-tools` in `flake.lock` |
| `inputs.nixpkgs.follows` | `"nixpkgs"` | Mandatory per Constitution Principle I |

### 2. SGDF Tools Service (`modules/services/sgdf-tools.nix`)

Exposed as `flake.modules.services.sgdf-tools`:

| Option / Attribute | Value | Description & Invariants |
| --- | --- | --- |
| `imports` | `[ inputs.sgdf-tools.nixosModules.default ]` | Imports upstream `services.sgdf-api` module |
| `services.sgdf-api.enable` | `true` | Enables `systemd.services.sgdf-api` |
| `services.sgdf-api.host` | `"127.0.0.1"` | Loopback-only binding; never exposed directly on LAN/WAN |
| `services.sgdf-api.port` | `8000` | Avoids `3000` (`adguardhome`), `3001` (`waha`), `3002` (`uptime-kuma`), etc. |
| `services.sgdf-api.dataDir` | `"/var/lib/sgdf-tools"` | State directory for `sgdf.db` and `sgdf-tools.env` |
| `environment.systemPackages` | `[ inputs.sgdf-tools.packages.${pkgs.stdenv.hostPlatform.system}.sgdf-cli ]` | Installs `sgdf` and `sgdf-cli` binaries on the host |
| `environment.variables.SGDF_API_URL` | `"http://127.0.0.1:8000"` | Default local endpoint for `sgdf-cli` on `homelab` |
| `users.users.sgdf-tools` | `{ isSystemUser = true; group = "sgdf-tools"; }` | Static user required for `preservation` bind mounts |
| `users.groups.sgdf-tools` | `{}` | Dedicated static group |

### 3. Systemd Unit Overrides (`systemd.services.sgdf-api`)

| Attribute | Value | Purpose |
| --- | --- | --- |
| `after` | `[ "local-fs.target" ]` | Ensures `/persistent/var/lib/sgdf-tools` is mounted before `preStart` and `ExecStart` |
| `serviceConfig.DynamicUser` | `lib.mkForce false` | Prevents `/var/lib/private/sgdf-tools` symlink conflict with `/persistent` bind mount |
| `serviceConfig.User` | `"sgdf-tools"` | Runs as static user `sgdf-tools` |
| `serviceConfig.Group` | `"sgdf-tools"` | Runs as static group `sgdf-tools` |
| `serviceConfig.StateDirectoryMode` | `"0750"` | Restricts `/var/lib/sgdf-tools` access to owner/group |
| `serviceConfig.EnvironmentFile` | `"-/var/lib/sgdf-tools/sgdf-tools.env"` | Leading `-` permits first-boot creation in `preStart` |
| `preStart` | Generates `SGDF_AUTH_TOKEN=<64-hex>` (`0600`) if missing/empty | Bootstraps Bearer authentication token without committing secrets to git |

### 4. Persistent State Directory (`/var/lib/sgdf-tools`)

Registered in `preservation.preserveAt."/persistent".directories`:

| Path | Owner / Group | Mode | Contents |
| --- | --- | --- | --- |
| `/var/lib/sgdf-tools` | `sgdf-tools:sgdf-tools` | `0750` | Preserved directory mapped from `/persistent/var/lib/sgdf-tools` |
| `/var/lib/sgdf-tools/sgdf.db` | `sgdf-tools:sgdf-tools` | `0644` (SQLite default) | Fresh SQLite database managed by `sgdf-api` SQLx migrations |
| `/var/lib/sgdf-tools/sgdf-tools.env` | `sgdf-tools:sgdf-tools` | `0600` | Contains `SGDF_AUTH_TOKEN=<64-hex-chars>` |

### 5. Reverse Proxy Endpoint (`services.caddy.virtualHosts."sgdf.homelab.vaylet.fr"`)

| Attribute | Value | Description |
| --- | --- | --- |
| Virtual Host | `"sgdf.${vars.homelabDomain}"` (`sgdf.homelab.vaylet.fr`) | Preserves exact external URL for scripts and n8n workflows |
| `extraConfig` | `reverse_proxy 127.0.0.1:8000` | Proxies HTTPS traffic on port `443` to local `sgdf-api` listener |

## State Lifecycle & Transitions

1. **First Boot / Deployment**:
   - `preservation` mounts `/persistent/var/lib/sgdf-tools` at `/var/lib/sgdf-tools` (`0750`, `sgdf-tools:sgdf-tools`).
   - `systemd.services.sgdf-api` runs `preStart`, detects `/var/lib/sgdf-tools/sgdf-tools.env` is absent, and writes `SGDF_AUTH_TOKEN=<64-hex>` with mode `0600`.
   - `sgdf-api` starts, loads `SGDF_AUTH_TOKEN`, creates `/var/lib/sgdf-tools/sgdf.db` (`?mode=rwc`), and runs embedded SQLite schema migrations.
2. **Data Ingestion**:
   - Operator imports SGDF intranet export (`ExportIndividus.xls`) via `sgdf import` using the Bearer token from `/var/lib/sgdf-tools/sgdf-tools.env`.
3. **Subsequent Reboots**:
   - Both `sgdf.db` and `sgdf-tools.env` persist under `/persistent/var/lib/sgdf-tools`; `preStart` preserves the existing `sgdf-tools.env` untouched.
4. **Legacy State Cleanup**:
   - Legacy `/persistent/var/lib/sgdf-utils` (and any pre-existing incompatible `sgdf.db`) can be deleted cleanly as its schema is superseded by `sgdf-tools`.
