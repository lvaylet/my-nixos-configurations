# Feature Specification: AI Skills Provisioning and Package Runners on Homelab

**Feature Branch**: `030-homelab-ai-skills`

**Created**: 2026-10-27

**Status**: Draft

**Input**: User description: "Je souhaite pouvoir installer des skills IA sur le homelab NixOS avec des commandes `npx skills ...`. Est-ce la meilleure option ? Les skills sont-ils aussi disponibles de manière déclarative, par exemple ceux de Matt Pocock ou d'Addy Osmani ? Si les skills ne sont pas disponibles de manière déclarative, fais en sorte que je puisse utiliser `npm`, `npx`, `uv` et `uvx` sur `homelab`."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Declarative AI Agent Skills Across Hosts (Priority: P1)

As a developer using AI coding agents on `homelab` (and shared across `desktop-pc` and `macbook-air-m4-15`), I want curated AI agent skill collections—specifically those created by Matt Pocock and Addy Osmani—to be provisioned declaratively and version-pinned by the system configuration, so that these engineering skills are immediately available to OpenCode and other compatible AI agents out-of-the-box without manual installation steps or configuration drift across reboots.

**Why this priority**: In a declarative, immutable system with ephemeral root storage on `homelab`, declarative provisioning is the superior, primary method for baseline AI skills. Because AI skills follow the open `SKILL.md` standard (plain Markdown instructions inside skill directories) published in public Git repositories (`mattpocock/skills` and `addyosmani/agent-skills`), they can be locked, fetched, and linked declaratively into the global agent skill directories (`~/.config/opencode/skills` and `~/.agents/skills`), guaranteeing 100% reproducibility and zero manual maintenance.

**Independent Test**: Log into `homelab` (via SSH or the OpenCode web interface), inspect the global skill directories or query the available skills inside an OpenCode session, and verify that the skills from Matt Pocock and Addy Osmani are listed and loadable without running any manual installation commands.

**Acceptance Scenarios**:

1. **Given** a freshly deployed or rebooted `homelab` system, **When** a user starts an OpenCode session (via terminal or web UI), **Then** the skills from Matt Pocock (`mattpocock/skills`) and Addy Osmani (`addyosmani/agent-skills`) are automatically discovered and available for invocation.
2. **Given** the shared OpenCode configuration across `homelab`, `desktop-pc`, and `macbook-air-m4-15`, **When** the system configurations are applied, **Then** the declarative skill collections are provisioned consistently across all enabled hosts from a single pinned source of truth.
3. **Given** an update to the pinned repository versions during standard system lockfile maintenance, **When** the configuration is rebuilt and switched, **Then** all declarative skills are atomically updated to the new revision without leaving stale skill files behind.

---

### User Story 2 - Ad-Hoc Package & Skill Execution with `npm`, `npx`, `uv`, and `uvx` on Homelab (Priority: P2)

As a developer working interactively on `homelab` or running automated tasks through the OpenCode service, I want the Node.js (`npm`, `npx`) and Python (`uv`, `uvx`) package and tool runners installed and accessible on `homelab`, so that I can install ad-hoc project-level skills (e.g., `npx skills add ...`), run MCP servers, and execute standalone JavaScript/TypeScript or Python CLI utilities on demand.

**Why this priority**: Even with core skill packs provisioned declaratively, ecosystems around AI agents (the `npx skills` CLI for third-party or project-scoped skills, Model Context Protocol servers, and agent helper scripts) frequently rely on `npx` and `uvx` for on-demand execution. Providing both declarative skills and runtime tool runners delivers a complete, friction-free workflow on `homelab`.

**Independent Test**: Connect to `homelab` (and test within an OpenCode session), execute `npm --version`, `npx --version`, `uv --version`, and `uvx --version`, and run `npx skills --help` (or `npx skills add <repo> --list`) to confirm that all four commands execute cleanly and can fetch and run packages.

**Acceptance Scenarios**:

1. **Given** an interactive terminal session on `homelab` (in Fish or Bash), **When** the user runs `npm --version`, `npx --version`, `uv --version`, and `uvx --version`, **Then** all four commands succeed and return valid version information.
2. **Given** an active OpenCode session on `homelab` (via CLI or `opencode-web`), **When** the user or agent runs `npx skills ...` or `uvx ...` within a project workspace, **Then** the commands are found in the execution path and complete without missing binary or dynamic-linking errors.
3. **Given** `homelab`'s ephemeral root filesystem, **When** `npm`/`npx` or `uv`/`uvx` download packages or install user-scoped tools and the host reboots, **Then** preserved user state and caches (or global user-installed skills in `~/.agents`) behave predictably without breaking subsequent executions.

---

### User Story 3 - Architectural Guidance & Living Documentation Synchronization (Priority: P3)

As the maintainer of this configuration repository, I want clear documentation in `README.md` explaining the hybrid AI skills architecture (declarative provisioning for baseline skill packs vs. `npx skills` / `uvx` for ad-hoc or project-local tooling) with both Bash and Fish command examples, so that future maintenance and usage across hosts remain transparent and reproducible.

**Why this priority**: Directly answers the architectural question posed in the feature request and fulfills the repository's governance requirement that `README.md` remain synchronized with all host capabilities and provide dual Bash/Fish command variants.

**Independent Test**: Review `README.md` and run all repository quality gates (`just fmt`, `just lint`, `just check`) to verify that documentation is complete, accurate, and compliant with formatting and linting standards.

**Acceptance Scenarios**:

1. **Given** `README.md`, **When** a reader inspects the `homelab` and OpenCode sections, **Then** it documents the declaratively provisioned skill packs (Matt Pocock and Addy Osmani) as well as the availability of `npm`, `npx`, `uv`, and `uvx` for on-demand workflows, with Bash and Fish examples where syntax differs.
2. **Given** the complete set of changes in the feature branch, **When** running `just check`, **Then** all flake checks, static analysis, and host evaluations pass with exit code 0.

---

### Edge Cases

- **Coexistence of Declarative and Imperative Skills**: What happens if a user runs `npx skills add ...` globally while declarative skills are also managed by the system? By linking each declarative skill directory individually (or scoping declarative skills cleanly inside `~/.config/opencode/skills`) while preserving `~/.agents` on persistent storage, declarative skills remain immutable and managed by the system without blocking project-local (`.agents/skills/` or `.opencode/skills/`) or additional user-installed skills.
- **Name Collisions Between Skill Repositories**: What happens if two skill repositories (e.g., `mattpocock/skills` and `addyosmani/agent-skills`) define a skill folder with the same name (such as `tdd`)? The declarative skill loader must handle or namespace colliding skill directory names deterministically so both repositories can coexist without build failure or silent overwrites.
- **Headless Service Execution Environment (`opencode-web`)**: What happens when an agent running inside the `opencode-web` background service attempts to invoke `npm`, `npx`, `uv`, or `uvx`? The systemd service `path` for `opencode-web` must explicitly include the Node.js and `uv` packages so background web sessions have identical tool access to interactive SSH sessions.
- **Ephemeral Root Filesystem on Homelab**: What happens to user-level skills installed via `npx skills add -g` or `uv tool install` after `homelab` reboots? Preserving `~/.agents` (and relevant user tool/cache directories if needed) in persistent storage ensures user-level additions are not unexpectedly wiped on reboot.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST declaratively provision the AI agent skills from Matt Pocock (`github:mattpocock/skills`) and Addy Osmani (`github:addyosmani/agent-skills`) as pinned inputs so they are reproducibly available to OpenCode across enabled hosts (`homelab`, `desktop-pc`, and `macbook-air-m4-15`).
- **FR-002**: System MUST resolve any skill directory name collisions between declarative skill repositories (for example, if both repositories contain a skill with the same folder name) so that all skills from both authors are accessible without conflict.
- **FR-003**: System MUST provide `npm` and `npx` (via Node.js) as well as `uv` and `uvx` in the system environment on `homelab` (and shared across hosts where appropriate) so interactive shell users can run `npx skills ...`, `npm ...`, `uv ...`, and `uvx ...` commands directly.
- **FR-004**: System MUST include `npm`, `npx`, `uv`, and `uvx` in the execution path of the `opencode-web` background service on `homelab` so browser-based AI agent sessions can execute Node.js and Python package runners seamlessly.
- **FR-005**: System MUST configure persistent storage on `homelab` (`core.preservation`) to preserve user-level agent skill directories (`~/.agents`) across reboots alongside existing OpenCode state.
- **FR-006**: System MUST update `README.md` to document both the declarative AI skills setup (Matt Pocock and Addy Osmani) and the availability of `npm`, `npx`, `uv`, and `uvx` on `homelab`, providing explicit Bash and Fish command variants where shell syntax differs.
- **FR-007**: All configuration changes MUST pass repository formatting (`just fmt`), linting (`just lint`), and flake verification (`just check`) with zero errors or warnings.

### Key Entities

- **Declarative Skill Pack**: A version-pinned upstream repository of `SKILL.md` definitions (`mattpocock/skills`, `addyosmani/agent-skills`) fetched and linked into the user's OpenCode skill directory during system activation.
- **Package & Tool Runners (`npm`, `npx`, `uv`, `uvx`)**: Command-line execution engines for Node.js and Python packages that enable on-demand execution of `npx skills`, MCP servers, and standalone developer scripts on `homelab`.
- **Persistent Agent Directory (`~/.agents`)**: The cross-agent user directory preserved across reboots on ephemeral-root hosts to store any ad-hoc global skills or agent state installed outside declarative Nix store links.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of skills published in the pinned `mattpocock/skills` and `addyosmani/agent-skills` repositories are automatically discoverable by OpenCode on `homelab` immediately after system deployment without manual CLI commands.
- **SC-002**: Users and OpenCode agent sessions on `homelab` can execute `npm`, `npx`, `uv`, and `uvx` commands (including `npx skills --help`) with a 100% success rate in both interactive shells (Fish and Bash) and the `opencode-web` service.
- **SC-003**: 100% of declaratively configured skills and persistent `~/.agents` directories survive `homelab` reboots without data loss or manual re-installation.
- **SC-004**: 100% of repository quality gates (`just fmt`, `just lint`, `just check`) and host evaluations (`homelab`, `desktop-pc`, `macbook-air-m4-15`, `iso`) succeed with exit code 0.

## Assumptions

- **Answer to "Is `npx skills ...` the best option?"**: On NixOS, a **hybrid approach** is the best option:
  1. **Declarative provisioning (Best for core/global skills)**: Because AI skills are standard Markdown files (`SKILL.md`), foundational skill collections like Matt Pocock's (`github:mattpocock/skills`) and Addy Osmani's (`github:addyosmani/agent-skills`) are best managed declaratively as pinned flake inputs and linked into OpenCode's skills directory. This respects NixOS's hermetic philosophy, survives ephemeral-root reboots automatically, shares skills across `homelab`, `desktop-pc`, and `macbook-air-m4-15`, and updates cleanly via `nix flake update`.
  2. **Runtime runners `npm`, `npx`, `uv`, `uvx` (Best for ad-hoc/project skills & MCP tools)**: Having `npm`/`npx` and `uv`/`uvx` installed on `homelab` remains essential for testing third-party skills on the fly (`npx skills add ...`), installing project-scoped skills into a git working tree, and running Python/Node.js MCP servers and CLI tools.
- Providing both the declarative skills (Matt Pocock + Addy Osmani) **and** the CLI tool runners (`npm`, `npx`, `uv`, `uvx`) on `homelab` fulfills both parts of the user's request and provides the most capable setup.
- In `mattpocock/skills` and `addyosmani/agent-skills`, each skill is a subdirectory containing a `SKILL.md` file (with YAML frontmatter). If both repositories contain a skill folder with the same name (or if `SKILL.md` frontmatter `name` requires matching directory names), the module can link or merge them cleanly during derivation build.
