# Quickstart & Validation Guide: AI Skills Provisioning and Package Runners on Homelab

**Feature**: `030-homelab-ai-skills`
**Date**: 2026-10-27

## Prerequisites

- Repository checked out on branch `030-homelab-ai-skills`.
- Access to a Nix environment with flakes enabled.

## 1. Verify Flake Inputs & Host Evaluations

Verify that the declarative skill derivation builds and that `homelab`, `desktop-pc`, and `macbook-air-m4-15` evaluate cleanly with the new skills and package runners:

**Bash / Fish**:

```bash
nix eval .#nixosConfigurations.homelab.config.systemd.tmpfiles.rules --json
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.xdg.configFile.\"opencode/skills\".source
nix eval .#darwinConfigurations.macbook-air-m4-15.config.home-manager.users.laurent.xdg.configFile.\"opencode/skills\".source
```

## 2. Run Repository Quality Gates

**Bash / Fish**:

```bash
just fmt
just lint
just check
```

Expected outcome: All formatting, static analysis (`deadnix`, `statix`), and `nix flake check` pre-commit hooks succeed with exit code `0`.

## 3. Deploy and Verify on `homelab`

Test and switch the configuration on `homelab`:

**Bash / Fish**:

```bash
just test
just switch
```

Verify that the declarative skills and CLI runners (`npm`, `npx`, `uv`, `uvx`) are available on `homelab`:

**Bash / Fish**:

```bash
ls -la ~/.config/opencode/skills/
npm --version
npx --version
uv --version
uvx --version
```

## 4. Using Declarative Skills vs. Ad-Hoc `npx skills`

- **Declarative Global Skills (Matt Pocock & Addy Osmani)**: Available immediately in every OpenCode session via `~/.config/opencode/skills/` without running any install command. To update all declarative skills to their latest upstream commits:
  **Bash / Fish**:

  ```bash
  nix flake update mattpocock-skills addyosmani-agent-skills
  just switch
  ```

- **Ad-Hoc Project or Global Skills via `npx skills`**: Use `npx skills` whenever you want to browse or install an additional third-party skill into a project workspace (or globally into `~/.agents/skills/`, which is persisted across reboots on `homelab`):
  **Bash / Fish**:

  ```bash
  npx skills add <owner/repo> --list
  ```
