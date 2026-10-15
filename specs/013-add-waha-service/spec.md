# Feature Specification: WAHA WhatsApp Automation Service for Homelab

**Feature Branch**: `013-add-waha-service`

**Created**: 2026-10-14

**Status**: Draft

**Input**: User description: "Ajoute un service WAHA à `homelab` pour l'automatisation des tâches WhatsApp manuelles répétitives dans le cadre de mon activité dans le groupe SGDF de La Rochelle. Expose le service comme les autres sur `waha.homelab.vaylet.fr`."

## Clarifications

### Session 2026-10-14

- Q: Comment souhaites-tu gérer l'authentification de WAHA (clé API pour n8n et identifiants du tableau de bord) afin qu'elle reste stable après un redémarrage sans exposer de secrets dans Git ? (FR-008) → A: Fichier d'environnement persistant (`/var/lib/waha/waha.env`) sur l'hôte `homelab` (hors Git).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - WhatsApp Session Pairing and Automated Messaging for SGDF Activities (Priority: P1)

As an organizer within the SGDF La Rochelle group, I want to access a self-hosted WAHA (WhatsApp HTTP API) dashboard and messaging interface on my homelab at `https://waha.homelab.vaylet.fr`, so that I can pair my WhatsApp account and automate repetitive communication tasks (such as sending activity reminders, logistics announcements, and recurring group messages) without performing them manually on my phone.

**Why this priority**: Core value of the feature. Without a reachable dashboard, active WhatsApp session pairing, and programmatic message dispatch, no repetitive SGDF WhatsApp tasks can be automated.

**Independent Test**: Navigate to `https://waha.homelab.vaylet.fr` in a web browser, authenticate to the dashboard, start and pair a WhatsApp session using a QR code or pairing code, trigger a test message to a designated test contact or group, and confirm the message is delivered on WhatsApp.

**Acceptance Scenarios**:

1. **Given** the homelab host is operational and the user is connected to the authorized network, **When** the user navigates to `https://waha.homelab.vaylet.fr`, **Then** the WAHA management dashboard and API documentation interface load over a trusted HTTPS connection.
2. **Given** an unlinked WhatsApp session in the WAHA dashboard, **When** the user initiates session pairing and scans the displayed QR code (or enters the pairing code) from their WhatsApp mobile application, **Then** the session transitions to an active, working state ready to send and receive messages.
3. **Given** an active, paired WhatsApp session, **When** an authorized automation request instructs the service to send a text or media message to an SGDF contact or group, **Then** the message is transmitted and delivered to the recipient on WhatsApp.

---

### User Story 2 - Persistent WhatsApp Sessions and Configuration Across Reboots (Priority: P1)

As a homelab administrator, I want linked WhatsApp sessions, authentication credentials, and service configurations to persist across service restarts and homelab host reboots, so that scheduled and event-driven SGDF automations continue running uninterrupted without requiring manual QR code re-pairing after every reboot.

**Why this priority**: Essential for operational reliability on a host with ephemeral root storage. Re-scanning a WhatsApp QR code after every container restart or host reboot would defeat the purpose of unattended automation.

**Independent Test**: Pair a WhatsApp session until it reaches a working state, restart the service or reboot the `homelab` host, and verify that the WhatsApp session automatically reconnects and resumes a working state without requiring user re-authentication or QR code scanning.

**Acceptance Scenarios**:

1. **Given** an active and paired WhatsApp session, **When** the WAHA service or the `homelab` host is restarted, **Then** all session credentials and state are retained in persistent storage and the WhatsApp session automatically reconnects upon startup.
2. **Given** saved service configurations and webhook definitions, **When** the host reboots, **Then** all settings remain intact and active without manual reconfiguration.

---

### User Story 3 - Integration with Homelab Workflow Automation (Priority: P2)

As an automation builder for the SGDF La Rochelle group, I want WAHA to exchange events and commands with my existing homelab workflow automation platform (such as n8n), so that incoming WhatsApp messages or scheduled calendar events can automatically trigger multi-step workflows and responses.

**Why this priority**: Connects the WhatsApp communication channel with the existing homelab automation ecosystem, turning standalone messaging capabilities into end-to-end automated workflows for group management.

**Independent Test**: Configure a webhook target pointing to a homelab automation workflow, send a message to the paired WhatsApp account, and verify that the workflow receives the event payload in real time and can send an automated reply back through WAHA.

**Acceptance Scenarios**:

1. **Given** a configured webhook endpoint on the homelab automation platform, **When** a new WhatsApp message or session status event occurs, **Then** WAHA dispatches the event payload to the webhook endpoint within seconds.
2. **Given** a scheduled or event-triggered automation workflow on the homelab, **When** the workflow issues an authenticated request to WAHA, **Then** WAHA executes the requested WhatsApp action (such as sending a message, polling a group, or attaching a document) and returns the delivery status.

---

### User Story 4 - Secure Reverse Proxy Exposure and Access Control (Priority: P1)

As a homelab administrator, I want WAHA to be exposed at `https://waha.homelab.vaylet.fr` using the same reverse proxy and TLS security model as the other homelab services, and protected against unauthorized use, so that my personal WhatsApp session cannot be hijacked or abused by unauthorized parties.

**Why this priority**: A paired WhatsApp session grants direct access to personal and SGDF group communications; securing both the transport layer (`https://waha.homelab.vaylet.fr`) and service access is critical.

**Independent Test**: Verify that `https://waha.homelab.vaylet.fr` presents a valid TLS certificate, that direct external unencrypted port access to the underlying service is blocked, and that unauthenticated requests to the API or dashboard are rejected.

**Acceptance Scenarios**:

1. **Given** an authorized client accessing `https://waha.homelab.vaylet.fr`, **When** the connection is established, **Then** traffic is served over HTTPS with a valid certificate managed by the homelab reverse proxy.
2. **Given** a client attempting to access the WAHA API or dashboard without valid authentication credentials, **When** the request is received, **Then** the service rejects the request with an authentication challenge or unauthorized status.
3. **Given** the underlying local port used by WAHA on the homelab host, **When** a connection is attempted directly from an external network bypassing the reverse proxy, **Then** the connection is refused or blocked by the host firewall.

---

### Edge Cases

- **Storage Mount Latency on Host Boot**: If persistent storage mounts are not yet ready during host startup, the service must wait for local filesystems to be mounted before starting, preventing initialization of empty session directories in volatile memory.
- **Port Collisions with Existing Homelab Services**: The local loopback port allocated to WAHA on the `homelab` host must not conflict with existing services (such as n8n, Home Assistant, FileBrowser, Jellyfin, qBittorrent, Portainer, or AdGuard Home).
- **WhatsApp Connection Drops or Upstream Disconnections**: When temporary internet or upstream WhatsApp server disconnections occur, the service must automatically attempt to reconnect the paired session without losing session credentials.
- **Unexpected Service Process Termination**: If the service process crashes or exits unexpectedly, the host supervisor must automatically restart it and restore active sessions.
- **Media and Temporary File Growth**: Automated sending or receiving of documents and images for SGDF activities must not exhaust volatile memory or cause unmanaged disk space growth over time.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a self-hosted WAHA (WhatsApp HTTP API) service on the `homelab` host, including both its web management dashboard and programmatic messaging endpoints.
- **FR-002**: The system MUST expose the WAHA service over HTTPS at `waha.homelab.vaylet.fr` through the homelab reverse proxy, following the same exposure pattern as existing homelab services.
- **FR-003**: The system MUST bind the internal WAHA service listener strictly to a local loopback port on the `homelab` host that does not conflict with any other host service, ensuring all external access passes through HTTPS reverse proxy termination.
- **FR-004**: The system MUST support pairing and maintaining an active WhatsApp session via QR code or phone pairing code through the management interface.
- **FR-005**: The system MUST persist WhatsApp session authentication data, service configuration, and stored media/state in persistent host storage so that paired sessions survive service restarts, container recreations, and ephemeral root filesystem reboots.
- **FR-006**: The system MUST automatically reconnect previously paired WhatsApp sessions upon service startup or host reboot without requiring manual QR code re-scanning.
- **FR-007**: The system MUST support programmatic sending and receiving of WhatsApp messages (text, attachments, and group messages) and outbound webhook notifications to support automated workflows (such as n8n automations for the SGDF La Rochelle group).
- **FR-008**: The system MUST require authentication to access the WAHA management dashboard, API documentation, and messaging endpoints, loading static dashboard credentials and API keys from a persistent host environment file (`/var/lib/waha/waha.env`) excluded from version control so credentials remain stable across container and host restarts.
- **FR-009**: The system MUST configure the service timezone to match the local host timezone (`Europe/Paris`) so timestamps, logs, and scheduled operations align with local SGDF activity times.
- **FR-010**: The system MUST start the WAHA service automatically on system boot after persistent filesystem mounts are ready, and automatically restart the service if it terminates unexpectedly.
- **FR-011**: The WAHA service capability MUST be encapsulated as a standalone, modular service definition and enabled declaratively on the `homelab` host.

### Key Entities

- **WhatsApp Session**: Represents a linked WhatsApp account connection, including its pairing state (stopped, starting, scan QR code, working, failed), cryptographic session tokens, and reconnection policy.
- **Automation Message / Action**: A programmatic instruction sent to WAHA (e.g., from an automation workflow) to dispatch a text message, media attachment, or group interaction on WhatsApp.
- **Webhook Subscription**: Configuration defining the target endpoint (such as a local n8n workflow webhook) and event types (incoming message, message acknowledgement, session state change) forwarded in real time by WAHA.
- **Service State Store**: Persistent storage location holding WhatsApp session data, authentication state, and runtime configuration across host reboots.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Authorized users can load the WAHA web dashboard at `https://waha.homelab.vaylet.fr` within 3 seconds over the authorized network with 0 TLS certificate errors or browser security warnings.
- **SC-002**: 100% of paired WhatsApp sessions and configurations survive a full `homelab` host reboot and automatically return to a working state within 60 seconds of service startup without manual QR code re-scanning.
- **SC-003**: Automated WhatsApp message requests triggered by homelab workflows are processed and dispatched by WAHA within 2 seconds under normal operating conditions.
- **SC-004**: 100% of unauthenticated requests to the WAHA dashboard or API endpoints are denied access.
- **SC-005**: Repetitive manual WhatsApp communication tasks for the SGDF La Rochelle group configured through homelab workflows execute end-to-end with 0 manual phone interactions required per scheduled or triggered run.

## Assumptions

- The `homelab` host already runs the centralized reverse proxy with automated TLS certificate management for `*.homelab.vaylet.fr` and private network routing via Tailscale.
- The `homelab` host already runs n8n (`n8n.homelab.vaylet.fr`) as the primary workflow automation engine that will orchestrate SGDF WhatsApp tasks via WAHA.
- A single WhatsApp account/session is sufficient for the initial SGDF La Rochelle automation needs, which is supported by the standard self-hosted WAHA edition.
- Dashboard credentials and API keys for n8n integration are provisioned via a persistent environment file on the host (`/var/lib/waha/waha.env`), consistent with other homelab services (such as Caddy's `/var/lib/caddy/cloudflare.env`), without committing plaintext secrets to the repository.
- The user has an active WhatsApp account on a mobile device available to perform the initial one-time QR code or pairing code link.
