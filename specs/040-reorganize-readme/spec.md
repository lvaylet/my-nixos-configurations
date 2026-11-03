# Feature Specification: Reorganize README for Progressive Disclosure and Clarity

**Feature Branch**: `040-reorganize-readme`

**Created**: 2026-11-02

**Status**: Draft

**Input**: User description: "Comment réorganiser @README.md pour qu'il soit moins impressionnant ?"

## Clarifications

### Session 2026-11-03

- Q: Quelle architecture documentaire préférez-vous pour alléger le README ? → A: **Option A (Modulaire via `docs/`)** : conserver un `README.md` concis (< 200 lignes) servant de vitrine et de hub d'orientation, et déplacer les longs runbooks (bootstrap Mac M4, installation headless Homelab avec `nixos-anywhere`, configuration détaillée par service) vers des guides dédiés sous `docs/` (`docs/hosts/`, `docs/services/`).
- Q: Comment souhaitez-vous traiter les volumineuses tables d'alias (Git, systemctl, journalctl) ? → A: **Option A (Vers `docs/reference/`)** : déplacer les tableaux exhaustifs de raccourcis Git, systemctl et journalctl vers `docs/reference/shell-aliases.md` et ne conserver dans le `README.md` que les recettes opérationnelles indispensables pilotées par `just`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Welcoming and Digestible Landing Page for Visitors & Newcomers (Priority: P1)

As a developer or visitor browsing the repository for the first time, I want to open `README.md` and immediately understand what the project is, what machines it manages, and how to get started in under 30 seconds, without being overwhelmed by a 600+ line wall of deep provisioning manuals, raw secrets snippets, and service setup tokens.

**Why this priority**: First impressions and cognitive load determine whether the documentation is inviting or intimidating. The landing page must provide high-level orientation before diving into deep technical minutiae.

**Independent Test**: Read `README.md` from top to bottom; verify that a newcomer can understand repository purpose, host topology, architecture overview, and basic development shell access without scrolling past lengthy initial bootstrap commands or service-specific configuration recipes.

**Acceptance Scenarios**:

1. **Given** a new visitor reading `README.md`, **When** viewing the above-the-fold content and top sections, **Then** they see a clear project summary, badges, host overview matrix, and quickstart commands in under 200 lines.
2. **Given** a visitor looking for deep provisioning steps (such as macOS `synthetic.conf` setup or headless Homelab `nixos-anywhere` bootstrap), **When** scanning `README.md`, **Then** they find clear navigation links leading directly to dedicated runbooks under `docs/hosts/` rather than encountering them inline in the main reading flow.

---

### User Story 2 - Efficient Operational Navigation for Everyday Maintainers (Priority: P2)

As a repository maintainer or daily workstation operator, I want quick access to everyday workflows (`just` recipes, remote deployment commands, formatting/linting instructions) organized by use case, so that I can execute common tasks without hunting through multi-page installation logs.

**Why this priority**: Daily maintainers need fast reference to routine commands (`just switch`, `just test`, `just check`) without cognitive clutter from one-time setup steps.

**Independent Test**: Verify that all core operational workflows (`just` recipes, remote SSH deployment patterns, dual Bash/Fish command variants, quality gate checks) are grouped logically in a dedicated, scannable section with explicit navigation.

**Acceptance Scenarios**:

1. **Given** an operator needing to run remote deployments or routine maintenance, **When** navigating to the operational section, **Then** they see a structured command reference grouped by task (building, testing, switching, linting) with clear dual-shell (Bash and Fish) parity.
2. **Given** any command syntax differences between shells, **When** displayed in the documentation, **Then** explicit Bash and Fish code blocks are preserved in compliance with project constitution standards.

---

### User Story 3 - Streamlined Reference and Modular Runbooks under `docs/` (Priority: P3)

As an administrator configuring a specific homelab service or looking up shell alias definitions, I want detailed configuration steps and reference tables structured hierarchically in dedicated documents under `docs/` (`docs/hosts/`, `docs/services/`, `docs/reference/`), so that deep documentation is accessible on demand without inflating the primary README.

**Why this priority**: Detailed setup guides for 12+ individual services (Cloudflare API tokens, WAHA WhatsApp pairing, Home Assistant proxy settings, SGDF tokens) and exhaustive alias tables are valuable reference material, but clumping them together linearly causes cognitive fatigue.

**Independent Test**: Verify that all detailed configuration instructions for homelab services and full alias tables remain 100% intact and accurate, but are organized into modular sub-documents under `docs/` so they do not obstruct casual reading.

**Acceptance Scenarios**:

1. **Given** an administrator setting up WAHA, Caddy Cloudflare tokens, or Home Assistant reverse proxy trust, **When** browsing the service documentation, **Then** they find a dedicated service guide under `docs/services/` with persistent storage paths, network ports, and secret handling without omission.
2. **Given** the full list of Git, systemctl, and journalctl shortcuts, **When** accessed by the user, **Then** all aliases are grouped in `docs/reference/shell-aliases.md` rather than occupying 100+ lines in the center of the main `README.md`.

---

### Edge Cases

- **Preservation of Living Documentation & Constitution Principles**: Constitution Principle VI mandates that repository documentation must accurately reflect services, ports, paths, reverse proxy endpoints, and dual Bash/Fish commands. Moving runbooks into `docs/` must preserve 100% of the technical information and dual-shell parity.
- **Deep Links & Cross-Document Navigation**: Every sub-document under `docs/` must link back to `README.md`, and all links from `README.md` to `docs/` must be validated to prevent broken relative links.
- **Markdown Linting & Formatting**: All newly created files under `docs/` and the updated `README.md` must pass `just lint-md` (`markdownlint-cli2`) with zero errors or warnings.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository documentation MUST adopt a modular multi-file architecture with a root `README.md` and a dedicated `docs/` directory (`docs/hosts/`, `docs/services/`, `docs/reference/`).
- **FR-002**: The top of `README.md` MUST present an inviting, high-level overview comprising: project purpose, host topology matrix (`desktop-pc`, `homelab`, `macbook-air-m4-15`, `iso`), architecture overview (Dendritic Pattern), and quickstart options (Devbox and native Nix flakes).
- **FR-003**: The primary `README.md` MUST remain concise and scannable, strictly keeping its total length under 200 lines.
- **FR-004**: One-time initial host provisioning procedures (macOS `synthetic.conf` and `nix-darwin` bootstrap, Homelab `nixos-anywhere` and custom ISO bootstrap) MUST be extracted into dedicated host provisioning runbooks (`docs/hosts/macbook.md`, `docs/hosts/homelab.md`).
- **FR-005**: The service catalog in `README.md` MUST provide a clean summary table of hosted services with URLs, ports, and brief descriptions, while detailed per-service first-time setup recipes (Cloudflare tokens, WAHA pairing, Home Assistant proxy, Uptime Kuma docker socket, SGDF tools tokens) MUST be extracted into modular service documentation (`docs/services/`).
- **FR-006**: The exhaustive Git, systemctl, and journalctl alias tables MUST be extracted to a dedicated reference document (`docs/reference/shell-aliases.md`). The primary `README.md` MUST only display everyday operational commands (`just` recipes).
- **FR-007**: All shell commands and snippets throughout `README.md` and all files under `docs/` MUST retain strict dual-shell parity (explicit **Bash** and **Fish** blocks) in compliance with Constitution Principle VI.
- **FR-008**: All markdown documentation files (both `README.md` and everything under `docs/`) MUST pass `just lint-md` (`markdownlint-cli2`) with zero errors or warnings.

### Key Entities

- **Landing Hub (`README.md`)**: The central entry point (< 200 lines) providing project identity, architecture summary, host matrix, quickstart, core `just` operations, summary service table, and links to detailed runbooks.
- **Host Provisioning Runbooks (`docs/hosts/`)**: Detailed, step-by-step first-time bootstrap manuals for bare-metal Homelab (`docs/hosts/homelab.md`) and macOS (`docs/hosts/macbook.md`).
- **Service Integration Runbooks (`docs/services/`)**: Step-by-step guides for individual homelab application configurations and secret provisioning (`docs/services/homelab-services.md` or dedicated service guides).
- **Command & Alias Reference (`docs/reference/shell-aliases.md`)**: Exhaustive reference of daily system shortcuts, Git aliases, and shell enhancements.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The line count of the main `README.md` is reduced by at least 65% (from 612 lines down to under 200 lines) while preserving 100% of existing technical instructions across the modular `docs/` suite.
- **SC-002**: A reader can locate common daily operations (`just` recipes, dev shell activation, linting/formatting) within the first 2 viewports (screens) of `README.md`.
- **SC-003**: 100% of operational commands with shell-specific syntax maintain explicit Bash and Fish variants across both `README.md` and all sub-documents in `docs/`.
- **SC-004**: 100% of documentation files format cleanly with `markdownlint-cli2` and pass repository markdown quality gates (`just lint-md` / `just fix-md`) with zero warnings.

## Assumptions

- Target readers include both curious external visitors (who need a fast overview) and the repository maintainer (who needs fast access to runbooks and operational recipes).
- Moving detailed runbooks and alias tables to `docs/` aligns with standard open-source repository organization and respects the intent of Constitution Principle VI by keeping operational data fully documented, verified, and linked.
- All technical information currently in `README.md` is accurate and valuable; none of it will be permanently deleted, only reorganized into modular documents.
