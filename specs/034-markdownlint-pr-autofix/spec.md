# Feature Specification: Markdownlint Availability & Pull Request Auto-Fix

**Feature Branch**: `034-markdownlint-pr-autofix`

**Created**: 2026-10-30

**Status**: Draft

**Input**: User description: "Ajoute markdownlint-cli2 à toutes les configurations, puis implémente la correction automatique des fichiers Markdown de chaque Pull Request avec l'option `--fix` (sauf ceux du sous-dossier `.agents`)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automatic Markdown Formatting in Pull Requests (Priority: P1)

As a repository contributor submitting or updating a Pull Request with Markdown documentation, I want formatting defects to be automatically detected and fixed so that I do not have to manually format lines, headings, or spacing before review.

**Why this priority**: Automating style corrections on every Pull Request eliminates tedious code review cycles, keeps documentation consistent across the entire repository, and guarantees that documentation standards are maintained effortlessly.

**Independent Test**: Submit a Pull Request that introduces common Markdown styling defects (such as missing blank lines around headers, irregular list spacing, or trailing spaces) in a document outside the `.agents` and `.opencode` directories. Verify that the automated workflow runs, applies corrective fixes, and pushes a clean commit back to the Pull Request branch without human intervention.

**Acceptance Scenarios**:

1. **Given** a Pull Request modifying Markdown files with auto-fixable formatting violations outside `.agents/` and `.opencode/`, **When** the automated quality pipeline triggers, **Then** formatting corrections are applied using `--fix` and committed to the Pull Request branch.
2. **Given** a Pull Request where all Markdown files already satisfy formatting standards, **When** the pipeline runs, **Then** no new commits are generated and the check passes cleanly.
3. **Given** a Pull Request that introduces syntax issues that cannot be automatically resolved, **When** the pipeline runs, **Then** auto-fixable issues are corrected and remaining errors are clearly highlighted in the workflow output.

---

### User Story 2 - Strict Exemption of Agent and Tool Configuration Directories (Priority: P2)

As a maintainer managing internal agent instructions, skills, and OpenCode commands, I want files inside the `.agents` and `.opencode` subfolders to be strictly exempted from automated Markdown linting and auto-fixing so that prompt structure, upstream skill configurations, command templates, and agent definitions remain unmodified.

**Why this priority**: Agent configurations and command definitions in `.agents` and `.opencode` may have specific prompt structures or template constraints that should not be altered by general Markdown styling rules.

**Independent Test**: Create a Pull Request containing changes to a general documentation file and files under `.agents/` and `.opencode/`, containing styling quirks. Verify that only the general documentation file is modified by the auto-fix mechanism, while files in `.agents/` and `.opencode/` remain byte-for-byte identical.

**Acceptance Scenarios**:

1. **Given** a Pull Request modifying Markdown files inside `.agents/` or `.opencode/`, **When** the automated correction workflow runs, **Then** files within `.agents/` and `.opencode/` and their subdirectories are skipped and remain unmodified.
2. **Given** a Pull Request that only modifies files inside `.agents/` or `.opencode/`, **When** the automated workflow runs, **Then** no formatting changes or commits are produced.

---

### User Story 3 - System-Wide Markdown Tooling Across All Configurations (Priority: P3)

As a system operator or developer working on any configured machine (desktop, homelab, installer, or laptop) or within the shared development environment, I want `markdownlint-cli2` to be pre-installed and available in my command path so that I can validate and format documentation locally before submitting changes.

**Why this priority**: Local availability enables developers to check and fix Markdown files on their own machines prior to pushing, shifting quality verification left and speeding up feedback loops.

**Independent Test**: On any configured machine environment or within the repository's development shell, run `markdownlint-cli2 --version` and verify that the command executes and reports the tool version.

**Acceptance Scenarios**:

1. **Given** an operator working on any configured system host, **When** they execute `markdownlint-cli2` from the terminal, **Then** the executable runs successfully.
2. **Given** a developer entering the project's development shell, **When** they run `markdownlint-cli2` on local documentation files, **Then** the command processes files and applies formatting fixes on demand.

---

### Edge Cases

- **Pull Requests with no Markdown changes**: When a Pull Request only touches source code, configuration files, or Nix expressions, the Markdown correction step skips processing without creating empty commits.
- **Pull Requests from external or fork branches**: When a Pull Request originates from an environment where direct branch write access is restricted, the workflow provides clear failure or advisory feedback rather than stalling or crashing silently.
- **Unfixable styling violations**: When Markdown documents contain syntax errors or rule violations that cannot be automatically fixed by `--fix`, the workflow logs descriptive diagnostic output so contributors can address them manually.
- **Concurrent workflow runs on subsequent pushes**: When a contributor pushes additional commits to a Pull Request while an automated run is already in flight, older runs are cancelled cleanly to avoid race conditions or merge conflicts.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST include `markdownlint-cli2` in the installed packages of all target operating environments (NixOS hosts, macOS/Darwin configurations, and the repository development shell).
- **FR-002**: System MUST trigger an automated Markdown correction workflow on every Pull Request targeting the default branch.
- **FR-003**: The automated Pull Request workflow MUST execute `markdownlint-cli2` with the `--fix` option against targeted Markdown files in the repository.
- **FR-004**: The automated workflow MUST strictly exclude all Markdown files located within the `.agents` and `.opencode` directories and all their subdirectories from linting and auto-fixing.
- **FR-005**: When formatting violations are corrected, the workflow MUST commit the changes and push them back to the Pull Request branch.
- **FR-006**: The automated commit message MUST explicitly identify that the revisions were generated by automated Markdown linting.
- **FR-007**: When no formatting corrections are required, the workflow MUST NOT create empty commits or modify the Git history.
- **FR-008**: Living documentation (`README.md`) MUST be updated to describe the Markdown linting capability and provide usage commands with dual-shell parity (both Bash and Fish variants).

### Key Entities *(include if feature involves data)*

- **Markdown Document**: Textual files with `.md` or `.markdown` extensions containing specifications, documentation, and guides throughout the repository.
- **Pull Request**: A proposed revision branch opened against the main repository branch to be validated and merged.
- **Excluded Path**: File and folder paths (specifically `.agents/`, `.opencode/`, and any nested children) designated as immune to automated linting and formatting changes.
- **Host Configuration**: Declarative host profiles (desktop-pc, homelab, iso, macbook-air-m4-15, and devshell) defining system environments and installed software packages.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of Pull Requests with auto-fixable documentation styling violations outside the excluded directory receive automated fixes within 2 minutes of pipeline activation.
- **SC-002**: 0% of documentation files located in the designated excluded directories (`.agents`, `.opencode`) are modified or reformatted by automated quality checks.
- **SC-003**: The documentation styling CLI is accessible and functional across 100% of target operating environments immediately after system initialization.
- **SC-004**: Automated styling checks generate zero redundant or empty revisions when documentation already adheres to style rules.

## Assumptions

- The Pull Request automation will have sufficient permissions to push formatting commits back to branches within the primary repository.
- `markdownlint-cli2` provided by the package management system supports the `--fix` flag and standard rule configuration mechanisms.
- Files located under `.agents` and `.opencode` contain specialized prompt or command instructions and are intentionally exempt from repository-wide Markdown styling rules.
- Local developers can use the installed `markdownlint-cli2` command or corresponding repository recipes to format documentation prior to pushing.
