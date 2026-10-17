# Feature Specification: Uptime Kuma Monitoring Service for Homelab

**Feature Branch**: `018-add-uptime-kuma`

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "Ajoute un service Uptime Kuma à `homelab`."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Service Availability Monitoring and Live Status Dashboard (Priority: P1)

As a homelab administrator, I want to access a self-hosted Uptime Kuma monitoring dashboard on `homelab`, so that I can configure automated health checks (HTTP/HTTPS endpoints, TCP ports, DNS queries, ping, and TLS certificate expiration) for my homelab and external services and visualize real-time availability, response times, and uptime history in a single interface.

**Why this priority**: Core value of the feature. Without a functional monitoring engine and web dashboard, the administrator cannot track service health, latency trends, or downtime across homelab applications.

**Independent Test**: Open the Uptime Kuma web interface in a browser, create an administrator account on first launch, add a health check monitor for an existing homelab service (such as Home Assistant, Jellyfin, or n8n), and verify that heartbeat checks execute on schedule and display live status and response latency in the dashboard.

**Acceptance Scenarios**:

1. **Given** the `homelab` host is operational, **When** an administrator navigates to the Uptime Kuma web interface for the first time, **Then** the application prompts to create an initial administrator account and opens the monitoring dashboard.
2. **Given** a configured monitor targeting an internal or external service endpoint, **When** the check interval elapses, **Then** Uptime Kuma executes the probe, records the response status and latency, and updates the heartbeat timeline in real time without requiring a page reload.
3. **Given** an HTTPS monitor with certificate expiration checking enabled, **When** Uptime Kuma inspects the target endpoint, **Then** the remaining certificate validity period is recorded and displayed in the monitor details.
4. **Given** a Docker/OCI container monitor configured with the local container socket and a container name managed by Portainer (such as `n8n`, `waha`, `homeassistant`, `filebrowser`, or `portainer`), **When** Uptime Kuma polls the container runtime, **Then** it accurately reports the container's running/healthy state and transitions the monitor to "Down" if the container stops or crashes.

---

### User Story 2 - Persistent Monitors, Credentials, and Historical Metrics Across Reboots (Priority: P1)

As a homelab administrator operating an impermanent root filesystem on `homelab`, I want all administrator credentials, configured monitors, notification channels, status pages, and historical uptime records to persist across service restarts and host reboots, so that monitoring resumes automatically after any reboot without data loss or manual reconfiguration.

**Why this priority**: Essential for operational reliability on an impermanent server host where non-persisted root filesystem paths are wiped on every reboot.

**Independent Test**: Configure one or more monitors and a status page in Uptime Kuma, restart the service or reboot the `homelab` host, and verify that the administrator login, configured monitors, and historical heartbeat records remain intact and automatically resume checking upon startup.

**Acceptance Scenarios**:

1. **Given** configured monitors, saved notification settings, and administrator credentials in Uptime Kuma, **When** the Uptime Kuma service or the `homelab` host is restarted, **Then** all configurations and credentials remain intact and the user is not prompted to recreate the administrator account.
2. **Given** accumulated historical uptime percentages and latency graphs, **When** the `homelab` host reboots, **Then** all historical heartbeat data is preserved and monitoring probes resume automatically once persistent storage is mounted.

---

### User Story 3 - Secure HTTPS Access via Homelab Reverse Proxy (Priority: P1)

As a homelab administrator accessing services locally or remotely over the private mesh network, I want Uptime Kuma to be exposed securely over HTTPS at `https://uptime.homelab.vaylet.fr` using the same reverse proxy and TLS security model as the other homelab services while binding its internal listener strictly to localhost, so that monitoring dashboards and administrative sessions are encrypted in transit and protected from direct unencrypted access.

**Why this priority**: Aligns Uptime Kuma with the homelab's zero-trust private network and HTTPS-everywhere architecture, preventing credential exposure and avoiding local port conflicts.

**Independent Test**: Navigate to `https://uptime.homelab.vaylet.fr` from an authorized device on the private network, verify that the browser establishes a trusted HTTPS connection with zero certificate warnings, and confirm that direct external connections to the internal loopback port are refused.

**Acceptance Scenarios**:

1. **Given** an authorized client connected to the private network, **When** the user navigates to `https://uptime.homelab.vaylet.fr`, **Then** the Uptime Kuma interface loads over HTTPS with a valid, publicly-trusted TLS certificate and maintains an active real-time WebSocket connection.
2. **Given** the internal loopback port assigned to Uptime Kuma on `homelab`, **When** a connection is attempted directly to that port from an external network interface bypassing the reverse proxy, **Then** the connection is refused or blocked by the host firewall.

---

### User Story 4 - Outage Alerting and Notification Delivery (Priority: P2)

As a homelab administrator, I want Uptime Kuma to dispatch automated alerts when a monitored service becomes unreachable, recovers, or has an expiring TLS certificate, so that I am notified promptly of incidents (via webhooks, homelab automation workflows such as n8n/WAHA, or external notification channels) without manually watching the dashboard.

**Why this priority**: Extends passive status visualization into proactive incident detection and integrates naturally with the homelab's existing automation ecosystem.

**Independent Test**: Configure a notification channel (such as a webhook pointing to an n8n workflow or messaging endpoint) in Uptime Kuma, trigger a test notification or simulate a monitor failure, and confirm that the alert payload is delivered within seconds.

**Acceptance Scenarios**:

1. **Given** a monitor linked to an active notification channel, **When** the monitored target fails consecutive health checks beyond its configured retry threshold, **Then** Uptime Kuma dispatches a "Down" alert notification containing the monitor name, error reason, and timestamp.
2. **Given** a monitor currently in a "Down" state, **When** a subsequent health check succeeds, **Then** Uptime Kuma transitions the monitor back to "Up" and dispatches a recovery notification.

---

### User Story 5 - Modular Host Integration and Documentation Synchronization (Priority: P2)

As a repository maintainer, I want Uptime Kuma to be defined as a standalone, modular service capability composed into `homelab` and documented in `README.md`, so that the system architecture stays modular and the living documentation accurately reflects all hosted services, ports, storage paths, and reverse proxy endpoints.

**Why this priority**: Enforces the project's constitutional mandates for feature-centric modularity and living documentation parity.

**Independent Test**: Evaluate the system configuration to verify that Uptime Kuma is enabled on `homelab` via a dedicated service module, passes all automated quality checks, and is accurately listed in `README.md`.

**Acceptance Scenarios**:

1. **Given** the repository configuration, **When** the `homelab` host closure is evaluated, **Then** the Uptime Kuma capability is composed cleanly as a modular service feature without inline service definitions in the host file.
2. **Given** the project documentation in `README.md`, **When** inspected after adding the service, **Then** the Homelab Hosted Services table, Reverse Proxy endpoints table, and architecture overview include Uptime Kuma's subdomain, upstream target, and persistent storage directory.

---

### Edge Cases

- **Port Collision with Existing Homelab Services on Port 3001**: Uptime Kuma's standard default port (`3001`) is already bound on `homelab` by WAHA (`127.0.0.1:3001`), and port `3000` is used by AdGuard Home / container defaults. The Uptime Kuma service must be configured on a dedicated, non-conflicting local loopback port (such as `127.0.0.1:3002`).
- **Storage Mount Latency on Impermanent Host Boot**: If Uptime Kuma starts before persistent storage mounts are ready on boot, it could initialize a blank database in volatile memory (`tmpfs`), hiding existing monitors and prompting for initial setup again. Service startup must wait until local filesystems are mounted.
- **Long-Lived WebSocket Connections Behind Reverse Proxy**: Uptime Kuma relies on persistent WebSocket connections to stream live heartbeat updates to connected browsers; the reverse proxy must forward WebSocket upgrades without premature disconnects.
- **Unexpected Service Process Termination**: If the Uptime Kuma process crashes or exits unexpectedly, the host service supervisor must automatically restart it and resume all active monitoring schedules.
- **Database Growth Over Extended Operation**: Continuous heartbeat logging across multiple monitors over months of operation could increase storage consumption; the persistent state directory must reside on persistent disk storage and support Uptime Kuma's built-in data retention and cleanup policies.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a self-hosted Uptime Kuma monitoring service on the `homelab` host accessible via a web browser.
- **FR-002**: The system MUST expose the Uptime Kuma web interface and status pages over HTTPS at `uptime.homelab.vaylet.fr` through the centralized homelab reverse proxy, following the same TLS termination pattern as existing homelab services.
- **FR-003**: The system MUST bind the internal Uptime Kuma listener strictly to a local loopback address (`127.0.0.1`) on a dedicated port that does not conflict with existing homelab services (specifically avoiding port `3001` used by WAHA and port `3000` used by AdGuard Home), ensuring all external access passes through HTTPS reverse proxy termination.
- **FR-004**: The reverse proxy route for Uptime Kuma MUST support bi-directional WebSocket connections so live monitor statuses, heartbeat timelines, and configuration updates stream in real time to the browser UI.
- **FR-005**: The system MUST allow administrators to configure and run health checks across standard monitoring protocols (including HTTP/HTTPS requests, TCP ports, DNS queries, ICMP ping, TLS certificate expiration checks, and local Docker/Podman container status for containers managed by Portainer).
- **FR-006**: The system MUST grant the Uptime Kuma service access to the host's Docker-compatible Podman socket (`/var/run/docker.sock` / `/run/podman/podman.sock`) so Uptime Kuma can directly inspect and monitor all OCI containers managed by Portainer on `homelab`.
- **FR-007**: The system MUST persist all Uptime Kuma state—including administrator credentials, monitor configurations, notification channels, status pages, and historical heartbeat data—in a dedicated persistent directory (`/var/lib/uptime-kuma` preserved on `/persistent`) so that 100% of state survives service restarts and ephemeral root filesystem reboots.
- **FR-008**: The system MUST support outbound alert notifications (such as webhooks to internal automation services like n8n/WAHA or external notification services) when monitored services or containers change availability state.
- **FR-009**: The system MUST start the Uptime Kuma service automatically on system boot after persistent local filesystems and the container runtime socket are ready, and automatically restart the service if it terminates unexpectedly.
- **FR-010**: The Uptime Kuma service capability MUST be encapsulated as a standalone, modular service definition under the services domain and enabled declaratively on the `homelab` host.
- **FR-011**: Project documentation (`README.md`) MUST be updated within the same branch to document Uptime Kuma in the hosted services table, reverse proxy endpoints table, architecture overview, and Portainer/Podman container monitoring setup instructions, adhering to constitutional dual-shell (Bash/Fish) parity rules.

### Key Entities

- **Service Monitor**: A configured health check target defining the check protocol, target endpoint, polling interval, retry policy, and expected response criteria.
- **Heartbeat Record**: A timestamped check outcome recording target availability state (up, down, pending, maintenance), response latency, and diagnostic status message.
- **Notification Channel**: A configured alert destination (e.g., webhook, messaging integration) invoked when a monitor transitions between up/down states or approaches certificate expiration.
- **Status Page**: A customizable dashboard view aggregating selected monitors to display current operational status and historical uptime percentages.
- **Monitoring State Store**: The persistent storage location (`/var/lib/uptime-kuma`) preserving the service's database, configuration, and historical metrics across reboots.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Authorized users can load the Uptime Kuma web dashboard at `https://uptime.homelab.vaylet.fr` within 3 seconds over the authorized network with 0 TLS certificate errors or browser security warnings.
- **SC-002**: 100% of administrator accounts, configured monitors, notification channels, status pages, and historical heartbeat records survive a full `homelab` host reboot and resume active monitoring within 60 seconds of system startup with 0 manual intervention.
- **SC-003**: Live monitor status changes and heartbeat latency updates appear in an open Uptime Kuma browser session within 2 seconds of check completion without requiring a manual page refresh.
- **SC-004**: Outbound alert notifications are triggered and dispatched within 5 seconds of a monitored service crossing its configured failure or recovery threshold.
- **SC-005**: 100% of direct external connection attempts to the internal Uptime Kuma loopback port from outside the `homelab` host are refused or blocked, enforcing encrypted HTTPS access through the reverse proxy.
- **SC-006**: 100% pass rate on all repository quality gates (`just fmt`, `just lint`, `just check`) with `README.md` fully synchronized.

## Assumptions

- Uptime Kuma will be exposed at `https://uptime.homelab.vaylet.fr`, leveraging the existing wildcard Cloudflare DNS record (`*.homelab.vaylet.fr` pointing to `homelab`'s private Tailscale IP `100.127.199.88`) and automated Let's Encrypt DNS-01 TLS certificate management.
- Because local loopback port `3001` is already allocated to WAHA (`127.0.0.1:3001`) on `homelab`, Uptime Kuma will bind to a non-conflicting local loopback port (`127.0.0.1:3002`).
- Initial administrator account setup, monitor creation, and notification channel configuration are managed directly through the Uptime Kuma web interface on first run and stored in its persistent database under `/var/lib/uptime-kuma` (`/persistent/var/lib/uptime-kuma`), requiring no plaintext credentials in version control.
- Scope is bounded strictly to the `homelab` host; `desktop-pc` and `iso` configurations are unaffected.
