# Implementation Plan: AI Skills Provisioning and Package Runners on Homelab

**Branch**: `030-homelab-ai-skills` | **Date**: 2026-10-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/030-homelab-ai-skills/spec.md`

## Summary

Implement a hybrid AI agent skills and package runner setup on `homelab` (and shared across `desktop-pc` and `macbook-air-m4-15`):
1. **Declarative AI Skills Provisioning**: Pin Matt Pocock's (`github:mattpocock/skills`) and Addy Osmani's (`github:addyosmani/agent-skills`) skill repositories as non-flake inputs in `flake.nix` and assemble their 52 curated `SKILL.md` directories in `modules/services/opencode.nix`. Provision them declaratively via `systemd.tmpfiles.rules` (`L+ /home/${vars.userName}/.config/opencode/skills`) on headless `homelab` (`enableHomeManager = false`) and via `xdg.configFile."opencode/skills"` on Home Manager hosts (`desktop-pc` and `macbook-air-m4-15`).
2. **Runtime Package & Tool Runners (`npm`, `npx`, `uv`, `uvx`)**: Provide `pkgs.nodejs` (`node`, `npm`, `npx`) and `pkgs.uv` (`uv`, `uvx`) in `modules/services/opencode.nix` (across system packages, `systemd.services.opencode-web.path` on `homelab`, and `programs.opencode.extraPackages` in Home Manager) so users and OpenCode sessions can execute `npx skills ...`, `uvx ...`, and MCP servers seamlessly.
3. **Ephemeral Root Persistence & Documentation**: Preserve `~/.agents` across reboots on `homelab` via `preservation.preserveAt."/persistent"` in `modules/services/opencode.nix`, and document both the declarative skills and `npm`/`npx`/`uv`/`uvx` workflows in `README.md` with Bash and Fish parity.

## Technical Context

**Language/Version**: Nix (Flakes, NixOS `nixos-unstable`, `nix-darwin`, Home Manager)
**Primary Dependencies**: `flake-parts`, `import-tree`, `opencode`, `nodejs` (`npm`, `npx`), `uv` (`uv`, `uvx`), `mattpocock-skills` (`github:mattpocock/skills`), `addyosmani-agent-skills` (`github:addyosmani/agent-skills`), `preservation`
**Storage**: Ephemeral `tmpfs` root on `homelab` with Btrfs persistence at `/persistent` via `preservation` (`~/.agents` persisted alongside `~/.local/share/opencode` and `~/.local/state/opencode`)
**Testing**: `nix flake check` (`just check`), `deadnix` & `statix check` (`just lint`), `alejandra` (`just fmt`), and host evaluations (`homelab`, `desktop-pc`, `macbook-air-m4-15`, `iso`)
**Target Platform**: `x86_64-linux` (NixOS: `homelab`, `desktop-pc`, `iso`) and `aarch64-darwin` (`macbook-air-m4-15`)
**Project Type**: Declarative OS & service configuration repository (Dendritic Pattern)
**Performance Goals**: Zero-overhead symlinked declarative skills available immediately at boot; instant CLI availability of `npm`, `npx`, `uv`, and `uvx` in both interactive shells and `opencode-web`
**Constraints**: Must keep `homelab` headless (`enableHomeManager = false`), preserve relative `../../references/*.md` paths inside `addyosmani/agent-skills` skill directories, and pass all sandbox pre-commit checks
**Scale/Scope**: `flake.nix`, `flake.lock`, `modules/services/opencode.nix`, and `README.md`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Declarative & Hermetic Configuration**: PASS — Upstream skill packs (`mattpocock/skills` and `addyosmani/agent-skills`) are pinned in `flake.lock` and linked declaratively from `/nix/store`, while `nodejs` and `uv` are declared via Nix packages and user-level `~/.agents` state is explicitly managed via `preservation`.
- **II. Dendritic Modularity & Feature-Centric Composition**: PASS — All OpenCode skills, `nodejs`/`uv` runtime dependencies, `opencode-web` service paths, and `~/.agents` persistence are colocated inside `modules/services/opencode.nix` across `nixos`, `homeManager`, and `darwin` aspects.
- **III. Shift-Left Quality, Formatting & Static Analysis**: PASS — All Nix expressions will be formatted with `alejandra` (`just fmt`) and validated with `deadnix`, `statix check` (`just lint`), and `nix flake check` (`just check`).
- **IV. Zero-Secrets Leakage & Security First**: PASS — No secrets, tokens, or credentials are added to version control.
- **V. Rigorous Verification & Safe Deployment Workflow**: PASS — Changes will be verified via flake evaluation and `just check` before deployment.
- **VI. Living Documentation & Dual-Shell Parity**: PASS — `README.md` will be updated to document the declarative skills and `npm`/`npx`/`uv`/`uvx` capabilities with explicit Bash and Fish examples where syntax differs.
- **VII. Dedicated Branch & Pull Request Workflow**: PASS — Work takes place on the dedicated `030-homelab-ai-skills` branch for PR submission.

## Project Structure

### Documentation (this feature)

```text
specs/030-homelab-ai-skills/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── homelab-ai-skills-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
flake.nix                        # Add mattpocock-skills and addyosmani-agent-skills (flake = false) inputs
flake.lock                       # Lock pinned revisions of both skill repositories
modules/
└── services/
    └── opencode.nix             # Declarative skills bundle, nodejs + uv packages, opencode-web path, and ~/.agents preservation
README.md                        # Document declarative skills (Matt Pocock & Addy Osmani) and npm/npx/uv/uvx on homelab
```

**Structure Decision**: Colocate all AI skills provisioning, `nodejs`/`uv` package runners, `opencode-web` service path additions, and `~/.agents` state preservation inside the existing `modules/services/opencode.nix` module in accordance with the Dendritic Pattern.

## Complexity Tracking

> No Constitution Check violations.
