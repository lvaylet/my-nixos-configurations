# Feature Specification: Secure Portainer and Home Assistant Network Exposure and Container Privileges

**Feature Branch**: `025-secure-portainer-homeassistant`

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "Travaille sur https://github.com/lvaylet/my-nixos-configurations/issues/32 pour sécuriser Portainer et Home Assistant. Avance de manière autonome sur les étapes "speckit.plan", "speckit.tasks" puis "speckit.implement" si aucune intervention de ma part n'est nécessaire, par exemple pour clarifier ou analyser tes propositions. Après la phase d'implémentation, crée une Pull Request dédiée. Je la reverrai manuellement."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Restrict Portainer to Localhost Reverse Proxy Without Privileged Mode (Priority: P1)

As a homelab administrator managing containers via Portainer, I want Portainer's web interface port (`9443`) to bind strictly to the local loopback interface (`127.0.0.1`), its unused Edge Agent port (`8000`) and direct HTTPS port (`9443`) to be closed on the host firewall, and the container to run without `--privileged` mode using only the mounted Podman socket, so that Portainer cannot be accessed directly from the local network and adheres to least-privilege container isolation.

**Why this priority**: Directly mitigates the highest-severity risks identified in Issue #32: exposing the container management plane on all network interfaces (`0.0.0.0:8000` and `0.0.0.0:9443`) and running the Portainer container with full host root capabilities (`--privileged`) when socket access alone is sufficient on NixOS.

**Independent Test**: Verify that Portainer is reachable via the Caddy HTTPS reverse proxy (`https://portainer.homelab.vaylet.fr`), listens only on `127.0.0.1:9443`, has neither port `8000` nor `9443` opened in the host firewall, and manages containers via the Podman socket without `--privileged` in its container options.

**Acceptance Scenarios**:

1. **Given** Portainer is running on `homelab`, **When** an authorized tailnet client connects to `https://portainer.homelab.vaylet.fr`, **Then** Caddy proxies the request to `https://127.0.0.1:9443` and serves the Portainer UI over HTTPS with a valid certificate.
2. **Given** Portainer is running on `homelab`, **When** inspecting the container's published ports and the host firewall rules, **Then** only `127.0.0.1:9443:9443` is bound, port `8000` is not published, and neither `8000` nor `9443` is present in `networking.firewall.allowedTCPPorts`.
3. **Given** the Portainer container configuration on `homelab`, **When** inspecting its runtime options, **Then** `--privileged` is absent and Portainer communicates with the container engine solely through the mounted `/var/run/podman/podman.sock:/var/run/docker.sock` socket and `/var/lib/portainer:/data` volume.

---

### User Story 2 - Restrict Home Assistant to Encrypted Reverse Proxy Access (Priority: P1)

As a homelab administrator running Home Assistant, I want redundant firewall port declarations (`443`) and direct unencrypted LAN HTTP exposure (`8123`) removed from the Home Assistant service firewall rules, so that all user and client interactions with Home Assistant are encrypted over HTTPS via the central Caddy reverse proxy (`https://ha.homelab.vaylet.fr`) while preserving local device discovery over `--network=host`.

**Why this priority**: Directly resolves the second security issue in Issue #32—opening port `8123` in the host firewall exposes Home Assistant authentication and session traffic in cleartext across the local network, while opening port `443` in `home-automation.nix` duplicates the central Caddy firewall declaration.

**Independent Test**: Verify that Home Assistant is accessible via `https://ha.homelab.vaylet.fr` through Caddy (`127.0.0.1:8123`), retains `--network=host` for local mDNS/UPnP discovery, and does not open port `8123` (or duplicate port `443`) in `modules/services/home-automation.nix`.

**Acceptance Scenarios**:

1. **Given** Home Assistant is running on `homelab`, **When** an authorized client connects to `https://ha.homelab.vaylet.fr`, **Then** Caddy forwards the traffic over loopback to `127.0.0.1:8123` and serves Home Assistant over encrypted HTTPS.
2. **Given** the host firewall configuration on `homelab`, **When** inspecting `networking.firewall.allowedTCPPorts`, **Then** port `8123` is not open to external LAN connections, while port `443` remains open once via the centralized Caddy module.
3. **Given** Home Assistant running with `--network=host` and `/run/dbus:/run/dbus:ro`, **When** discovering or communicating with local smart-home devices via mDNS/UPnP/Bluetooth, **Then** local discovery and outbound device communication continue to operate normally.

---

### User Story 3 - Synchronized Service and Setup Documentation (Priority: P2)

As a repository maintainer and operator, I want `README.md` to accurately reflect the hardened network exposure for Portainer and Home Assistant (including initial SSH port-forwarding instructions for Home Assistant reverse proxy trust setup), so that operational tables and bootstrap guides stay synchronized with the declarative NixOS configuration.

**Why this priority**: Complies with Constitution Principle VI (Living Documentation & Dual-Shell Parity), preventing documentation drift regarding exposed ports, LAN direct URLs, and initial Home Assistant setup.

**Independent Test**: Inspect `README.md` service tables and Home Assistant setup instructions to verify that ports `8000`, `9443`, and `8123` are no longer listed as open LAN ports, LAN Direct URLs are marked `N/A (loopback bound)`, and initial Home Assistant UI setup documents SSH local port forwarding in both Bash and Fish.

**Acceptance Scenarios**:

1. **Given** the "Homelab Hosted Services" table in `README.md`, **When** reviewing the Home Assistant and Portainer CE rows, **Then** both list `443` (HTTPS via Caddy) under `Network / Ports` without `8123`, `9443`, or `8000`.
2. **Given** the "Reverse Proxy & Secure HTTPS Access" table in `README.md`, **When** reviewing the Home Assistant and Portainer CE rows, **Then** the `LAN Direct URL` column displays `N/A (loopback bound)` for both services.
3. **Given** the "Home Assistant Reverse Proxy Authorization (UI Configuration)" section in `README.md`, **When** an operator follows the first-time bootstrap steps, **Then** instructions show how to reach `http://127.0.0.1:8123` via an SSH tunnel (`ssh -L 8123:127.0.0.1:8123`) with explicit Bash and Fish blocks.

---

### Edge Cases

- **Portainer Podman Socket Access Without `--privileged`**: On NixOS, SELinux is not enabled by default and rootful Podman runs the Portainer container as root (`0:0`), which natively has read/write access to `/var/run/podman/podman.sock` (`root:podman`, `0660`). Removing `--privileged` drops unnecessary kernel capabilities and host device access without breaking container inspection or management.
- **Home Assistant `--network=host` vs Firewall Filtering**: Because Home Assistant uses `--network=host` for mDNS/UPnP discovery, the process listens on `*:8123` in the host network namespace. Removing `8123` from `networking.firewall.allowedTCPPorts` blocks incoming TCP connections to port `8123` on external interfaces (`eno1`, `tailscale0`) while allowing Caddy on the trusted loopback interface (`lo`, `127.0.0.1:8123`) to proxy requests seamlessly.
- **First-Time Home Assistant Reverse Proxy Setup**: Before Home Assistant is configured in its UI to trust `127.0.0.1` / `::1` as reverse proxies, accessing `https://ha.homelab.vaylet.fr` returns `400 Bad Request`. With port `8123` closed on the LAN firewall, operators can securely forward port `8123` over SSH (`ssh -L 8123:127.0.0.1:8123 laurent@homelab`) to complete the one-time UI setting at `http://127.0.0.1:8123`.
- **Centralized Port 443 Firewall Rule**: `modules/services/caddy.nix` already declares `networking.firewall.allowedTCPPorts = lib.mkIf config.services.caddy.enable [ 443 ];`, and both `portainer.nix` and `home-automation.nix` set `services.caddy.enable = true`. Removing `networking.firewall.allowedTCPPorts` from `portainer.nix` and `home-automation.nix` eliminates redundancy while keeping port `443` open on `homelab`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST bind the Portainer container's HTTPS port strictly to the host loopback interface (`ports = ["127.0.0.1:9443:9443"]`) and MUST NOT publish the unused Edge Agent port `8000` in `modules/services/portainer.nix`.
- **FR-002**: System MUST remove `extraOptions = ["--privileged"]` from `virtualisation.oci-containers.containers.portainer` in `modules/services/portainer.nix` so Portainer runs with standard container isolation and manages Podman solely through `/var/run/podman/podman.sock:/var/run/docker.sock`.
- **FR-003**: System MUST remove ports `8000` and `9443` from `networking.firewall.allowedTCPPorts` in `modules/services/portainer.nix`.
- **FR-004**: System MUST remove the `networking.firewall.allowedTCPPorts` declaration (`443` and `8123`) from `modules/services/home-automation.nix`, relying on `modules/services/caddy.nix` for port `443` and blocking unencrypted external LAN access to port `8123`.
- **FR-005**: System MUST preserve existing reverse proxy virtual hosts (`portainer.${vars.homelabDomain}` -> `https://127.0.0.1:9443` and `ha.${vars.homelabDomain}` -> `127.0.0.1:8123`), persistent storage directories (`/var/lib/portainer` and `/var/lib/home-assistant`), and Home Assistant's `--network=host` and `/run/dbus:/run/dbus:ro` options.
- **FR-006**: Project documentation (`README.md`) MUST be updated within the same branch to reflect the updated port bindings, loopback-only access (`N/A (loopback bound)`), and SSH tunnel instructions (with Bash and Fish variants) for initial Home Assistant reverse proxy authorization.
- **FR-007**: All changes MUST pass formatting (`just fmt`), static linting (`just lint`), and hermetic flake checks (`just check`) with zero errors or warnings.

### Key Entities

- **Portainer OCI Container (`virtualisation.oci-containers.containers.portainer`)**: Containerized management UI in `modules/services/portainer.nix`, bound to `127.0.0.1:9443:9443`, mounting `/var/run/podman/podman.sock:/var/run/docker.sock` and `/var/lib/portainer:/data`, running without `--privileged`.
- **Home Assistant OCI Container (`virtualisation.oci-containers.containers.homeassistant`)**: Containerized home automation server in `modules/services/home-automation.nix`, running with `--network=host` for local discovery while protected from direct LAN HTTP access on port `8123` by the host firewall.
- **Caddy Reverse Proxy Endpoints (`portainer.<homelabDomain>` and `ha.<homelabDomain>`)**: TLS-terminating virtual hosts forwarding authenticated HTTPS requests on port `443` to loopback upstreams `https://127.0.0.1:9443` and `http://127.0.0.1:8123`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 0 non-loopback network interfaces expose Portainer ports `8000` or `9443`; `virtualisation.oci-containers.containers.portainer.ports` evaluates strictly to `["127.0.0.1:9443:9443"]`.
- **SC-002**: 0 privileged container flags (`--privileged`) are present in `virtualisation.oci-containers.containers.portainer.extraOptions` (evaluates to `[]`).
- **SC-003**: Ports `8000`, `9443`, and `8123` are completely absent from `nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts`, while port `443` remains present.
- **SC-004**: 100% of repository quality gates (`just fmt`, `just lint`, and `just check`) pass with exit code 0.
- **SC-005**: `README.md` service tables, reverse proxy tables, and Home Assistant setup instructions accurately document loopback-only access and dual-shell (Bash/Fish) SSH tunnel bootstrap steps.

## Assumptions

- Edge Agent tunnel functionality on TCP port `8000` is unused in this single-host `homelab` deployment where Portainer manages the local Podman engine via UNIX socket.
- Rootful Podman on NixOS runs without SELinux mandatory access control by default, allowing the root process inside the unprivileged Portainer container to access `/var/run/podman/podman.sock` without `--privileged`.
- All day-to-day user access to Home Assistant and Portainer occurs over HTTPS via `https://ha.homelab.vaylet.fr` and `https://portainer.homelab.vaylet.fr` on the private Tailscale network (`modules/services/caddy.nix`).
