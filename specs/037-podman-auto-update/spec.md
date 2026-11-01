# Feature Specification: Automated Container Image Updates via Podman and Systemd Timer

**Feature Branch**: `037-podman-auto-update`

**Created**: 2026-11-01

**Status**: Draft

**Input**: User description: "Utilise le mécanisme natif de `podman auto-update` pour mettre à jour les images des containers automatiquement. Utilise le timer systemd natif de NixOS pour vérifier les mises à jour tous les jours."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Daily Automated Inspection and Container Refresh (Priority: P1)

As a homelab administrator, I want my host system to automatically inspect container image registries every day and refresh running containers when a new version of their image is published, so that security patches, upstream improvements, and bug fixes are applied consistently without manual intervention.

**Why this priority**: Directly satisfies the primary user requirement to automate container image updates on a daily cadence using system-level scheduling.

**Independent Test**: Trigger or wait for the scheduled daily execution on the host; verify that container image registries are polled for new image digests and that eligible containers with newer upstream images are pulled and restarted.

**Acceptance Scenarios**:

1. **Given** a container configured for automated updates and running on an older image digest, **When** the scheduled daily update job triggers, **Then** the updated image is downloaded from the container registry and the container is cleanly restarted running the new image.
2. **Given** a container running the latest image digest available in its registry, **When** the scheduled daily update job runs, **Then** the container remains running undisturbed without unnecessary restarts or downtime.
3. **Given** the system boot or generation activation, **When** examining scheduled background jobs, **Then** a recurring daily timer is active and scheduled to execute once every 24 hours.

---

### User Story 2 - Comprehensive Lifecycle Management for Portainer and Managed Services (Priority: P1)

As a homelab administrator, I want all core infrastructure containers—including Portainer CE itself as well as all service containers running on the host—to participate in automated updates while maintaining persistent volume data, so that management dashboards and operational workloads remain up-to-date without risking state loss or service corruption.

**Why this priority**: Ensures that the update mechanism covers the entire container fleet (specifically including the management UI Portainer itself) while protecting critical state stored on persistent disks.

**Independent Test**: Verify that both the Portainer container and secondary OCI containers (e.g. Home Assistant, Filebrowser, n8n, WAHA) have update tracking enabled, and that updating an image retains all database files, user accounts, and configurations located on persistent storage mounts.

**Acceptance Scenarios**:

1. **Given** Portainer CE is running on `homelab`, **When** upstream publishes a new release under its tracking tag, **Then** Portainer's image is updated, the container service restarts, and all Portainer environments, user credentials, and configurations remain intact.
2. **Given** workloads running on the host (e.g. Home Assistant, Filebrowser, n8n, WAHA), **When** an automated image refresh occurs, **Then** persistent volumes under `/persistent` retain their files and services resume functioning normally.
3. **Given** a container restart triggered by an update, **When** the service starts up, **Then** service dependencies and network bindings (such as Caddy reverse-proxy loopback ports) remain valid and reachable.

---

### User Story 3 - On-Demand Manual Update Execution (Priority: P2)

As a homelab administrator or developer performing routine system maintenance, I want an operational command to trigger container image updates on demand (both locally on the server and remotely from a workstation), so that I can immediately apply and verify updates during maintenance windows without waiting for the daily scheduled timer.

**Why this priority**: Essential for operational control, troubleshooting, and immediate validation after configuration changes or security advisories.

**Independent Test**: Execute the designated manual update recipe or command from both a local shell and a remote management machine; confirm that registry checks execute immediately, progress is displayed to the operator, and any pending updates are applied.

**Acceptance Scenarios**:

1. **Given** an operator running a maintenance workflow locally on the host, **When** executing the manual container update command, **Then** the system checks all managed containers against their registries and reports the status of each container.
2. **Given** an operator working from a remote management workstation, **When** running the update command targeting the server, **Then** the update executes on the remote host over a secure connection and streams execution status back to the operator.
3. **Given** an update command execution where no new images are available, **When** the command completes, **Then** it cleanly reports that all containers are already up-to-date.

---

### User Story 4 - Operational Documentation and Dual-Shell Command Parity (Priority: P3)

As a repository maintainer and system administrator, I want the repository documentation (`README.md`) to clearly document how container auto-updates work, how the daily schedule is configured, and how to trigger manual updates with explicit Bash and Fish command examples, so that any operator can monitor and manage the container fleet without operational confusion.

**Why this priority**: Required by repository governance (Constitution Principle VI) to prevent documentation drift and ensure command copy-paste reliability across different shells.

**Independent Test**: Review `README.md` to verify that container update procedures, schedule timers, and manual trigger commands are documented with dual Bash and Fish examples.

**Acceptance Scenarios**:

1. **Given** an operator reading `README.md`, **When** looking up container maintenance instructions, **Then** the documentation describes the daily automated timer and the manual update commands.
2. **Given** commands requiring shell-specific syntax, **When** presented in documentation, **Then** explicit Bash and Fish variants are provided side by side.

---

### Edge Cases

- **Registry Network Unavailability or Outage**: If a container registry is unreachable or network connectivity is temporarily interrupted during the daily check, the update mechanism must fail gracefully without terminating running containers or corrupting existing local images.
- **Upstream Image Failure or Startup Crash**: If a newly downloaded image fails to start or crashes immediately upon launch, the container runtime should report the failure and allow administrator intervention without cascading failures to unrelated containers.
- **Registry Rate Limiting**: When querying public registries (e.g., Docker Hub anonymous limits), consecutive queries across multiple containers must handle or log rate-limit responses cleanly.
- **Ephemeral Root Filesystem Constraints**: Because the host operates on an impermanent root filesystem with state preservation, all newly downloaded container image layers and runtime state must reside on preserved persistent storage paths (`/var/lib/containers` and `/var/tmp`) to avoid exhausting root tmpfs memory.
- **Containers Not Managed by Systemd**: Any containers created ad-hoc outside declarative systemd definitions without auto-update markers must not cause errors or interruptions to the scheduled update of systemd-supervised containers.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST configure a recurring daily timer that checks for container image updates across all eligible containers once every 24 hours.
- **FR-002**: The daily update timer MUST be persistent so that if the machine was offline or powered down when a run was scheduled, the check executes shortly after the next boot.
- **FR-003**: The container management runtime MUST inspect container registries for newer image digests corresponding to the declared image tags.
- **FR-004**: When a newer image digest is detected for an eligible container, the system MUST download the updated image and restart the associated container service to run the new version.
- **FR-005**: When no newer image digest is available for a container, the system MUST leave the running container active without restarting or interrupting the service.
- **FR-006**: The Portainer CE management container MUST be configured to participate in the automated update mechanism, pulling updated images under its tracking tag and restarting cleanly.
- **FR-007**: All declarative host container services (including Home Assistant, Filebrowser, n8n, and WAHA) MUST be configured to participate in the automated update mechanism.
- **FR-008**: The automated container update process MUST preserve all persistent directory bindings, permissions, and network endpoints across image updates.
- **FR-009**: The repository MUST provide an operational command (recipe) in `justfile` allowing operators to manually trigger the container auto-update process on demand, supporting both local execution and remote target invocation.
- **FR-010**: All operational commands and instructions documented in `README.md` MUST provide dual Bash and Fish syntax variants where applicable.

### Key Entities

- **Update Timer**: A system-level scheduling entity that triggers recurring automated container image checks on a 24-hour interval.
- **Container Auto-Update Policy**: Configuration metadata associated with each container instructing the runtime whether and how to check registries for newer image digests.
- **Managed Container Service**: A systemd-supervised OCI container (such as Portainer, Home Assistant, Filebrowser, n8n, or WAHA) that executes an application from a specified image tag.
- **Persistent State Mount**: Filesystem paths under `/persistent` bound into container filesystems to ensure data survives container recreation and host reboots.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of declared OCI container services (including Portainer) have automated update policies enabled.
- **SC-002**: The automated update schedule triggers exactly once every calendar day (24-hour cycle) under normal uptime.
- **SC-003**: When an upstream image update is released, the target container is updated and running the new image within 24 hours without administrative intervention.
- **SC-004**: 0% loss of user data, configuration files, or persistent database state during automated container image updates and restarts.
- **SC-005**: Manual update commands allow operators to check and update all containers within 60 seconds (excluding image download time dependent on network bandwidth).
- **SC-006**: 100% of static checks and quality gates (`just fmt`, `just lint`, `just check`) pass with zero errors.

## Assumptions

- The host has outbound internet access to container registries (Docker Hub, GitHub Container Registry) during the scheduled daily execution window.
- The containers use floating or tracking tags (such as `:lts`, `:latest`, `:stable`, or major version tags like `:2-stable`) intended to receive upstream updates.
- Ephemeral root preservation rules already protect `/var/lib/containers` and `/var/tmp` so that newly fetched container layers are persisted across host reboots.
- Administrative privileges (`sudo` / root) are available for running the container update runtime and restarting systemd units.
