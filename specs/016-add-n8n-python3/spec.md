# Feature Specification: Enable Python 3 Script Execution for n8n Code Nodes on Homelab

**Feature Branch**: `016-add-n8n-python3`

**Created**: 2026-10-15

**Status**: Draft

**Input**: User description: "Ajoute Python 3 sur `homelab` pour que n8n puisse lancer des scripts Python dans les blocs Code."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Execute Python 3 Scripts in n8n Code Nodes (Priority: P1)

As a workflow creator using n8n on `homelab`, I want to write and execute Python 3 scripts inside n8n `Code` nodes (blocs Code), so that I can transform data, parse text, perform calculations, and implement custom automation logic using Python within my automated workflows.

**Why this priority**: Directly delivers the primary user goal. Without a functional Python 3 runtime integrated with n8n's `Code` node execution engine, any workflow containing a Python `Code` block fails immediately at runtime.

**Independent Test**: Open the n8n web interface on `homelab`, create a workflow with a manual trigger followed by a `Code` node configured for Python, execute a script that transforms input items using standard Python 3 modules (such as `datetime`, `json`, or `re`), and verify that the node completes successfully and outputs the expected structured data.

**Acceptance Scenarios**:

1. **Given** an active n8n instance on `homelab`, **When** a user adds a `Code` node configured to run Python in "Run Once for All Items" mode and executes the workflow, **Then** the Python 3 script runs without runtime availability errors and returns the transformed items list to subsequent workflow nodes.
2. **Given** an n8n `Code` node configured to run Python in "Run Once for Each Item" mode, **When** multiple input items are passed into the node, **Then** the Python 3 script executes for each individual item and outputs the corresponding processed results.
3. **Given** a Python `Code` node that imports modules from the Python 3 standard library (such as `json`, `datetime`, `re`, `math`, `hashlib`, or `urllib`), **When** the node is executed, **Then** the standard library modules import and execute as expected.

---

### User Story 2 - Clear Error Reporting and Execution Isolation for Python Scripts (Priority: P2)

As a workflow creator debugging automations in n8n, I want syntax errors, unhandled exceptions, or infinite loops in a Python `Code` node to be caught, reported clearly in the n8n execution interface, and isolated from the main automation service, so that a faulty script can be diagnosed easily without crashing the n8n platform or interrupting other running workflows.

**Why this priority**: Ensures operational stability of the homelab automation platform while authoring and testing custom Python scripts.

**Independent Test**: Execute a Python `Code` node containing an intentional exception (such as `ZeroDivisionError` or `KeyError`) in the n8n editor and verify that n8n displays the Python traceback/error message in the UI while the n8n service remains healthy and responsive.

**Acceptance Scenarios**:

1. **Given** a Python `Code` node containing a syntax error or runtime exception, **When** the user runs the node in n8n, **Then** the execution fails gracefully and surfaces the Python error details in the n8n user interface without terminating the n8n service.
2. **Given** a Python `Code` node that exceeds the configured execution timeout, **When** the timeout threshold is reached, **Then** the script execution is terminated cleanly and the workflow records a timeout failure without freezing the n8n service.

---

### User Story 3 - Host Availability and Persistence Across Reboots (Priority: P2)

As a homelab administrator, I want Python 3 to be available on the `homelab` host and for n8n's Python execution capability to start automatically and persist across service restarts and host reboots, so that unattended scheduled and webhook-triggered workflows using Python `Code` nodes continue working reliably after system updates or power cycles, and administrative Python scripts can also be tested directly on `homelab`.

**Why this priority**: Guarantees long-term reliability on an impermanent server host and fulfills the user's request to have Python 3 available on `homelab` as well as usable by n8n.

**Independent Test**: Log into `homelab` via SSH to verify that `python3 --version` succeeds, restart the n8n service (or reboot `homelab`), and trigger an automated workflow containing a Python `Code` node to confirm it succeeds without manual intervention.

**Acceptance Scenarios**:

1. **Given** an administrator connected to `homelab` over SSH, **When** they invoke `python3` from the command line, **Then** the Python 3 interpreter is available and executes Python scripts using the standard library.
2. **Given** a saved and active n8n workflow containing a Python `Code` node, **When** the n8n service is restarted or the `homelab` host reboots, **Then** the Python execution capability initializes automatically alongside n8n and existing workflows, credentials, and execution history remain intact.

---

### Edge Cases

- **Missing or Unreachable Python Runner at Startup**: If n8n starts before its Python execution runtime is ready, or if the runner process crashes, the system must automatically supervise and recover the Python execution capability so subsequent workflow runs succeed.
- **Non-Serializable Return Values**: When a user's Python script attempts to return data types that cannot be serialized into workflow JSON items, n8n must return a descriptive validation error rather than hanging the workflow execution.
- **Large Input Payloads in Code Nodes**: When a workflow passes a multi-megabyte JSON payload into a Python `Code` node, the data transfer between n8n and the Python runtime must complete without truncation or premature connection reset.
- **Timezone Consistency in Python Scripts**: Date and time operations performed inside Python `Code` nodes (e.g., `datetime.now()`) must align with the configured `homelab` and n8n timezone (`Europe/Paris`).
- **Existing Workflow Compatibility**: Enabling Python 3 support must not alter the network exposure (`https://n8n.homelab.vaylet.fr`), persistent storage permissions (`/var/lib/n8n`), or JavaScript `Code` node execution of existing n8n workflows.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a Python 3 interpreter on the `homelab` host accessible to system users and administrative sessions.
- **FR-002**: The system MUST enable the n8n automation service on `homelab` to execute Python 3 scripts within n8n `Code` nodes without missing-runtime or unavailable-runner errors.
- **FR-003**: The Python 3 environment available to n8n `Code` nodes MUST include the complete standard Python 3 library so scripts can perform JSON manipulation, regular expressions, math, date/time handling, and string processing out of the box.
- **FR-004**: The n8n Python execution environment MUST support both "Run Once for All Items" and "Run Once for Each Item" execution modes in n8n `Code` nodes.
- **FR-005**: The n8n Python execution environment MUST use the same timezone (`Europe/Paris`) as the `homelab` host and the n8n service so time-sensitive Python scripts behave consistently with workflow schedules.
- **FR-006**: The Python execution capability for n8n MUST start automatically on host boot and recover automatically if the service or runner process restarts or terminates unexpectedly.
- **FR-007**: Enabling Python 3 support MUST preserve all existing n8n workflows, credentials, encryption keys, persistent storage mappings (`/var/lib/n8n`), and reverse proxy routing (`https://n8n.homelab.vaylet.fr`).
- **FR-008**: All configuration changes MUST be declared modularly within the repository's feature-centric architecture (`modules/services/n8n.nix` and `modules/hosts/homelab.nix`) without introducing imperative host state.
- **FR-009**: Project documentation (`README.md`) MUST be updated within the same branch to reflect the Python 3 capability for `n8n` on `homelab`, adhering to constitutional documentation and dual-shell parity standards.

### Key Entities

- **Python Code Node (Bloc Code)**: A workflow step within n8n where users author custom Python 3 scripts to inspect, filter, aggregate, or transform workflow data items.
- **Python 3 Runtime Environment**: The Python 3 interpreter and standard library provisioned on `homelab` and exposed to n8n's task execution mechanism.
- **Workflow Execution Payload**: The collection of structured data items passed into the Python script from upstream nodes and returned as output items to downstream nodes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of valid Python 3 scripts using standard library modules execute successfully inside n8n `Code` nodes on `homelab` in both "All Items" and "Each Item" modes.
- **SC-002**: Standard Python `Code` nodes processing typical workflow payloads (up to 100 items) complete execution and return results to the workflow within 2 seconds.
- **SC-003**: 100% of existing n8n workflows, credentials, and JavaScript `Code` nodes continue functioning without regression after enabling Python 3 support.
- **SC-004**: Following a `homelab` host reboot or service restart, n8n and its Python 3 script execution capability return to a healthy operational state automatically within 60 seconds with 0 manual intervention.
- **SC-005**: 100% pass rate on repository formatting, static analysis, and hermetic flake check gates (`just fmt`, `just lint`, `just check`).

## Assumptions

- Python scripts executed in n8n `Code` nodes rely on Python 3 and its standard library; third-party external Python packages are not required unless specified in a future iteration.
- Scope is bounded to the `homelab` host and its `n8n` automation service; `desktop-pc` and `iso` configurations do not host `n8n` and remain unaffected.
- If n8n utilizes an external or sidecar task runner architecture to execute Python 3 in its latest release, any communication between n8n and its runner remains strictly internal to the `homelab` host and is never exposed externally.
