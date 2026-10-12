# Feature Specification: Migrate SSH Settings from Deprecated MatchBlocks

**Feature Branch**: `009-migrate-ssh-settings`

**Created**: 2026-10-12

**Status**: Draft

**Input**: User description: "Help me fix this warning reported on every build:

> Building NixOS configuration
evaluation warning: laurent profile: `programs.ssh.matchBlocks` defined in `/nix/store/rhsxvv1380jmchb5p3a43d24mhlmp2ry-source/flake.nix' is deprecated. Use `programs.ssh.settings`."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Clean and Warning-Free Build Diagnostics (Priority: P1)

As a system maintainer, I want system build and evaluation processes to complete cleanly without deprecation warnings regarding SSH configuration options, so that build logs remain clean, actionable, and free of diagnostic noise.

**Why this priority**: Build warnings obscure genuine errors and indicate pending breaking changes in underlying toolchains. Resolving this eliminates noise and prevents future build breakage when deprecated options are eventually removed upstream.

**Independent Test**: Can be fully tested by evaluating the system configuration build and verifying that the warning regarding deprecated SSH match blocks is no longer reported in evaluation logs.

**Acceptance Scenarios**:

1. **Given** a system build or flake check invocation, **When** the configuration evaluation runs, **Then** no deprecation warnings regarding `programs.ssh.matchBlocks` or replacement options are reported.
2. **Given** automated CI and quality check runs, **When** configuration integrity is verified, **Then** the check passes cleanly with zero diagnostic warnings.

---

### User Story 2 - Transparent Remote Host Connectivity Parity (Priority: P1)

As an administrative user connecting to managed devices, I want my configured SSH host connections (such as `rpi3` and `homelab-vm`) to retain identical connection settings (host addresses, user accounts, authentication keys, and security parameters), so that day-to-day remote operations, terminal sessions, and automated tasks continue functioning without interruption or manual adjustments.

**Why this priority**: Maintaining remote host connectivity is essential for managing networked devices; any change in connection parameters would break administrative workflows and remote access.

**Independent Test**: Can be tested by verifying that generated client SSH connection settings for defined hosts match the target IP addresses, usernames, and authentication key configurations, and confirming that remote connections succeed with expected authentication credentials.

**Acceptance Scenarios**:

1. **Given** an existing SSH client configuration for managed hosts (`rpi3`, `homelab-vm`), **When** migrating to modern configuration options, **Then** the resulting connection profile retains identical host addresses, target usernames, identity files, and host-key checking settings.
2. **Given** an interactive or automated SSH connection attempt to a configured host, **When** establishing a session, **Then** the client resolves the expected target address and authentication identity without authentication failures or host mismatch errors.

---

### User Story 3 - Repository Code Hygiene and Standards Compliance (Priority: P2)

As a repository maintainer, I want the updated configuration module to adhere strictly to project code formatting, static linting, and architectural modularity standards, so that code quality and consistency are maintained across all configuration modules.

**Why this priority**: Ensures compliance with repository governance principles (shift-left quality and dendritic modularity) and prevents code debt.

**Independent Test**: Can be tested by running automated linters, formatters, and flake integrity verification commands on the repository.

**Acceptance Scenarios**:

1. **Given** the modified configuration file, **When** static code analysis and linting tools are executed, **Then** all checks succeed with zero errors and zero warnings.
2. **Given** repository formatting standards, **When** code formatters are executed, **Then** all files are properly formatted according to project conventions.

---

### Edge Cases

- **Host Alias Parameter Variations**: Custom flags (e.g., disabled IP checking or specific key paths) must be mapped faithfully to the modern configuration syntax without dropping security directives or connection behaviors.
- **Multi-Host Evaluation**: The updated configuration must evaluate consistently across all host targets where the user profile is active (`desktop-pc`, `homelab`, etc.) without evaluation discrepancies.
- **Default Configuration Fallbacks**: Disabling default configuration (`enableDefaultConfig = false`) must continue to work as intended, ensuring upstream defaults do not inadvertently re-enable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST configure user SSH client settings using the modern `programs.ssh.settings` structure in place of deprecated `programs.ssh.matchBlocks`.
- **FR-002**: The system MUST preserve all existing host aliases and their configured parameters, including hostnames (`192.168.1.68`, `192.168.1.194`), usernames (`pi`, `core`), identity file paths (`~/.ssh/id_ed25519`), and host IP verification settings (`checkHostIP = false`).
- **FR-003**: The system configuration evaluation MUST NOT produce any deprecation warnings concerning `programs.ssh.matchBlocks`.
- **FR-004**: The rendered SSH client configuration MUST produce equivalent connection behavior to the pre-migration state for all defined hosts.
- **FR-005**: The modified module MUST conform to repository formatting, static analysis, and dendritic modularity rules without introducing dead code or lint warnings.

### Key Entities

- **SSH Host Configuration Profile**: A named profile containing remote connection instructions (hostname/IP address, login username, identity key path, and host verification flags) used by the SSH client to connect to remote systems.
- **Client SSH Configuration**: The user-level configuration rendered to `~/.ssh/config` that OpenSSH consumes during outgoing client connections.
- **Build Diagnostic Stream**: The evaluation and build log output generated during system configuration checks and builds, which must remain free of deprecation warnings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% elimination of the `programs.ssh.matchBlocks` deprecation warning during evaluation of all system configurations.
- **SC-002**: 100% parameter equivalence in generated SSH client configuration settings for all declared hosts (`rpi3`, `homelab-vm`).
- **SC-003**: 0 connectivity regressions or behavioral changes for configured remote host connections.
- **SC-004**: 100% pass rate on all automated repository quality checks (`just lint`, `just fmt`, `just check`) with zero errors and zero warnings.

## Assumptions

- The deprecation warning is caused by upstream Home Manager deprecating `programs.ssh.matchBlocks` in favor of `programs.ssh.settings`.
- The user profile `laurent` is the primary target where this SSH client configuration is evaluated.
- The `enableDefaultConfig = false` option remains active to preserve the intended baseline configuration behavior.
- Remote devices (`rpi3` at `192.168.1.68` and `homelab-vm` at `192.168.1.194`) and authentication key paths remain unchanged.
