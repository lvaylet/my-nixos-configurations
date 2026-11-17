# Feature Specification: Migrate OpenCode CLI Configuration

**Feature Branch**: `042-migrate-opencode-cli-config`

**Created**: 2026-11-17

**Status**: Draft

**Input**: User description: "Aide-moi à corriger le message d'avertissement suivant, obtenu lors du dernier `just switch` sur `desktop-pc`. L'avertissement peut s'appliquer à d'autres machines :

evaluation warning: laurent profile: programs.opencode.tui is ignored by OpenCode 2.

                    OpenCode 2 replaced tui.json with a single global cli.json. Move
                    terminal client settings to programs.opencode.cli. When
                    programs.opencode.mutableSettings is enabled, OPENCODE_TUI_CONFIG is
                    ignored as well.

                    OpenCode 2 only migrates an existing tui.json when cli.json does not
                    exist. See: https://opencode.ai/v2/docs/cli/config"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Warning-Free System Evaluation and Deployment (Priority: P1)

As a system maintainer deploying machine configurations across desktop and server environments, I want configuration evaluation and profile switching to execute without deprecation or obsolescence warnings, so that build logs remain clean and automated validation pipelines pass with zero diagnostic noise.

**Why this priority**: Eliminating evaluation warnings ensures compliance with repository quality standards and prevents automated validation checks or deployment workflows from flagging obsolete settings.

**Independent Test**: Execute system evaluation and deployment commands across all target machines and confirm that zero OpenCode-related warnings are emitted during the build and evaluation process.

**Acceptance Scenarios**:

1. **Given** a managed machine with OpenCode enabled, **When** evaluating the system configuration or executing a profile switch, **Then** the process completes cleanly with zero OpenCode evaluation warnings.
2. **Given** multiple managed machines sharing the OpenCode configuration, **When** evaluating each host configuration, **Then** none of the hosts produce warnings regarding deprecated terminal interface options.

---

### User Story 2 - Preservation of Terminal Visual Styling and Client Behavior (Priority: P2)

As a developer using the interactive AI assistant in the terminal, I want my visual styling preferences (Nord theme) and client preferences to remain active and consistently applied across all machines, so that my interactive command-line experience is preserved without disruption.

**Why this priority**: Upgrading configuration settings must not degrade or alter the developer's everyday interactive terminal environment.

**Independent Test**: Launch an interactive OpenCode terminal session on an upgraded system and confirm that the user's configured theme and styling are active.

**Acceptance Scenarios**:

1. **Given** an updated client configuration declaring the Nord theme, **When** launching an interactive session in the terminal, **Then** the assistant renders with the Nord color palette applied.
2. **Given** a machine that previously had legacy terminal configuration files, **When** the upgraded configuration is activated, **Then** modern client settings take precedence seamlessly without requiring manual configuration repair.

---

### Edge Cases

- **Existing Legacy State**: On hosts where a legacy `tui.json` file might exist in local state, the system ensures that the new declarative client configuration (`cli.json`) is properly generated and takes precedence without requiring manual file removal.
- **Multi-Host Consistency**: OpenCode is enabled across distinct host profiles (`desktop-pc`, `homelab`, and potential developer laptops); the configuration change must apply uniformly across all applicable hosts without leaving any host on deprecated options.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST declare OpenCode terminal client settings using modern command-line interface configuration options rather than legacy terminal user interface options.
- **FR-002**: System MUST configure the visual theme for OpenCode as "nord" within the active client configuration.
- **FR-003**: System evaluation and activation commands MUST complete with zero warnings regarding ignored or deprecated OpenCode terminal configuration options across all managed hosts.
- **FR-004**: System MUST ensure that modern client settings are generated and deployed to the user environment, superseding legacy configuration files.
- **FR-005**: System MUST maintain consistent OpenCode client configuration across all target machines where the OpenCode capability is enabled.

### Key Entities *(include if feature involves data)*

- **OpenCode Client Configuration**: Represents user-level settings for the OpenCode interactive command-line application, including theme styling and runtime preferences.
- **Target Host Profile**: Represents a managed machine configuration (such as desktop workstation or server) that consumes shared developer tooling and user environment settings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of managed hosts evaluate and build with zero OpenCode-related deprecation or obsolescence warnings.
- **SC-002**: Configuration build and deployment logs show 0 occurrences of warning messages regarding `programs.opencode.tui`.
- **SC-003**: User theme preferences remain 100% functional and visually verified with the Nord theme active in interactive terminal sessions.
- **SC-004**: System update verification completes successfully across all applicable machines without manual intervention.

## Assumptions

- All target machines are running or transitioning to OpenCode version 2.x where modern client configuration replaces legacy terminal configuration files.
- The desired visual theme remains "nord" across all machines, consistent with repository design standards.
- User data directories, runtime credentials, and declarative agent skills are unaffected by updating client configuration options.
