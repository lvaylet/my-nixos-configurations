# Feature Specification: n8n Workflow Automation Service for Homelab

**Feature Branch**: `007-add-n8n-service`

**Created**: 2026-10-11

**Status**: Draft

**Input**: User description: "Ajoute un service n8n à `homelab`."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visual Workflow Design and Automation (Priority: P1)

As a homelab administrator, I want to access a self-hosted n8n workflow automation service through a responsive web interface on the homelab host, so that I can create, configure, test, and run multi-step automated workflows connecting various local and external services.

**Why this priority**: Core value of the automation platform. Without the web user interface and workflow execution engine, no automation can be built or executed.

**Independent Test**: Can be tested by opening the automation service web interface in a browser, creating a simple scheduled or manual workflow, running it, and confirming that the execution completes successfully with logged output.

**Acceptance Scenarios**:

1. **Given** the homelab host is operational, **When** an administrator accesses the workflow automation web interface, **Then** the application interface loads promptly and allows the user to create, edit, and activate workflows.
2. **Given** an activated workflow with a trigger condition, **When** the trigger condition is met, **Then** the workflow executes all configured steps in order and records the execution result.
3. **Given** an administrator testing a workflow in the editor, **When** a step is executed manually, **Then** intermediate data payloads are displayed in the user interface for inspection and debugging.

---

### User Story 2 - State and Credential Persistence Across Restarts (Priority: P1)

As a homelab administrator, I want all workflows, node configurations, integration credentials, and execution logs to persist across service restarts and host reboots, so that unattended automations remain reliable and configuration is never lost when the host machine restarts.

**Why this priority**: Essential for data integrity and operational reliability. On a host environment utilizing ephemeral root storage, non-persisted data would be permanently lost upon reboot.

**Independent Test**: Can be tested by creating an automated workflow with saved integration credentials, rebooting the homelab host, and verifying that the workflow remains active, configured, and capable of executing with valid credentials after the system starts back up.

**Acceptance Scenarios**:

1. **Given** configured workflows and saved service credentials, **When** the workflow automation service or the host machine is rebooted, **Then** all workflows, active activation states, and encrypted credentials remain fully intact without requiring manual intervention.
2. **Given** historical workflow execution logs, **When** the host is restarted, **Then** historical execution records remain accessible for auditing and monitoring.

---

### User Story 3 - Event-Driven Webhook Integration (Priority: P2)

As an automation user, I want external webhooks to trigger workflows in real time, so that external events (such as home automation sensor alerts, repository updates, or incoming notifications) can immediately invoke automated processing pipelines.

**Why this priority**: Enables real-time reactive automation between homelab services and external platforms, extending the utility beyond scheduled jobs.

**Independent Test**: Can be tested by creating a workflow triggered by an HTTP webhook, dispatching a test payload to the webhook endpoint, and verifying that the workflow is triggered immediately with the payload correctly parsed.

**Acceptance Scenarios**:

1. **Given** an active workflow configured with a webhook trigger, **When** an authorized incoming HTTP request arrives at the designated webhook endpoint, **Then** the service accepts the request and triggers the workflow within seconds.
2. **Given** an incoming request with an invalid signature or unauthorized token, **When** received at a secured webhook endpoint, **Then** the service rejects the request with an appropriate error response and does not trigger the workflow.

---

### User Story 4 - Modular Host Integration and Lifecycle Management (Priority: P1)

As a system maintainer, I want the automation service to be defined as a standalone, modular capability and composed into the homelab host, so that service dependencies, startup sequencing, and network port exposure are cleanly managed without cluttering host declarations.

**Why this priority**: Ensures long-term maintainability, clean separation of concerns, and automatic startup after host storage and virtualization dependencies are ready.

**Independent Test**: Can be tested by evaluating the system configuration to confirm that the service capability is modularized, enabled on the homelab target, and verified to start automatically upon system boot.

**Acceptance Scenarios**:

1. **Given** the declarative host configuration for homelab, **When** the configuration is evaluated, **Then** the workflow automation capability is composed cleanly as an enabled feature without inline service logic in the host definition.
2. **Given** system boot, **When** storage mounts and container/service runtime targets are reached, **Then** the automation service starts automatically and transitions to a healthy operational state.

---

### Edge Cases

- **Storage Mount Latency on Host Boot**: If persistent storage mounts experience delay during host startup, the automation service must wait for storage availability before launching, avoiding initializing temporary or blank databases in volatile memory.
- **Service Termination and Crash Recovery**: If the automation process terminates unexpectedly, the system must restart it automatically and clear any transient lock files so the service resumes normal operations without manual intervention.
- **Log and Execution History Growth**: Excessive execution records over long operational periods could exhaust persistent storage; the service must support data retention and log pruning policies.
- **Port Allocation Collisions**: The service web interface and webhook port must not conflict with any existing services deployed on the homelab host.
- **Network Interruptions During Workflow Execution**: If an external network call within a workflow fails or times out, the workflow execution engine must handle the error gracefully, log the failure, and support retry strategies where configured.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide an n8n workflow automation service accessible through a web browser.
- **FR-002**: The system MUST expose the automation service web interface and webhook endpoints on the homelab network on a dedicated, non-conflicting port (defaulting to TCP port 5678).
- **FR-003**: The system MUST allow inbound network traffic for the automation service port through the host firewall.
- **FR-004**: The system MUST persist all workflow definitions, user credentials, encryption keys, and application state in dedicated persistent storage that survives host reboots and ephemeral root wipes.
- **FR-005**: The system MUST automatically start the automation service upon host boot once storage dependencies are fulfilled.
- **FR-006**: The system MUST automatically restart the automation service if the service process terminates unexpectedly.
- **FR-007**: The system MUST securely encrypt stored third-party credentials and API tokens at rest using a dedicated encryption key.
- **FR-008**: The system MUST support incoming HTTP webhook triggers for real-time, event-driven workflow execution.
- **FR-009**: The automation service MUST be structured as a dedicated, modular feature within the project's services architecture and composed into the homelab host specification.
- **FR-010**: The system MUST configure the automation service timezone to match the local host timezone (`Europe/Paris`) so scheduled triggers run at expected local times.

### Key Entities

- **Automation Workflow**: A directed graph representing triggers, logical processing nodes, transformations, and output actions that execute sequentially or conditionally.
- **Credential Store**: An encrypted storage facility managing authentication tokens, API secrets, and connection parameters for external services accessed by workflows.
- **Execution Record**: Historical record capturing execution timing, status (success, error, waiting), input payloads, and step-by-step diagnostic output for a workflow run.
- **Automation Service Feature**: The modular configuration definition encapsulating service runtime specifications, network port rules, persistence mappings, and host composition bindings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The workflow automation web interface responds to user requests within 3 seconds of navigation under standard local network conditions.
- **SC-002**: 100% of saved workflows, encryption keys, and credentials survive a complete host system restart without data loss or required reconfiguration.
- **SC-003**: 99% of incoming webhook requests trigger their associated workflows within 2 seconds of receipt under standard system load.
- **SC-004**: Scheduled workflow triggers initiate execution within 1 second of their designated trigger time according to the local timezone.
- **SC-005**: The automation service recovers and resumes healthy operation within 30 seconds following an unexpected process termination.
- **SC-006**: The host configuration evaluates cleanly with zero syntax, type, or composition errors when the workflow automation feature is enabled.

## Assumptions

- The workflow automation service will be accessed from the local homelab network or via a secure administrative VPN/overlay connection.
- Standard embedded database storage is sufficient for single-host homelab automation workloads without requiring a separate multi-node database server.
- Default service port 5678 is available and unallocated on the homelab host.
- The automation service runs within the existing service virtualization and container infrastructure configured on the homelab host.
- Administrative user accounts and workflow authentication are managed directly within the n8n application interface upon initial setup.
- The host timezone `Europe/Paris` is adopted as the primary timezone for cron-style and scheduled triggers.
