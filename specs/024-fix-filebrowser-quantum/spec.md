# Feature Specification: Fix FileBrowser Quantum Config Persistence and Localhost Binding

**Feature Branch**: `024-fix-filebrowser-quantum`

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "Corrige les bugs sur le service FileBrowser Quantum en travaillant sur <https://github.com/lvaylet/my-nixos-configurations/issues/30>"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Persistent User Accounts and Settings Across Container Updates & Reboots (Priority: P1)

As a homelab user managing files through FileBrowser Quantum, I want the application's configuration, database, and user accounts to be stored in the host's preserved configuration directory rather than inside the container's temporary filesystem, so that accounts, permissions, and preferences survive container restarts, image updates, and system reboots.

**Why this priority**: Directly resolves the data-loss bug described in Issue #30—without mounting the preserved host directory into the container, all user accounts, custom settings, and database state exist only in the container's ephemeral root filesystem and are permanently wiped whenever the container is recreated or updated.

**Independent Test**: Start the FileBrowser Quantum service, configure user credentials or preferences in the web interface, recreate or restart the container (or reboot `homelab`), and verify that all accounts and settings remain intact and stored on the host's preserved directory.

**Acceptance Scenarios**:

1. **Given** the FileBrowser Quantum service is running on `homelab`, **When** a user creates or modifies user accounts, passwords, or application settings, **Then** the database and configuration files are written directly to the host's preserved `/var/lib/filebrowser` directory.
2. **Given** user accounts and preferences have been saved in FileBrowser Quantum, **When** the container is stopped, recreated (such as during an image upgrade), or the `homelab` server reboots, **Then** the service starts with all previously configured user accounts and settings intact without resetting to default credentials.
3. **Given** the FileBrowser Quantum service running alongside shared media storage, **When** browsing, uploading, or organizing files in `/data`, **Then** file access and shared group permissions (`multimedia`) continue to function without regression.

---

### User Story 2 - Loopback-Only Binding and Encrypted Reverse Proxy Access (Priority: P1)

As a homelab administrator securing internal services, I want FileBrowser Quantum to listen strictly on the host's local loopback interface and have its direct HTTP port closed on the host firewall, so that all user traffic is enforced through the central HTTPS reverse proxy rather than being exposed over unencrypted HTTP to the local network.

**Why this priority**: Directly addresses the security vulnerability in Issue #30—binding port `8081` to all network interfaces (`0.0.0.0`) and opening port `8081` in the firewall exposes authentication credentials and file transfers in cleartext across the local network, bypassing the HTTPS reverse proxy.

**Independent Test**: Verify that accessing `https://fb.homelab.vaylet.fr` over the private mesh network succeeds via the reverse proxy, while direct connections to port `8081` from another device on the local network are refused or blocked.

**Acceptance Scenarios**:

1. **Given** FileBrowser Quantum is running on `homelab`, **When** an authorized client accesses `https://fb.homelab.vaylet.fr`, **Then** the reverse proxy forwards requests to `127.0.0.1:8081` and serves the web interface over encrypted HTTPS.
2. **Given** FileBrowser Quantum is running on `homelab`, **When** inspecting the host's active network listeners, **Then** port `8081` is bound exclusively to `127.0.0.1` (`127.0.0.1:8081`) and not to `0.0.0.0` or external network interfaces.
3. **Given** the host firewall configuration on `homelab`, **When** an external device on the local network attempts to connect directly to TCP port `8081`, **Then** the connection is rejected because port `8081` is not open in the host firewall.

---

### User Story 3 - Synchronized Service Documentation (Priority: P2)

As a repository maintainer and operator, I want the project documentation (`README.md`) to accurately reflect that FileBrowser Quantum is bound strictly to localhost and accessible exclusively via HTTPS through the reverse proxy, so that service tables and network architecture documentation remain truthful to the deployed configuration.

**Why this priority**: Enforces the project's Living Documentation governance principle (`README.md` parity), ensuring operators do not rely on outdated references to direct LAN HTTP access on port `8081`.

**Independent Test**: Review the Homelab Hosted Services and Reverse Proxy tables in `README.md` and confirm that port `8081` is no longer listed as an exposed LAN HTTP port and the LAN Direct URL is marked as loopback-bound (`N/A (loopback bound)`), matching `n8n`, `Uptime Kuma`, `OpenCode`, and `WAHA`.

**Acceptance Scenarios**:

1. **Given** the "Homelab Hosted Services" table in `README.md`, **When** reviewing the FileBrowser Quantum row, **Then** the network/ports column lists `443` (HTTPS via Caddy) without `8081` (LAN HTTP), and the storage column reflects `/data:/srv` and `/var/lib/filebrowser:/config`.
2. **Given** the "Reverse Proxy & Secure HTTPS Access" table in `README.md`, **When** reviewing the FileBrowser Quantum entry, **Then** the "LAN Direct URL" column states `N/A (loopback bound)` instead of `http://homelab:8081`.

---

### Edge Cases

- **Container Recreated or Image Updated**: When Podman pulls a new `2-stable` container image and recreates the container, `/var/lib/filebrowser` remains mounted from `/persistent/var/lib/filebrowser`, preventing loss of the SQLite database or user accounts.
- **Directory Ownership and Permissions on Ephemeral Root**: `/var/lib/filebrowser` is preserved under `/persistent` with `filebrowser:filebrowser` ownership (matching UID `992` defined in `modules/services/media.nix`), ensuring the container process running with `PUID = "992"` can read and write its database and configuration files without permission errors.
- **Direct LAN Access Attempt to Port 8081**: If a user or script attempts to connect to `http://homelab:8081` from the LAN, the request fails both at the firewall level (port `8081` removed from allowed TCP ports) and at the socket level (bound strictly to `127.0.0.1`).
- **Reverse Proxy Coexistence**: Removing `8081` from `networking.firewall.allowedTCPPorts` must keep port `443` open (consistent with `n8n`, `waha`, and `uptime-kuma` modules) so Caddy HTTPS traffic continues unimpeded.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST mount the host directory `/var/lib/filebrowser` to `/config` inside the FileBrowser Quantum container (`/var/lib/filebrowser:/config`) so that its database and configuration persist outside the ephemeral container rootfs.
- **FR-002**: System MUST retain the preservation declaration for `/var/lib/filebrowser` under `/persistent` so that FileBrowser Quantum state survives ephemeral root reboots on `homelab`.
- **FR-003**: System MUST bind the FileBrowser Quantum container's host port strictly to the local loopback interface (`127.0.0.1:8081:80`) rather than all interfaces (`8081:80`).
- **FR-004**: System MUST NOT expose TCP port `8081` in `networking.firewall.allowedTCPPorts`, ensuring all external access to FileBrowser Quantum occurs exclusively over HTTPS (port `443`) through the Caddy reverse proxy (`fb.<homelabDomain>` -> `127.0.0.1:8081`).
- **FR-005**: System MUST preserve existing FileBrowser Quantum capabilities, including the `/data:/srv` volume mount, `PUID`/`PGID`/`UMASK` environment settings, supplementary `multimedia` group access (`--group-add=995`), and `CAP_NET_BIND_SERVICE` capability.
- **FR-006**: Project documentation (`README.md`) MUST be updated within the same branch to reflect that FileBrowser Quantum is exposed solely via HTTPS (`443` via Caddy), mounts `/var/lib/filebrowser:/config`, and has no direct LAN HTTP URL (`N/A (loopback bound)`), while maintaining dual-shell (Bash/Fish) parity for any shell commands.
- **FR-007**: All configuration and documentation changes MUST pass repository formatting (`just fmt`), static linting (`just lint`), and flake check validation (`just check`) with zero errors or warnings.

### Key Entities

- **FileBrowser Quantum Container (`virtualisation.oci-containers.containers.filebrowser`)**: The containerized web-based file manager running on `homelab`, configured in `modules/services/filebrowser.nix`.
- **FileBrowser Persistent Configuration Directory (`/var/lib/filebrowser` -> `/config`)**: The host directory preserved under `/persistent/var/lib/filebrowser` (owned by `filebrowser:filebrowser`, UID `992`) and bind-mounted into the container at `/config` to store the SQLite database and application settings.
- **Loopback Upstream Endpoint (`127.0.0.1:8081`)**: The local-only socket connecting the Caddy HTTPS reverse proxy (`fb.<homelabDomain>`) to container port `80` without exposing unencrypted HTTP on the LAN.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of FileBrowser Quantum database records, user accounts, and configuration changes persist across container restarts, image recreations, and `homelab` system reboots.
- **SC-002**: 0 non-loopback network interfaces expose TCP port `8081` on `homelab`; port `8081` is bound strictly to `127.0.0.1` and absent from `networking.firewall.allowedTCPPorts`.
- **SC-003**: 100% of authorized HTTPS requests to `https://fb.homelab.vaylet.fr` succeed through the Caddy reverse proxy to `127.0.0.1:8081`.
- **SC-004**: 100% of repository quality gates (formatting, static linting, dead-code analysis, and full flake checks) pass with zero errors or warnings.
- **SC-005**: `README.md` service and reverse proxy tables accurately reflect loopback-only binding (`N/A (loopback bound)`) and persistent `/var/lib/filebrowser:/config` storage for FileBrowser Quantum.

## Assumptions

- FileBrowser Quantum (`ghcr.io/gtsteffaniak/filebrowser:2-stable`) uses `/config` inside the container as its default configuration and database storage directory when `/var/lib/filebrowser:/config` is mounted.
- The `filebrowser` system user (UID `992`) and `filebrowser` / `multimedia` (GID `995`) groups remain defined in `modules/services/media.nix`, which is imported alongside `services.filebrowser` on `homelab`.
- Following the established pattern in `modules/services/n8n.nix`, `modules/services/waha.nix`, and `modules/services/uptime-kuma.nix`, `networking.firewall.allowedTCPPorts` in `modules/services/filebrowser.nix` should expose port `443` (or rely on Caddy's HTTPS port) rather than `8081`.
