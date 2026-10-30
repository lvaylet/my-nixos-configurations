# Technical Research: Migrate SSH Settings from Deprecated MatchBlocks

**Branch**: `009-migrate-ssh-settings` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

This document consolidates technical research, architectural decisions, option mappings, and validation procedures for migrating the user SSH configuration from `programs.ssh.matchBlocks` to `programs.ssh.settings` within the dendritic NixOS configuration.

---

## 1. Upstream Home Manager Deprecation & Options Migration

### Decision

Migrate the Home Manager SSH host configuration in `modules/services/ssh.nix` from `programs.ssh.matchBlocks` to `programs.ssh.settings`.

### Rationale

- **Eliminate Evaluation Warning**: In recent versions of Home Manager, `programs.ssh.matchBlocks` was marked deprecated in favor of `programs.ssh.settings`. Whenever `cfg.matchBlocks != { }`, Home Manager emits:

  ```text
  evaluation warning: <user> profile: `programs.ssh.matchBlocks` defined in `<path>' is deprecated. Use `programs.ssh.settings`.
  ```

  Transitioning to `programs.ssh.settings` fully eliminates this warning across all flake evaluation and build commands.
- **Future-Proofing**: Deprecated options in Home Manager are scheduled for removal in subsequent releases. Migrating now ensures continuous evaluation stability without emergency fixes when upstream bumps occur.
- **Flexible DAG Configuration**: `programs.ssh.settings` uses a DAG (Directed Acyclic Graph) of submodules with freeform attribute sets, providing first-class OpenSSH directive emission and predictable block ordering.

### Alternatives Considered

- **Suppressing Warnings via Nix Flags**: Passing `--show-trace` or attempting to suppress evaluation warnings hides actionable diagnostics, violates repository Constitution Principle III (Shift-Left Quality), and fails when the deprecated option is eventually removed upstream.
- **Raw String Injection via `extraConfig`**: Inlining SSH blocks into `programs.ssh.extraConfig` loses structured Nix typing, prevents programmatic overrides, and makes configuration maintenance more brittle.

---

## 2. Option Schema & Directive Name Mapping

### Decision

Use bare host alias keys under `programs.ssh.settings` with canonical OpenSSH PascalCase directive names:

```nix
programs.ssh = {
  enable = true;
  enableDefaultConfig = false;
  settings = {
    "rpi3" = {
      HostName = "192.168.1.68";
      User = "pi";
      IdentityFile = "~/.ssh/id_ed25519";
      CheckHostIP = false;
    };
    "homelab-vm" = {
      HostName = "192.168.1.194";
      User = "core";
      IdentityFile = "~/.ssh/id_ed25519";
      CheckHostIP = false;
    };
  };
};
```

### Rationale

- **Header Derivation**: In Home Manager's `programs.ssh.settings`, attribute keys that do not begin with `"Host "` or `"Match "` automatically have `"Host "` prepended by the internal `blockHeader` helper. Thus, bare keys `"rpi3"` and `"homelab-vm"` generate `Host rpi3` and `Host homelab-vm` headers identically to the legacy `matchBlocks` implementation.
- **Upstream OpenSSH Directives**: `programs.ssh.settings` is a freeform attribute set where attribute names are emitted directly as OpenSSH configuration directives. The legacy options map directly as follows:
  - `hostname` → `HostName`
  - `user` → `User`
  - `identityFile` → `IdentityFile`
  - `checkHostIP = false;` → `CheckHostIP = false;` (rendered as `CheckHostIP no` by Home Manager's boolean formatter `lib.hm.booleans.yesNo`)
- **Direct Parity with `legacyBlockSettings`**: Home Manager's own internal fallback function (`legacyBlockSettings`) converts legacy `matchBlocks` fields to exactly these PascalCase directive names. Adopting them directly ensures zero divergence in the resulting `~/.ssh/config` file.

### Alternatives Considered

- **Explicit Header Keys (e.g. `"Host rpi3"` vs `"rpi3"`)**: While `"Host rpi3"` is valid syntax, bare alias names are more concise, idiomatic in Home Manager, and match the existing codebase pattern.
- **Lowercase or CamelCase Attributes**: OpenSSH directives are case-insensitive in parsing, but Home Manager prints attribute names verbatim. Using standard OpenSSH PascalCase (`HostName`, `User`, `IdentityFile`, `CheckHostIP`) guarantees standard readability and consistency with OpenSSH documentation.

---

## 3. Interaction with Baseline Settings (`enableDefaultConfig`)

### Decision

Retain `enableDefaultConfig = false;` alongside `programs.ssh.settings`.

### Rationale

- When `enableDefaultConfig = true` (Home Manager's default), Home Manager synthesizes a `Host *` block configuring default settings (such as `ServerAliveInterval`, `HashKnownHosts`, and `ControlMaster`).
- The current user configuration explicitly opted out of these defaults by setting `enableDefaultConfig = false`.
- Retaining `enableDefaultConfig = false` preserves the exact baseline behavior without unexpected defaults injected into the user's `~/.ssh/config`.

---

## 4. Verification & Diagnostic Strategy

### Decision

Validate the change using a three-tier verification process:

1. **Flake Evaluation Diagnostics**: Run `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath` to verify that evaluation succeeds and zero deprecation warnings are emitted.
2. **Configuration Output Diffing**: Query `nix eval --raw .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.home.file.".ssh/config".text` to inspect the generated SSH configuration and verify complete directive equivalence for `rpi3` and `homelab-vm`.
3. **Repository Quality Gates**: Execute `just check` (`nix flake check`) and `just lint` (`statix`, `deadnix`) to ensure the updated Nix expressions format cleanly with `alejandra` and satisfy all pre-commit sandbox checks with exit code 0.
