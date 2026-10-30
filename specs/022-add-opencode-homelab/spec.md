# Feature Specification: OpenCode v2 on Homelab with Shared Configuration and Web Access

**Feature Branch**: `022-add-opencode-homelab`

**Created**: 2026-10-25

**Status**: Draft

**Input**: User description: "Aide-moi à installer OpenCode v2 sur la machine `homelab`. Réutilise et mutualise la configuration d'OpenCode des autres machines. OpenCode devra être accessible dans un shell et aussi via un navigateur et exposé sur <https://opencode.homelab.vaylet.fr>"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Interactive OpenCode Shell Environment on `homelab` (Priority: P1)

As a developer or system administrator logged into `homelab` via terminal or SSH, I want to run OpenCode v2 directly within my shell session with my preferred theme, tools, and agent settings, so that I can perform coding tasks, script maintenance, and automated troubleshooting directly on the server without manual environment reconfiguration.

**Why this priority**: Delivering the command-line interface on `homelab` provides immediate value as an operational tool on the server and forms the core capability for running OpenCode tasks locally.

**Independent Test**: Connect to `homelab` via terminal or SSH, invoke the `opencode` command, and verify that the interactive interface launches immediately with user configuration applied.

**Acceptance Scenarios**:

1. **Given** an interactive terminal session on `homelab`, **When** the user executes the `opencode` command, **Then** the OpenCode v2 interface starts interactively in the shell.
2. **Given** an active OpenCode shell session on `homelab`, **When** the user enters a prompt or command, **Then** OpenCode processes the request, executes required local tools with appropriate permissions, and displays results using the configured visual theme.
3. **Given** a user session terminated by exiting, **When** the user exits OpenCode, **Then** control returns cleanly to the shell prompt without orphaned background processes.

---

### User Story 2 - Shared and Mutualized OpenCode Configuration Across Machines (Priority: P2)

As a multi-machine developer maintaining workstations and servers (`desktop-pc`, `macbook-air-m4-15`, and `homelab`), I want common OpenCode configurations (visual themes, agent behaviors, skills, and model preferences) to be centrally defined and shared, so that configuration updates are applied consistently across all hosts without duplication or configuration drift.

**Why this priority**: Eliminates redundant configuration definitions across different hosts, guaranteeing consistency of themes, tools, and agent capabilities across the entire fleet.

**Independent Test**: Update a shared OpenCode setting (such as a visual theme or custom agent instruction) in the centralized configuration, apply changes to `homelab` and another host, and confirm that both hosts reflect the updated setting identically.

**Acceptance Scenarios**:

1. **Given** the shared OpenCode configuration module, **When** examining the configuration across `desktop-pc`, `macbook-air-m4-15`, and `homelab`, **Then** all machines consume the common settings without duplicated definitions.
2. **Given** a host-specific need (such as server-only services vs. desktop-only integrations), **When** applying configuration, **Then** shared settings are preserved while host-specific variations remain modular and decoupled.
3. **Given** an update to a shared preference or tool, **When** the update is published, **Then** all enabled hosts automatically inherit the update on their next configuration deployment.

---

### User Story 3 - Browser Access and HTTPS Exposure via `opencode.homelab.vaylet.fr` (Priority: P3)

As a developer working remotely or from a lightweight device without a local command-line environment, I want to access OpenCode v2 via a web browser at `https://opencode.homelab.vaylet.fr`, so that I can initiate, monitor, and interact with coding agent sessions through a secure and responsive web interface.

**Why this priority**: Extends OpenCode accessibility beyond terminal sessions, enabling remote usage and browser-based workflows from any authorized device.

**Independent Test**: Navigate to `https://opencode.homelab.vaylet.fr` in a modern web browser, confirm that a secure HTTPS connection is established with a valid TLS certificate, and verify that the OpenCode web UI loads and accepts user prompts.

**Acceptance Scenarios**:

1. **Given** an authorized client with web browser access, **When** navigating to `https://opencode.homelab.vaylet.fr`, **Then** the connection uses valid HTTPS encryption and displays the OpenCode web interface.
2. **Given** a request sent via unencrypted HTTP (`http://opencode.homelab.vaylet.fr`), **When** received by the server, **Then** the request is automatically redirected to the secure HTTPS endpoint.
3. **Given** an active web session, **When** the user submits coding prompts and file inspection requests, **Then** OpenCode streams responses and updates session state in real time.
4. **Given** an unauthorized connection attempt from an unauthenticated or untrusted source, **When** access is attempted, **Then** access control mechanisms deny access to prevent unauthorized agent execution.

---

### User Story 4 - Session Persistence and Operational Continuity Across Reboots (Priority: P4)

As a homelab administrator, I want OpenCode session history, user preferences, and web daemon processes to survive host reboots, so that ongoing work is not lost and the service remains continuously available without manual administrator intervention.

**Why this priority**: Ensures service reliability, data retention, and system resilience for server operations and long-running workflows.

**Independent Test**: Create an active session with prompt history on `homelab`, reboot the machine, reconnect, and confirm that previous session history is preserved and the background web service starts automatically.

**Acceptance Scenarios**:

1. **Given** an active OpenCode history and persistent configuration on `homelab`, **When** the host undergoes a system reboot, **Then** previous session history and configuration data remain accessible.
2. **Given** the OpenCode web service enabled on `homelab`, **When** the host completes system boot, **Then** the service starts automatically in the background and responds to incoming requests on `https://opencode.homelab.vaylet.fr`.
3. **Given** a service crash or abnormal termination, **When** the failure occurs, **Then** the service manager automatically restarts the process to restore availability.

---

### Edge Cases

- **Transient Network Disruptions**: What happens when network connectivity drops during an active web session? The web interface should notify the user of disconnection, attempt automatic reconnection, and preserve unsaved prompt drafts.
- **Concurrent Shell and Web Sessions**: How does the system handle simultaneous sessions from the command line and the web browser? Multiple sessions must operate independently without locking each other out or corrupting shared session logs.
- **Host Reboot During Active Execution**: What happens if the host is restarted while an agent is executing a multi-step task? The service must terminate gracefully without database corruption, and record a clear interrupted status in the session log.
- **Unauthenticated Web Requests**: How does the system handle access attempts from unauthorized external networks or missing authentication tokens? The gateway must reject unauthenticated requests before they reach the execution engine.
- **File System State Reset**: Given that `homelab` uses impermanence/state preservation, what happens to OpenCode data stored outside persistent paths? All critical application data, session histories, and credentials must reside strictly on designated persistent paths.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST make the OpenCode v2 command-line tool accessible in the shell environment on `homelab` for interactive terminal use.
- **FR-002**: System MUST centralize common OpenCode configurations (themes, agent profiles, skills, and model preferences) into a reusable shared module consumed by `homelab`, `desktop-pc`, and `macbook-air-m4-15`.
- **FR-003**: System MUST execute a persistent OpenCode web server daemon on `homelab` providing a browser-accessible graphical user interface.
- **FR-004**: System MUST expose the OpenCode web interface at `https://opencode.homelab.vaylet.fr` with automatic TLS certificate provisioning and renewal.
- **FR-005**: System MUST redirect all unencrypted HTTP traffic directed at `opencode.homelab.vaylet.fr` to HTTPS.
- **FR-006**: System MUST enforce access control on the web endpoint to ensure only authorized users can access the interface and initiate agent tasks.
- **FR-007**: System MUST preserve OpenCode session histories, workspace state, caches, and authentication credentials across host reboots using persistent storage paths.
- **FR-008**: System MUST configure the OpenCode web daemon to start automatically on system boot and restart automatically in the event of unexpected process failure.
- **FR-009**: System MUST update operational documentation (`README.md`) with deployment, access, and service management instructions, providing explicit variants for both Bash and Fish shells.

### Key Entities *(include if feature involves data)*

- **OpenCode Configuration**: The declarative settings bundle comprising UI theme, default models, agent personalities, skill definitions, and shared environment settings shared across machines.
- **OpenCode Session**: A persistent record of interaction between user and agent, containing messages, execution plans, tool invocation logs, and workspace context.
- **Web Service Endpoint**: The networked web service configuration comprising internal network binding, public hostname (`opencode.homelab.vaylet.fr`), TLS certificates, and access control policies.
- **Persistent Workspace State**: The persistent on-disk data structures containing active project states, caches, authentication tokens, and session history stored in durable storage.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An administrator connecting to `homelab` via terminal can launch an interactive OpenCode session in under 2 seconds.
- **SC-002**: Navigating to `https://opencode.homelab.vaylet.fr` loads the functional web interface in under 3 seconds with a trusted, valid TLS certificate.
- **SC-003**: 100% of common OpenCode configuration options (such as theme and agent presets) are shared from a single location across all target hosts without copy-pasted definitions.
- **SC-004**: OpenCode web service automatically recovers and is accessible within 30 seconds following a host reboot.
- **SC-005**: 100% of unauthorized connection attempts to the web endpoint are blocked before agent command execution can occur.
- **SC-006**: 100% of operational documentation commands in `README.md` have tested, working syntax for both Bash and Fish shells.

## Assumptions

- The base domain `homelab.vaylet.fr` and DNS routing for `opencode.homelab.vaylet.fr` are managed by existing homelab infrastructure and DNS automation.
- The host `homelab` maintains stable network connectivity to reach necessary model provider APIs and package distribution channels.
- The user possesses valid credentials or API keys for their chosen language model providers, managed via secure runtime mechanisms or environment files.
- The web browser client used to access the web UI supports modern web standards (HTML5, WebSockets, JavaScript, and TLS 1.3).
- Existing workstation machines (`desktop-pc`, `macbook-air-m4-15`) can adopt the shared OpenCode module without disruption to their existing terminal workflows.
