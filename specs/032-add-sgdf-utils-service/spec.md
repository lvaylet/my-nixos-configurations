# Feature Specification: Add SGDF Contacts API (`sgdf-utils`) Service on Homelab

**Feature Branch**: `032-add-sgdf-utils-service`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "Implémente l'option B pour pouvoir appeler l'API via `https://sgdf.homelab.vaylet.fr/api/v1/parents?active_only=true`."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - HTTPS Access to SGDF Contacts API via Reverse Proxy (Priority: P1)

As an automation workflow in n8n (running inside a Podman container) or an authorized administrator on the private Tailscale network, I want the `sgdf-utils` HTTP REST API to run as a native systemd service on `homelab` (`127.0.0.1:8000`) and be exposed securely through Caddy at `https://sgdf.homelab.vaylet.fr`, so that n8n workflows can query endpoints like `https://sgdf.homelab.vaylet.fr/api/v1/parents?active_only=true` over HTTPS without exposing unencrypted ports on the host network.

**Why this priority**: Containerized n8n workflows cannot reach `127.0.0.1:8000` on the host directly because `127.0.0.1` inside a container refers to the container's own loopback interface. Exposing the native `sgdf-utils` service via Caddy on `https://sgdf.homelab.vaylet.fr` aligns with all other homelab services and enables immediate HTTPS access from n8n.

**Independent Test**: Can be verified by evaluating the `homelab` NixOS configuration to confirm `services.sgdf-utils.enable = true`, `services.caddy.virtualHosts."sgdf.homelab.vaylet.fr"` proxies to `127.0.0.1:8000`, and querying `https://sgdf.homelab.vaylet.fr/api/v1/parents?active_only=true` with the `X-API-Key` header after deployment.

**Acceptance Scenarios**:

1. **Given** `services.sgdf-utils` is enabled on `homelab`, **When** the system configuration is evaluated, **Then** `sgdf-utils` listens strictly on `127.0.0.1:8000` and Caddy configures a virtual host `sgdf.homelab.vaylet.fr` with `reverse_proxy 127.0.0.1:8000`.
2. **Given** an n8n `HTTP Request` node configured with `X-API-Key` authentication, **When** it sends a `GET` request to `https://sgdf.homelab.vaylet.fr/api/v1/parents?active_only=true`, **Then** the `sgdf-utils` API returns a `200 OK` JSON response containing active parent contacts.

---

### User Story 2 - Persistent SQLite Database & Auto-Bootstrapped API Key Across Reboots (Priority: P2)

As a homelab administrator running an ephemeral `tmpfs` root filesystem, I want `/var/lib/sgdf-utils` (containing `sgdf.sqlite3` and `sgdf-utils.env`) to be preserved under `/persistent/var/lib/sgdf-utils` with a static `sgdf-utils:sgdf-utils` user/group and automatic first-boot `SGDF_API_KEY` generation, so that imported parent data and n8n API credentials survive system reboots without manual intervention or `DynamicUser` bind-mount conflicts.

**Why this priority**: On `homelab`'s impermanent root filesystem, unpreserved `/var/lib/*` paths are wiped on reboot, and `DynamicUser = true` conflicts with `nix-community/preservation` bind mounts on `/var/lib/<service>`.

**Independent Test**: Can be tested by evaluating `nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories` to verify `/var/lib/sgdf-utils` is registered with `user = "sgdf-utils"`, `group = "sgdf-utils"`, and `mode = "0750"`, and verifying `systemd.services.sgdf-utils.serviceConfig.DynamicUser` is `false`.

**Acceptance Scenarios**:

1. **Given** `sgdf-utils` starts for the first time on `homelab`, **When** `/var/lib/sgdf-utils/sgdf-utils.env` does not yet exist, **Then** the `preStart` script generates a 64-character random hexadecimal `SGDF_API_KEY` with `0600` permissions owned by `sgdf-utils:sgdf-utils`.
2. **Given** parent contacts have been imported into `/var/lib/sgdf-utils/sgdf.sqlite3`, **When** `homelab` reboots, **Then** both `sgdf.sqlite3` and `sgdf-utils.env` remain intact under `/persistent/var/lib/sgdf-utils`.

---

### Edge Cases

- **Impermanence & `DynamicUser` Compatibility**: The upstream `sgdf-utils` NixOS module sets `DynamicUser = true` by default, which causes systemd to manage `/var/lib/private/sgdf-utils` via symlinks that fail when `/var/lib/sgdf-utils` is already a bind mount from `/persistent`. Overriding `DynamicUser = lib.mkForce false` with a dedicated static `sgdf-utils` user and group avoids this conflict.
- **Mount Ordering at Boot**: `systemd.services.sgdf-utils.after` includes `"local-fs.target"` so the service only starts after `/persistent/var/lib/sgdf-utils` is mounted at `/var/lib/sgdf-utils`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST add `sgdf-utils` (`github:lvaylet/sgdf-utils`, following `nixpkgs`) to `flake.nix` inputs.
- **FR-002**: System MUST define a dendritic service module `modules/services/sgdf-utils.nix` (`flake.modules.services.sgdf-utils`) and enable it on `homelab` (`modules/hosts/homelab.nix`).
- **FR-003**: `modules/services/sgdf-utils.nix` MUST configure `services.sgdf-utils` on `127.0.0.1:8000` with `dataDir = "/var/lib/sgdf-utils"` and `environmentFile = "/var/lib/sgdf-utils/sgdf-utils.env"`, using a static `sgdf-utils:sgdf-utils` system user/group (`DynamicUser = lib.mkForce false`) and auto-generating `SGDF_API_KEY` on first start.
- **FR-004**: `modules/services/sgdf-utils.nix` MUST expose `sgdf-utils` via Caddy on `sgdf.${vars.homelabDomain}` (`https://sgdf.homelab.vaylet.fr` -> `127.0.0.1:8000`) and preserve `/var/lib/sgdf-utils` (`0750`, `sgdf-utils:sgdf-utils`) under `/persistent`.
- **FR-005**: `README.md` MUST be updated in the same branch to document the `sgdf-utils` service, its Caddy endpoint (`https://sgdf.homelab.vaylet.fr`), persistent storage path, and dual Bash/Fish commands for retrieving `SGDF_API_KEY`.

### Key Entities

- **SGDF Contacts API Service (`services.sgdf-utils`)**: Native FastAPI/Uvicorn systemd service listening on `127.0.0.1:8000` and proxied by Caddy at `https://sgdf.homelab.vaylet.fr`.
- **Persistent State Directory (`/var/lib/sgdf-utils`)**: Preserved directory at `/persistent/var/lib/sgdf-utils` (`sgdf-utils:sgdf-utils`, `0750`) holding `sgdf.sqlite3` and `sgdf-utils.env`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nixosConfigurations.homelab` evaluates and builds cleanly with `services.sgdf-utils.enable = true` and `services.caddy.virtualHosts."sgdf.homelab.vaylet.fr"` configured.
- **SC-002**: 100% of repository quality gates (`nix fmt .`, `nix flake check`) pass with exit code `0`.
- **SC-003**: After deployment on `homelab`, `https://sgdf.homelab.vaylet.fr/api/v1/parents?active_only=true` is reachable from n8n with `X-API-Key` authentication.

## Assumptions

- Wildcard DNS `*.homelab.vaylet.fr` already points to `homelab`'s Tailscale IP (`100.127.199.88`), so `sgdf.homelab.vaylet.fr` resolves automatically without additional DNS changes.
