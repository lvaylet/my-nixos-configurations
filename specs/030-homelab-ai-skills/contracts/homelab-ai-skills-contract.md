# Contract: AI Skills Provisioning and Package Runners on Homelab

**Feature**: `030-homelab-ai-skills`
**Date**: 2026-10-27

## 1. Flake Inputs Contract (`flake.nix`)

- `inputs.mattpocock-skills` MUST be declared with `url = "github:mattpocock/skills";` and `flake = false;`.
- `inputs.addyosmani-agent-skills` MUST be declared with `url = "github:addyosmani/agent-skills";` and `flake = false;`.
- Both inputs MUST be locked in `flake.lock`.

## 2. Host Configuration Evaluation Contract

### `nixosConfigurations.homelab`
- `config.environment.systemPackages` MUST include `opencode`, `nodejs` (`node`, `npm`, `npx`), and `uv` (`uv`, `uvx`).
- `config.systemd.tmpfiles.rules` MUST include a rule linking `/home/laurent/.config/opencode/skills` to the declarative `opencode-skills` store path containing all 27 Matt Pocock skills (`engineering` + `productivity`) and all 25 Addy Osmani skills.
- `config.systemd.services.opencode-web.path` MUST include `nodejs` and `uv` in addition to existing system and development tools.
- `config.preservation.preserveAt."/persistent".users.laurent.directories` MUST include `".agents"` alongside `".local/share/opencode"` and `".local/state/opencode"`.

### `nixosConfigurations.desktop-pc` & `darwinConfigurations.macbook-air-m4-15`
- `config.environment.systemPackages` MUST include `nodejs` and `uv`.
- `config.home-manager.users.laurent.xdg.configFile."opencode/skills".source` MUST point to the declarative `opencode-skills` store path.
- `config.home-manager.users.laurent.programs.opencode.extraPackages` MUST include `nodejs` and `uv`.

## 3. Runtime CLI & Skill Discovery Contract on `homelab`

From an interactive shell (Fish or Bash) or within an OpenCode session on `homelab`:

| Verification Target | Expected Behavior |
|---------------------|-------------------|
| `~/.config/opencode/skills/` | Symlink to `/nix/store/...-opencode-skills` containing both Matt Pocock's (`grill-me`, `grill-with-docs`, `tdd`, `to-spec`, `code-review`, etc.) and Addy Osmani's (`spec-driven-development`, `test-driven-development`, `code-review-and-quality`, `interview-me`, etc.) skill folders. |
| `npm --version` & `npx --version` | Succeeds with exit code `0` and prints the installed Node.js / npm version. |
| `uv --version` & `uvx --version` | Succeeds with exit code `0` and prints the installed `uv` version. |
| `npx -y skills --help` | Downloads/executes the `skills` CLI via `npx` with exit code `0`. |
