# Feature Specification: Persist Tailscale Node Identity and State Across Impermanent Reboots

**Feature Branch**: `023-persist-tailscale-state`

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "Travaille sur <https://github.com/lvaylet/my-nixos-configurations/issues/29> pour persister les paramètres de Tailscale."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Uninterrupted Mesh Network Reconnection Across Ephemeral Reboots (Priority: P1)

As a homelab administrator managing a server with an ephemeral root filesystem (`homelab`), I want the private mesh network node identity, authentication credentials, and daemon settings to be preserved across system reboots, so that the server automatically reconnects to the private mesh network under the same node identity without requiring manual re-authentication or creating duplicate machine entries.

**Why this priority**: Directly resolves Issue #29—without persistent state storage for the mesh network service, every reboot of `homelab` wipes its node key and credentials, severing remote management and internal service access until an operator intervenes physically or over the local network.

**Independent Test**: Authenticate `homelab` to the private mesh network, record its assigned mesh IP address and node identity, reboot the server, and verify that the host automatically comes back online in the mesh network with the exact same node identity, IP address, and SSH settings without manual login.

**Acceptance Scenarios**:

1. **Given** `homelab` is authenticated and connected to the private mesh network with an assigned node identity and mesh IP address, **When** the host undergoes a full system reboot (wiping its ephemeral root filesystem), **Then** the mesh network service retains its stored node keys and credentials and automatically reconnects using the same node identity and IP address.
2. **Given** runtime daemon flags and preferences (such as mesh SSH access) are applied to the mesh network service on `homelab`, **When** the host restarts, **Then** those settings and local daemon state remain intact immediately upon boot.
3. **Given** the persistent state directory for the mesh network service on `homelab`, **When** inspecting its ownership and permissions on disk, **Then** access is restricted exclusively to the system administrator (`root:root` with `0700` permissions) to protect sensitive node private keys.

---

### User Story 2 - Continuous Dependent Service Availability After Reboot (Priority: P1)

As a user accessing self-hosted applications on `homelab` over the private mesh network (such as reverse-proxied web services and mesh SSH), I want services that depend on the mesh network connection and certificate authority to recover automatically after a host reboot, so that remote shell access and HTTPS web applications remain available without manual recovery steps.

**Why this priority**: The reverse proxy and remote administration workflows depend on an authenticated mesh network daemon; preserving the mesh state is essential to maintaining end-to-end service availability after power cycles or system updates.

**Independent Test**: Reboot `homelab` and, from a remote client device on the mesh network without physical LAN access, connect to `homelab` via mesh SSH and open a reverse-proxied HTTPS endpoint in a browser to confirm both succeed automatically after boot.

**Acceptance Scenarios**:

1. **Given** `homelab` has just completed a system reboot, **When** an authorized operator connects from a remote mesh client via mesh SSH, **Then** the connection succeeds without prior LAN intervention or manual re-authentication on the host.
2. **Given** `homelab` has just completed a system reboot, **When** a user accesses an internal HTTPS web service hosted behind the reverse proxy over the mesh network, **Then** the service resolves and loads cleanly over the restored mesh connection.

---

### User Story 3 - Non-Intrusive Multi-Host Coexistence & Living Documentation (Priority: P2)

As a maintainer of a multi-host configuration repository (`homelab` with ephemeral root storage and `desktop-pc` with standard persistent root storage), I want state preservation for the mesh network service to be declared cleanly within the shared service module and documented in the project guide, so that hosts without ephemeral root storage remain unaffected while documentation accurately reflects all persisted paths and verification steps.

**Why this priority**: Upholds the repository's modular architecture and documentation governance, ensuring that shared service definitions work across both ephemeral and non-ephemeral hosts and that operators have accurate reference documentation.

**Independent Test**: Evaluate the system configurations for both `homelab` and `desktop-pc` through the repository's automated check suite, and verify that `README.md` documents the persistent state path for the mesh network service.

**Acceptance Scenarios**:

1. **Given** the shared mesh network service module is enabled on both `homelab` (ephemeral root) and `desktop-pc` (persistent root), **When** system configurations are evaluated and built for both hosts, **Then** `homelab` mounts the persistent `/var/lib/tailscale` directory while `desktop-pc` builds and operates normally without activating ephemeral root preservation.
2. **Given** the updated project documentation (`README.md`), **When** an operator reviews the homelab state preservation and mesh networking sections, **Then** the persistent storage path (`/var/lib/tailscale` under `/persistent/var/lib/tailscale`) is clearly documented alongside dual-shell (Bash and Fish) command variants where applicable.

---

### Edge Cases

- **Unauthorized Local Read Access to Node Keys**: Because `/var/lib/tailscale` stores the node's private key (`tailscaled.state`), preserving the directory with overly permissive permissions could expose node credentials to unprivileged local users or containers; enforcing `root:root` ownership and `0700` permissions prevents unauthorized local access.
- **First Boot Before Initial Mesh Authentication**: When a freshly provisioned `homelab` boots before ever authenticating to the mesh network, the persistent directory `/persistent/var/lib/tailscale` is created empty with `0700` permissions, allowing the daemon to start cleanly and await initial authentication.
- **Service Disabled on a Host**: If the mesh network service is disabled on a target host (`services.tailscale.enable = false`), the state preservation rule must remain inactive so unnecessary directories are not created or bind-mounted.
- **Daemon Startup Ordering Relative to Mounts**: The persistent directory `/var/lib/tailscale` must be mounted and available before the mesh network daemon (`tailscaled`) reads or writes its state file during boot, preventing the daemon from generating a transient state file on the ephemeral root filesystem prior to mounting.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST register `/var/lib/tailscale` for state preservation under `/persistent` whenever the mesh network service is enabled, ensuring node keys, authentication credentials, and daemon state survive reboots on ephemeral-root hosts.
- **FR-002**: System MUST enforce strict directory ownership (`user = "root"`, `group = "root"`) and permissions (`mode = "0700"`) on the preserved `/var/lib/tailscale` directory to protect sensitive node identity keys.
- **FR-003**: System MUST colocate the mesh network state preservation declaration within the mesh network service module (`modules/services/tailscale.nix`) in accordance with the repository's feature-centric modular pattern.
- **FR-004**: System MUST preserve existing mesh network service capabilities—including reverse proxy TLS certificate permissions (`permitCertUid = "caddy"`) and mesh SSH activation (`extraSetFlags = ["--ssh"]` via `tailscaled-set.service`)—without regression.
- **FR-005**: System MUST ensure that declaring preservation paths in the shared mesh network module does not break or alter behavior on hosts where ephemeral root preservation is not enabled (`desktop-pc`).
- **FR-006**: Project documentation (`README.md`) MUST be updated within the same branch to document the persistent storage of `/var/lib/tailscale` under `/persistent` on `homelab`, providing explicit **Bash** and **Fish** command variants whenever shell syntax differs.
- **FR-007**: All configuration and documentation changes MUST pass repository formatting, static analysis, dead-code detection, and full flake evaluation checks with zero errors or warnings.

### Key Entities

- **Mesh Network Node State (`/var/lib/tailscale`)**: The local state directory containing the node's cryptographic private identity key, control-plane authentication state (`tailscaled.state`), and persisted daemon settings.
- **Persistent Storage Volume (`/persistent`)**: The durable Btrfs subvolume on `homelab` that survives ephemeral `tmpfs` root resets across system reboots and bind-mounts registered state directories into the live root filesystem.
- **Shared Mesh Network Module (`modules/services/tailscale.nix`)**: The declarative feature module responsible for configuring the mesh network daemon, certificate sharing, mesh SSH settings, and state persistence across NixOS hosts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Across 100% of system reboots on `homelab`, the host reconnects to the private mesh network automatically using its existing node identity and IP address with 0 manual re-authentication steps and 0 duplicate orphan nodes created in the network console.
- **SC-002**: The preserved `/var/lib/tailscale` directory enforces `0700` permissions owned by `root:root`, allowing 0 unprivileged local users to read the node's private state file.
- **SC-003**: Following a `homelab` reboot, remote mesh SSH access and reverse-proxied web services over the mesh network recover automatically within 30 seconds of system boot completion.
- **SC-004**: 100% of repository quality gates (formatting, static linting, dead-code detection, and configuration evaluations for `homelab` and `desktop-pc`) pass with zero errors or warnings.
- **SC-005**: `README.md` accurately documents the persistence of `/var/lib/tailscale` on `homelab` and maintains 100% dual-shell (Bash/Fish) parity for any shell-specific operational commands.

## Assumptions

- `homelab` uses the existing `core.preservation` module (`modules/core/preservation.nix`) with `/persistent` mounted from durable storage via Disko.
- `homelab` is already enrolled in the private mesh network (or will be authenticated once after deploying this change), after which its state in `/persistent/var/lib/tailscale` will be retained indefinitely across reboots.
- `desktop-pc` imports `inputs.preservation.nixosModules.default` via `mkHost` (`modules/core/lib.nix`) with `preservation.enable` defaulting to `false`, allowing `preservation.preserveAt."/persistent".directories` definitions in shared service modules to evaluate cleanly as a no-op on non-impermanent hosts (matching the pattern used in `modules/services/podman.nix` and `modules/services/opencode.nix`).
