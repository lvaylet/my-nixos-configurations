# Feature Specification: Fix Preservation Temporary Directory & Jellyfin Group Permissions

**Feature Branch**: `031-fix-preservation-permissions`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "Mets en place ce correctif permanent sur `/tmp` et `/var/tmp`, dans une branche dédiée avec une Pull Request. Corrige aussi les groupes `jellyfin` orphelins par la même occasion, pour une Pull Request orientée sur la correction et le nettoyage de permissions."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - World-Writable Sticky Temporary Directories Across Reboots (Priority: P1)

As a non-root user or developer working on `homelab`, I want `/tmp` and `/var/tmp` (and their underlying persistent directories `/persistent/tmp` and `/persistent/var/tmp`) to always retain standard world-writable sticky permissions (`1777`, `rwxrwxrwt`), so that unprivileged processes, shell tools, and Nix development environments (`direnv` / `nix print-dev-env`) can create temporary files and directories without encountering `Permission denied` errors.

**Why this priority**: When `/tmp` or `/var/tmp` defaults to mode `0755` (`root:root`), unprivileged user sessions cannot create temporary directories in `/tmp`, breaking interactive development workflows (`direnv`, `nix develop`, compilers, and editors) on `homelab`.

**Independent Test**: Can be fully tested by evaluating the host preservation configuration and running temporary file creation rules, then verifying that `/tmp`, `/persistent/tmp`, `/var/tmp`, and `/persistent/var/tmp` have mode `1777` (`drwxrwxrwt`) and that an unprivileged user can enter a Nix flake directory with `direnv` without permission errors.

**Acceptance Scenarios**:

1. **Given** `homelab` is configured with state preservation for `/tmp` and `/var/tmp`, **When** system temporary directory rules are evaluated and applied, **Then** `/tmp`, `/persistent/tmp`, `/var/tmp`, and `/persistent/var/tmp` are configured with mode `1777` owned by `root:root`.
2. **Given** an unprivileged user (`laurent`) logged into `homelab` over SSH, **When** the user navigates into a project directory managed by `direnv` and `nix-direnv`, **Then** the development environment evaluates and caches cleanly without `Permission denied` errors on `/tmp`.

---

### User Story 2 - Clean Group Ownership for Preserved Jellyfin Directories (Priority: P2)

As a system administrator maintaining `homelab`, I want Jellyfin's preserved state and cache directories (`/var/lib/jellyfin` and `/var/cache/jellyfin`) to reference the actual group configured for the Jellyfin service (`multimedia`) rather than a non-existent `jellyfin` group, so that boot-time temporary file setup (`systemd-tmpfiles-setup.service`) completes with zero group resolution errors.

**Why this priority**: Because the Jellyfin service is configured to use the `multimedia` group (`services.jellyfin.group = "multimedia"`), the default `jellyfin` group is never created on the system. Referencing `group = "jellyfin"` in preservation rules causes `systemd-tmpfiles` to fail with `Failed to resolve group 'jellyfin': Unknown group` (exit status `65`) on every boot and deployment.

**Independent Test**: Can be tested independently by evaluating the Jellyfin preservation configuration to confirm `group` matches the configured service group (`multimedia`) and running `systemd-tmpfiles --create` with zero `Unknown group` errors.

**Acceptance Scenarios**:

1. **Given** the Jellyfin service is configured with `group = "multimedia"`, **When** the system preservation rules for `/var/lib/jellyfin` and `/var/cache/jellyfin` are generated, **Then** both preserved directories specify `user = "jellyfin"` and `group = "multimedia"` (matching `config.services.jellyfin.group`).
2. **Given** the updated preservation configuration is active on `homelab`, **When** `systemd-tmpfiles-setup.service` runs, **Then** it exits with status `0` and logs zero `Failed to resolve group 'jellyfin'` errors.

---

### Edge Cases

- **System Reboot or Service Activation**: When `systemd-tmpfiles-setup.service` runs during boot or system switch, existing `/persistent/tmp` and `/persistent/var/tmp` directories that previously had `0755` permissions must have their permissions updated to `1777` so that sticky-bit world-writable access is restored automatically.
- **Unprivileged Multi-User Isolation in `/tmp`**: With mode `1777` (`drwxrwxrwt`), the sticky bit (`1`) prevents one unprivileged user from deleting or renaming files owned by another user inside `/tmp` and `/var/tmp`, preserving standard multi-user security guarantees.
- **Dynamic Service Group Alignment**: Referencing `config.services.jellyfin.group` (which resolves to `"multimedia"`) in Jellyfin's preservation entries prevents future drift if the service group is ever changed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST configure the preserved `/tmp` directory in core state preservation with mode `1777` (`rwxrwxrwt`), owned by `root:root`.
- **FR-002**: System MUST configure the preserved `/var/tmp` directory in container/service state preservation with mode `1777` (`rwxrwxrwt`), owned by `root:root`.
- **FR-003**: System MUST configure the preserved `/var/lib/jellyfin` and `/var/cache/jellyfin` directories to use the group assigned to the Jellyfin service (`multimedia` / `config.services.jellyfin.group`) rather than the non-existent `jellyfin` group, and remove obsolete inline `TODO` comments questioning those permissions.
- **FR-004**: Project documentation (`README.md`) MUST remain accurate and synchronized with any permission or state preservation documentation updates in the same branch, maintaining dual Bash and Fish command parity where applicable.
- **FR-005**: All changes MUST be delivered in a dedicated Git branch associated with a Pull Request targeting `main` and pass all repository formatting, linting, and flake check quality gates.

### Key Entities

- **Preserved Temporary Directories (`/tmp`, `/var/tmp`)**: System-wide temporary storage directories backed by `/persistent/tmp` and `/persistent/var/tmp` on `homelab`, requiring mode `1777` (`root:root`) for unprivileged multi-user write access with sticky-bit deletion protection.
- **Preserved Jellyfin Directories (`/var/lib/jellyfin`, `/var/cache/jellyfin`)**: Persistent application data and cache directories for Jellyfin backed by `/persistent/var/lib/jellyfin` and `/persistent/var/cache/jellyfin`, owned by user `jellyfin` and group `multimedia` (`0750`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of preserved temporary directories (`/tmp`, `/persistent/tmp`, `/var/tmp`, `/persistent/var/tmp`) report permission mode `1777` (`drwxrwxrwt`) after system activation.
- **SC-002**: 0 `Failed to resolve group 'jellyfin': Unknown group` errors occur during `systemd-tmpfiles` execution (`systemd-tmpfiles-setup.service` succeeds with exit code `0`).
- **SC-003**: Unprivileged users on `homelab` can evaluate and reload `direnv` Nix flake environments in 100% of attempts without `/tmp` permission errors.
- **SC-004**: 100% of repository quality gates (`just fmt`, `just lint`, `just check`) pass with exit code `0`.

## Assumptions

- The changes target the `my-nixos-configurations` repository (`~/workspace/github.com/lvaylet/my-nixos-configurations`), which manages `homelab`'s declarative NixOS and `preservation` configuration.
- Mode `0750` on `/var/lib/jellyfin` and `/var/cache/jellyfin` with `user = "jellyfin"` and `group = "multimedia"` is the intended permission posture for Jellyfin state and cache directories.
