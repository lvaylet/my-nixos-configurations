# Feature Specification: Tailscale Automated Secure Authentication

**Feature Branch**: `011-tailscale-auto-auth`

**Created**: 2026-10-14

**Status**: Draft

**Input**: User description: "Make Tailscale authenticate automatically, so I do not need to run `sudo tailscale login` on startup or after a rebuild. Make sure the authentication is secure and no secret leaks."

## Clarifications

### Session 2026-10-14

- Q: How should the Tailscale authentication credentials be managed and provisioned to ensure zero secret leakage? → A: Use agenix for age-encrypted secret management and secure runtime credential injection.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unattended Secure Mesh Network Authentication (Priority: P1)

As a system administrator and workstation user, I want Tailscale to authenticate automatically on machine startup or after system rebuilds without manual CLI logins (`sudo tailscale login`) or interactive browser prompts, so that network connectivity and mesh services are immediately available.

**Why this priority**: Core objective of the feature; eliminates repetitive manual intervention every time a host boots, restarts, or updates its system configuration.

**Independent Test**: Can be fully tested by applying the configuration or rebooting the machine, verifying that the Tailscale client transitions directly to an active, connected state without executing any interactive or manual login commands.

**Acceptance Scenarios**:

1. **Given** a configured host with valid network access and provisioned credentials, **When** the machine boots up or applies a configuration update, **Then** the Tailscale client automatically authenticates to the tailnet and enters an active, connected state.
2. **Given** a machine that has rebooted, **When** the system services start, **Then** the host rejoins the mesh network automatically without prompting for administrator credentials or displaying web login URLs.

---

### User Story 2 - Zero-Leakage Credential Security (Priority: P1)

As a security-conscious administrator, I want authentication credentials and tokens to remain strictly confidential and encrypted, so that no secrets leak into version control repositories, build evaluation logs, or world-readable files.

**Why this priority**: Core security mandate and constitutional requirement; automated authentication must never compromise credentials or expose them to public or unprivileged inspection.

**Independent Test**: Can be fully tested by inspecting repository files, commit history, build outputs, and process tables to confirm that no plaintext authentication keys or secrets are exposed or logged.

**Acceptance Scenarios**:

1. **Given** version control files, configuration manifests, and build artifacts, **When** static security scanning and repository audits are executed, **Then** no plaintext authentication tokens, pre-shared keys, or private credential strings are present.
2. **Given** the automated authentication service at runtime, **When** authentication executes or completes, **Then** credentials are consumed securely without printing secret tokens into system logs or leaving persistent unencrypted files accessible to unprivileged users.

---

### User Story 3 - Node Identity Continuity Across Reboots (Priority: P2)

As a network administrator, I want an authenticated host to maintain a consistent node identity and assigned network address across reboots and configuration rebuilds, so that the machine does not generate duplicate device entries or require manual device cleanup in the network admin console.

**Why this priority**: Prevents device clutter and network address churn across normal operational lifecycles (reboots, system rebuilds).

**Independent Test**: Can be tested by noting the node identity and assigned mesh address, rebuilding the system configuration and rebooting, and verifying that the node identity and address remain unchanged in the network console.

**Acceptance Scenarios**:

1. **Given** a previously authenticated node on the tailnet, **When** the host reboots or undergoes a configuration rebuild, **Then** it reconnects under its existing machine identity and retains its assigned network address.
2. **Given** successive reboots and updates, **When** viewing the network management console, **Then** only a single persistent device entry exists for the host without orphan or duplicate records.

---

### User Story 4 - Offline Resilience and Diagnostic Visibility (Priority: P3)

As an administrator, I want the system to handle boot-time network delays or transient connectivity failures gracefully without blocking the boot sequence or leaving system services in a failed, unrecoverable state, so that system availability is preserved.

**Why this priority**: Ensures system reliability under degraded or offline network conditions while providing actionable diagnostic status when troubleshooting is necessary.

**Independent Test**: Can be tested by booting the system with network interfaces disconnected, verifying boot completion, restoring network connectivity, and confirming that authentication and connection establish automatically once the network is reachable.

**Acceptance Scenarios**:

1. **Given** an absence of upstream internet connectivity during boot, **When** system startup completes, **Then** other system services proceed normally without hanging or failing due to mesh network timeouts.
2. **Given** network connectivity restored after an initial offline boot, **When** the network becomes reachable, **Then** the Tailscale client retries and successfully establishes connection.
3. **Given** an invalid or expired authentication credential, **When** authentication fails, **Then** a clear diagnostic error is logged indicating authentication failure without exposing sensitive token contents.

---

### Edge Cases

- **Network delay at boot**: When upstream internet connectivity is not immediately available during startup, the authentication process must not block the system boot sequence and must automatically retry once the network is reachable.
- **Expired or revoked credentials**: When an authentication key expires or is revoked in the network coordination console, the system must record a clear diagnostic message without crashing background daemons or leaking credential fragments into log streams.
- **Concurrent rebuilds or service restarts**: When multiple system rebuilds or service reloads occur in rapid succession, the authentication service must avoid race conditions and maintain state consistency.
- **Missing or unreadable secret store**: When the secret store or credential reference is missing or inaccessible, the service must report a structured, permission-safe error rather than failing silently.
- **Network roaming and interface switching**: When switching network adapters (e.g., Ethernet to Wi-Fi), the authenticated session must gracefully re-establish connection without re-triggering unnecessary authentication handshakes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST automatically authenticate and connect the Tailscale client to the configured tailnet during system startup without requiring interactive user login or manual command-line intervention.
- **FR-002**: The system MUST automatically maintain or restore Tailscale authentication following system configuration rebuilds and software updates.
- **FR-003**: Authentication credentials (such as auth keys) MUST be stored encrypted at rest using agenix and decrypted securely at runtime, and MUST NOT be committed in plaintext to version control or hardcoded in configuration manifests.
- **FR-004**: The authentication process MUST NOT leak, log, or expose plaintext authentication keys or secrets in system logs, service statuses, or process argument lists.
- **FR-005**: Unprivileged system users MUST NOT have read access to authentication credentials or secret injection files.
- **FR-006**: The system MUST preserve node identity, cryptographic machine state, and assigned network addresses across reboots and rebuilds to prevent orphan or duplicate nodes in the tailnet.
- **FR-007**: The automated authentication process MUST NOT block, delay, or hang system startup if internet or coordination server connectivity is temporarily unavailable at boot.
- **FR-008**: The system MUST automatically retry authentication and network connection when network reachability is restored after an offline boot or temporary network loss.
- **FR-009**: The automated authentication configuration MUST integrate cleanly within host definitions, allowing hosts that enable Tailscale to leverage automated authentication consistently.
- **FR-010**: The system MUST provide clear, non-leaking diagnostic status indicating whether authentication succeeded, is in progress, or encountered an error.

### Key Entities

- **Tailscale Client Node**: The local machine endpoint participating in the secure mesh network with a defined identity and assigned mesh address.
- **Authentication Key / Credential**: The protected, secret authorization material used by the client to register and authenticate unattended with the network coordinator.
- **Node State & Identity**: The persistent cryptographic machine identity and session state that ties the physical or virtual host to its registered record in the network console.
- **Connection Status**: The current operational state of the mesh networking service (disconnected, authenticating, active/connected, or failed).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 0 manual `sudo tailscale login` or interactive authentication commands required after initial provisioning, across all reboots and configuration rebuilds.
- **SC-002**: Tailscale client achieves active, authenticated connection within 15 seconds of network availability during system boot.
- **SC-003**: 0 plaintext authentication secrets, keys, or tokens committed to version control or exposed in build evaluation artifacts.
- **SC-004**: 0 plaintext secret tokens exposed in system journal logs, process listings, or error reports.
- **SC-005**: 100% of node identities and assigned mesh network addresses are preserved across system reboots and updates, resulting in 0 duplicate node registrations.
- **SC-006**: 100% of system boot sequences complete without hanging or blocking when network connectivity is delayed or unavailable.
- **SC-007**: 100% pass rate on repository security scanning, linting, and flake evaluation checks (`ripsecrets`, `trufflehog`, `just lint`, `just check`).

## Assumptions

- The user has an active Tailscale network (tailnet) account and access to generate pre-authenticated or reusable authentication keys from the admin console.
- Encrypted secret management infrastructure using agenix (age-based asymmetric key encryption) is used to supply authentication tokens safely at runtime.
- Target hosts enabling the Tailscale feature have network access to reach Tailscale coordination servers under normal operational conditions.
- Interactive authentication via web browser is undesirable for automated workstation and server workflows.
