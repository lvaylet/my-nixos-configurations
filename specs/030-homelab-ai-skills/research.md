# Research: AI Skills Provisioning and Package Runners on Homelab

**Feature**: `030-homelab-ai-skills`
**Date**: 2026-10-27

## 1. Declarative vs. Imperative (`npx skills`) AI Skills Management on NixOS

### Decision
Adopt a **hybrid architecture**:
1. **Declarative provisioning via Nix flake inputs** (`github:mattpocock/skills` and `github:addyosmani/agent-skills`) for global, foundational engineering skills across `homelab`, `desktop-pc`, and `macbook-air-m4-15`.
2. **Runtime CLI package runners (`nodejs` providing `npm`/`npx`, and `uv` providing `uv`/`uvx`)** installed in the system environment and `opencode-web` service `path` for ad-hoc or project-local skill installation (`npx skills add ...`), MCP server execution, and Python/Node.js CLI tooling.

### Rationale
- **Why declarative is best for core skills**: AI agent skills follow the open `SKILL.md` standard (plain Markdown files with YAML frontmatter `name` and `description`). On NixOS—and especially on `homelab`, which uses an ephemeral `tmpfs` root filesystem (`core.preservation`) and disables Home Manager (`enableHomeManager = false`)—declaring Matt Pocock's and Addy Osmani's skill repositories as pinned flake inputs guarantees:
  - **Total reproducibility**: Skills are version-pinned in `flake.lock` and updated atomically via `nix flake update`.
  - **Multi-host consistency**: The exact same skill bundle is shared across `homelab`, `desktop-pc`, and `macbook-air-m4-15` from `modules/services/opencode.nix`.
  - **Zero reboot drift**: Declarative symlinks under `~/.config/opencode/skills` are recreated automatically on boot via `systemd.tmpfiles.rules` (on `homelab`) and `xdg.configFile` (on Home Manager hosts).
- **Why `npm`, `npx`, `uv`, and `uvx` are still essential**: Even with declarative global skills, developers and OpenCode sessions frequently need `npx skills add <owner/repo>` to install project-scoped skills into a repository's `.opencode/skills/` or `.agents/skills/`, or `npx` / `uvx` to run Model Context Protocol (MCP) servers and one-off CLI tools.

### Alternatives Considered
- **Imperative `npx skills` only**: Rejected as the sole mechanism because global imperative installations drift across machines (`homelab`, `desktop-pc`, `macbook-air-m4-15`) and violate Principle I (Declarative & Hermetic Configuration) when a clean declarative source exists.
- **Declarative skills only (omitting `npm`/`npx`/`uv`/`uvx`)**: Rejected because the user explicitly requested `npm`, `npx`, `uv`, and `uvx` on `homelab` for ad-hoc skill and tool workflows.

## 2. Repository Structure & Collision Analysis for `mattpocock/skills` and `addyosmani/agent-skills`

### Findings
- **`github:addyosmani/agent-skills`**:
  - Contains **25 production skills** directly under `skills/<skill-name>/SKILL.md`:
    `api-and-interface-design`, `browser-testing-with-devtools`, `ci-cd-and-automation`, `code-review-and-quality`, `code-simplification`, `constraint-driven-development`, `context-engineering`, `debugging-and-error-recovery`, `deprecation-and-migration`, `documentation-and-adrs`, `doubt-driven-development`, `frontend-ui-engineering`, `git-workflow-and-versioning`, `idea-refine`, `incremental-implementation`, `interview-me`, `observability-and-instrumentation`, `performance-optimization`, `planning-and-task-breakdown`, `security-and-hardening`, `shipping-and-launch`, `source-driven-development`, `spec-driven-development`, `test-driven-development`, `using-agent-skills`.
  - Also contains a top-level `references/` directory (`accessibility-checklist.md`, `definition-of-done.md`, `observability-checklist.md`, `orchestration-patterns.md`, `performance-checklist.md`, `security-checklist.md`, `testing-patterns.md`) referenced by skills via relative paths (`../../references/...`).
- **`github:mattpocock/skills`**:
  - Groups skills by category subdirectories. Per its `.claude-plugin/plugin.json` manifest, the **27 official published skills** live under `skills/engineering/<skill-name>/SKILL.md` (20 skills) and `skills/productivity/<skill-name>/SKILL.md` (7 skills):
    - `skills/engineering/*`: `ask-matt`, `code-review`, `codebase-design`, `diagnosing-bugs`, `domain-modeling`, `grill-with-docs`, `implement`, `implement-spec`, `improve-codebase-architecture`, `pr`, `prototype`, `research`, `retro`, `setup-matt-pocock-skills`, `tdd`, `to-spec`, `to-tickets`, `triage`, `wayfinder`, `wizard`.
    - `skills/productivity/*`: `grill-me`, `grilling`, `handoff`, `teach`, `to-questionnaire`, `wait-what`, `writing-for-agents`.
  - Note: `skills/in-progress/*` and `skills/misc/*` are experimental/frozen drafts excluded from Matt Pocock's official plugin manifest.
- **Directory Name Collisions**:
  - Comparing all 25 skill names in `addyosmani/agent-skills` against all 27 published skill names (and even all 38 total folders) in `mattpocock/skills` shows **zero directory or skill name collisions** (e.g., `tdd` vs. `test-driven-development`, `code-review` vs. `code-review-and-quality`, `to-spec` vs. `spec-driven-development`).

### Decision
Build a unified Nix derivation (`opencodeSkillsDir`) using `pkgs.runCommandLocal "opencode-skills"` in `modules/services/opencode.nix` that:
1. Symlinks every skill directory under `${inputs.addyosmani-agent-skills}/skills/*` into `$out/<skill-name>`.
2. Symlinks every skill directory under `${inputs.mattpocock-skills}/skills/engineering/*` and `${inputs.mattpocock-skills}/skills/productivity/*` into `$out/<skill-name>` (checking for any future collision and failing loudly or namespacing if an upstream rename ever collides).
3. Symlinks `$out/<skill-name>` directly to the upstream Nix store directory `${inputs.addyosmani-agent-skills}/skills/<skill-name>` so that relative links like `../../references/testing-patterns.md` resolve naturally within `${inputs.addyosmani-agent-skills}/references/`!
4. Pass `opencodeSkillsDir` to:
   - `systemd.tmpfiles.rules` on NixOS (`L+ /home/${vars.userName}/.config/opencode/skills - - - - ${opencodeSkillsDir}`)
   - `programs.opencode.skills = opencodeSkillsDir;` on Home Manager (`desktop-pc` and `macbook-air-m4-15`).

## 3. Provisioning `npm`, `npx`, `uv`, and `uvx` on `homelab`

### Findings
- In `nixpkgs` (`nixos-unstable`):
  - `pkgs.nodejs` provides `node`, `npm`, `npx`, and `corepack` in `$out/bin`.
  - `pkgs.uv` provides both `uv` and `uvx` in `$out/bin`.
- `homelab` already enables `services.nix-ld` (`programs.nix-ld.enable = true`), which allows unpatched dynamically linked binaries downloaded by `npx`, `npm`, or `uv`/`uvx` to execute transparently on NixOS.

### Decision
In `modules/services/opencode.nix`:
- Add `pkgs.nodejs` and `pkgs.uv` to `environment.systemPackages` in `nixos` and `darwin`.
- Add `pkgs.nodejs` and `pkgs.uv` to `systemd.services.opencode-web.path` in `nixos` so the headless web daemon on `homelab` has `node`, `npm`, `npx`, `uv`, and `uvx` directly in its service `PATH`.
- Add `pkgs.nodejs` and `pkgs.uv` to `programs.opencode.extraPackages` in `homeManager` so Home Manager-wrapped OpenCode instances also guarantee `npm`, `npx`, `uv`, and `uvx` in their runtime `PATH`.

## 4. Persistence of Ad-Hoc Agent Skills on `homelab`

### Decision
Add `".agents"` to `preservation.preserveAt."/persistent".users.${vars.userName}.directories` in `modules/services/opencode.nix`.

### Rationale
- When a user runs `npx skills add <repo> -g` (global user install), the `skills` CLI installs skills into `~/.agents/skills/<name>/SKILL.md` (which OpenCode natively scans alongside `~/.config/opencode/skills/<name>/SKILL.md`).
- Keeping `~/.config/opencode/skills` declaratively linked to `opencodeSkillsDir` while persisting `~/.agents` on `/persistent` allows declarative skills and imperative `npx skills` additions to coexist cleanly without overwriting one another or disappearing on reboot.
