# Data Model: AI Skills Provisioning and Package Runners on Homelab

**Feature**: `030-homelab-ai-skills`
**Date**: 2026-10-27

## Entities & Configuration Modules

### 1. Pinned Upstream Skill Flake Inputs (`flake.nix`)

| Input Name | Source URL | Flake Attribute | Description |
|------------|------------|-----------------|-------------|
| `mattpocock-skills` | `github:mattpocock/skills` | `flake = false;` | Matt Pocock's official engineering (`skills/engineering/*`) and productivity (`skills/productivity/*`) agent skills (27 skills). |
| `addyosmani-agent-skills` | `github:addyosmani/agent-skills` | `flake = false;` | Addy Osmani's production-grade software engineering lifecycle skills (`skills/*`, 25 skills) and shared `references/`. |

### 2. Unified Declarative Skills Derivation (`modules/services/opencode.nix`)

| Entity | Type | Structure | Validation Rules |
|--------|------|-----------|------------------|
| `opencodeSkillsDir` | Nix derivation (`pkgs.runCommandLocal "opencode-skills"`) | Directory containing one symlink per skill (`$out/<skill-name>`) pointing to its upstream directory containing `SKILL.md`, plus `$out/references` pointing to `${inputs.addyosmani-agent-skills}/references`. | Every linked skill directory MUST contain a valid `SKILL.md` file; build MUST fail if duplicate skill directory names collide unexpectedly. |

### 3. OpenCode Service & Multi-Host Provisioning (`modules/services/opencode.nix`)

| Attribute / Option | Platform Scope | Value / Contents | Purpose |
|--------------------|----------------|------------------|---------|
| `environment.systemPackages` | `nixos`, `darwin` | `opencodePackage`, `pkgs.nodejs`, `pkgs.uv` | Provides `opencode`, `node`, `npm`, `npx`, `uv`, and `uvx` in interactive shells on `homelab`, `desktop-pc`, and `macbook-air-m4-15`. |
| `systemd.tmpfiles.rules` | `nixos` (`homelab`) | `L+ /home/${vars.userName}/.config/opencode/skills - - - - ${opencodeSkillsDir}` (gated by `!config ? home-manager` or applied cleanly alongside `opencode.json`) | Symlinks the declarative skills bundle on headless NixOS hosts (`homelab`) where Home Manager is disabled. |
| `systemd.services.opencode-web.path` | `nixos` (`homelab`) | Existing tools + `pkgs.nodejs`, `pkgs.uv` | Exposes `node`, `npm`, `npx`, `uv`, and `uvx` to browser-based OpenCode sessions on `homelab`. |
| `preservation.preserveAt."/persistent".users.${vars.userName}.directories` | `nixos` (`homelab`) | `".agents"`, `".local/share/opencode"`, `".local/state/opencode"` | Persists user-installed `~/.agents` skills across ephemeral root reboots on `homelab`. |
| `xdg.configFile."opencode/skills"` | `homeManager` (`desktop-pc`, `macbook-air-m4-15`) | `{ source = opencodeSkillsDir; recursive = true; }` | Provisions the declarative skills bundle in `~/.config/opencode/skills` on Home Manager hosts. |
| `programs.opencode.extraPackages` | `homeManager` (`desktop-pc`, `macbook-air-m4-15`) | `[ pkgs.nodejs pkgs.uv ]` | Ensures `npm`, `npx`, `uv`, and `uvx` are wrapped into the OpenCode binary `PATH` on Home Manager hosts. |

## State & Skill Discovery Hierarchy in OpenCode

1. **Declarative Global Skills (`~/.config/opencode/skills/<name>/SKILL.md`)**:
   - Managed immutably by Nix (`opencodeSkillsDir`).
   - Contains all 52 skills from Matt Pocock and Addy Osmani.
   - Automatically updated whenever `nix flake update` updates `flake.lock` and the host configuration is switched.
2. **User-Installed Global Skills (`~/.agents/skills/<name>/SKILL.md`)**:
   - Mutable directory persisted in `/persistent/home/${vars.userName}/.agents` on `homelab`.
   - Populated if the user runs `npx skills add <owner/repo> -g` at runtime.
3. **Project-Scoped Skills (`.opencode/skills/<name>/SKILL.md` or `.agents/skills/<name>/SKILL.md`)**:
   - Stored inside individual git repositories under `~/workspace/...`.
   - Populated when the user runs `npx skills add <owner/repo>` inside a project directory.
