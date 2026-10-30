# Feature Specification: Dynamic Tailnet SSH Access Without Static Key Distribution

**Feature Branch**: `022-enable-tailscale-ssh`

**Created**: 2026-10-25

**Status**: Draft

**Input**: User description: "Travaille sur l'Issue 37 : <https://github.com/lvaylet/my-nixos-configurations/issues/37> — Enable Tailscale SSH for dynamic tailnet access without static key distribution"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Keyless Identity-Based Remote Access Across the Private Mesh Network (Priority: P1)

As a system owner introducing a new workstation or mobile device to my private mesh network (tailnet), I want to establish remote shell sessions to my managed hosts (`homelab`, `desktop-pc`) immediately using my authenticated network identity, so that I do not have to generate a new cryptographic keypair, commit the public key to the configuration repository, and redeploy the target host before connecting.

**Why this priority**: Eliminates the primary operational bottleneck identified in Issue #37—manual static key registration and host redeployment every time a new device joins the private network.

**Independent Test**: Authenticate a newly provisioned client device to the private mesh network without generating or registering any local SSH keypair, initiate a remote shell connection to `homelab` over its private mesh address or hostname, and verify that an interactive session opens for the authorized user (`laurent` or `root`).

**Acceptance Scenarios**:

1. **Given** a managed host with mesh network SSH enabled and a newly added client device authenticated to the same private mesh network without a registered static SSH public key, **When** the operator initiates a remote shell connection to the host over the mesh network as `laurent`, **Then** the connection is authorized via mesh network identity and policy and opens an interactive shell session.
2. **Given** a managed host with mesh network SSH enabled and an operator on an authenticated mesh device, **When** the operator initiates an administrative remote shell connection as `root` in accordance with the network access policy, **Then** the connection succeeds after satisfying the configured policy verification (such as interactive session check).
3. **Given** a managed host that restarts or undergoes a system update, **When** the system finishes booting, **Then** mesh network SSH access remains enabled automatically without manual operator intervention.

---

### User Story 2 - Non-Breaking Physical Local Network Fallback Access (Priority: P1)

As a system administrator managing local infrastructure, I want traditional public-key-authenticated remote shell access over the physical local area network (LAN) to remain active alongside mesh network SSH, so that I retain uninterrupted recovery and management access if the mesh network coordination service is unreachable or during initial bare-metal provisioning.

**Why this priority**: Preserves system recoverability and ensures zero regression for existing local network workflows and emergency maintenance.

**Independent Test**: Connect to `homelab` via its physical LAN address (`192.168.1.180`) using a pre-authorized static SSH keypair while mesh network SSH is active, and verify that the standard key-based session succeeds normally.

**Acceptance Scenarios**:

1. **Given** a managed host with both mesh network SSH and standard key-based SSH enabled, **When** an operator connects to the host's physical LAN IP address using an authorized static key, **Then** the traditional SSH service authenticates the key and establishes the session without conflict.
2. **Given** an unauthenticated device on the physical LAN without an authorized static private key, **When** it attempts to connect to the host's LAN IP address, **Then** the connection is rejected.

---

### User Story 3 - Centralized Access Policy & Living Documentation (Priority: P2)

As a system operator and maintainer, I want clear documentation of the mesh network SSH architecture, the required centralized access control policy rules, and verification commands (with dual-shell compatibility where applicable), so that I can configure the network control plane accurately and verify remote access from any shell environment.

**Why this priority**: Mesh network SSH relies on both host-level activation and centralized network policy rules; documenting both alongside dual-shell operational commands fulfills project governance and prevents configuration drift.

**Independent Test**: Review the repository documentation to confirm that mesh network SSH behavior, centralized policy configuration for `laurent` and `root`, LAN fallback coexistence, and verification instructions are completely and accurately documented.

**Acceptance Scenarios**:

1. **Given** the updated project documentation, **When** an operator sets up or audits mesh network SSH, **Then** the documentation provides the exact access control policy rules required in the network administration console and explains how mesh SSH coexists with LAN SSH.
2. **Given** operational or verification commands in the documentation that use shell-specific syntax, **When** an operator follows the guide in either Bash or Fish, **Then** explicit variants for both shells are provided.

---

### Edge Cases

- **Simultaneous Mesh and LAN Listening on Port 22**: The mesh network SSH server intercepts connections only on the virtual mesh network interface (`100.x.y.z`), while the standard SSH daemon continues listening on physical LAN interfaces (`192.168.1.x`), preventing port binding conflicts.
- **Mesh Control Plane Unavailability**: If the external mesh coordination plane is temporarily unreachable or the mesh tunnel is down, operators can still access the host over the physical LAN using pre-configured static public keys.
- **Unauthorized Mesh Node or User**: If a device on the mesh network attempts to connect as a user not permitted by the centralized access policy, the connection is denied before spawning a shell.
- **High-Privilege (`root`) Access Protection**: Administrative `root` connections over the mesh network can be gated by check-mode re-authentication policies in the central console without breaking unattended standard user workflows.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Managed hosts running the private mesh network service MUST enable built-in mesh network SSH capabilities declaratively so that incoming SSH connections on the mesh interface are authenticated via mesh network identity.
- **FR-002**: Newly authenticated devices on the private mesh network MUST be able to establish SSH sessions to managed hosts without requiring their static SSH public keys to be added to the repository or deployed to target hosts.
- **FR-003**: Mesh network SSH activation MUST persist automatically across system reboots, service restarts, and configuration updates without manual command execution.
- **FR-004**: Traditional key-based SSH access over physical network interfaces MUST remain active and functional as a fallback mechanism for authorized static keys.
- **FR-005**: Existing static SSH public key authorizations for `laurent` and `root` MUST be preserved to guarantee uninterrupted physical LAN access and initial system bootstrapping.
- **FR-006**: Project documentation MUST be updated within the same change set to document mesh network SSH usage, the recommended centralized access policy for `laurent` and `root`, LAN fallback behavior, and dual-shell (Bash and Fish) command variants wherever shell syntax differs.
- **FR-007**: All configuration and documentation changes MUST pass repository formatting, static analysis, and automated evaluation quality gates with zero errors or warnings.

### Key Entities

- **Managed Mesh Host**: A system (`homelab`, `desktop-pc`) participating in the private mesh network that accepts identity-authenticated SSH connections on its mesh interface while maintaining key-based SSH on physical interfaces.
- **Mesh Client Device**: Any workstation or laptop authenticated to the private mesh network seeking remote shell access to a managed host without pre-shared static SSH keys.
- **Mesh SSH Access Policy**: The centralized authorization rule set in the mesh network control plane defining which members can connect to which destination hosts and local user accounts (`laurent`, `root`), and under what verification mode (`accept` or `check`).
- **Physical LAN Fallback Channel**: The standard key-authenticated SSH listener operating on local physical network interfaces independent of the mesh network.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Onboarding a new tailnet-authenticated device for SSH access to `homelab` requires 0 repository commits, 0 static public key additions, and 0 host rebuilds.
- **SC-002**: Authorized operators on any tailnet-authenticated device can establish an interactive SSH session to `homelab` in under 5 seconds (excluding interactive identity check prompts when required by policy).
- **SC-003**: 100% of existing physical LAN SSH connections using pre-authorized static keys continue to succeed without port conflicts or service interruption.
- **SC-004**: 100% of repository quality gates (formatting, static linting, dead-code detection, and full system configuration evaluation) pass with zero errors or warnings.
- **SC-005**: 100% of new or updated operational instructions in the project documentation include both Bash and Fish variants whenever shell-specific syntax is used.

## Assumptions

- Target hosts (`homelab`, `desktop-pc`) are already enrolled and authenticated in the private mesh network (Tailscale tailnet).
- The administrator has access to the mesh network administration console to apply or verify the corresponding SSH access control policy rules (`ssh` section in tailnet ACLs).
- Standard key-based SSH over the physical LAN (`192.168.1.180`) remains desirable as a resilient local fallback and for initial provisioning workflows.
