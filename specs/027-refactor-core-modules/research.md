# Research: Refactor Core Modules, Bootloaders, Shell Abbreviations, and SSH Identity

**Feature**: `027-refactor-core-modules`
**Date**: 2026-10-26

## Decision 1: Modular Bootloader Extraction (`modules/core/bootloader.nix`)

- **Decision**: Extract bootloader configurations from `modules/core/base.nix` and `modules/hosts/homelab.nix` into a dedicated dendritic module file `modules/core/bootloader.nix` exposing `flake.modules.core.limine` and `flake.modules.core.grub`. Enable `core.limine` in `modules/hosts/desktop-pc.nix` and `core.grub` in `modules/hosts/homelab.nix`.
- **Rationale**:
  - Directly resolves Issue #36 item 2 ("`core.base` forces `boot.loader.limine.enable = true;`, requiring any non-Limine machine (`homelab`) to override it with `lib.mkForce false` to use GRUB. Bootloaders should be factored into modular features or configured per host.")
  - Aligns strictly with Constitutional Principle II (Dendritic Modularity & Feature-Centric Composition): `import-tree ./modules` automatically discovers `modules/core/bootloader.nix`, and host files (`desktop-pc.nix`, `homelab.nix`) declare their bootloader cleanly in their `features` list without inline `boot.loader` definitions or `lib.mkForce` overrides.
- **Alternatives Considered**:
  - *Keep `boot.loader` inline inside each host's `extraModules`*: Rejected because Constitutional Principle II discourages inline service/subsystem blocks in `modules/hosts/*.nix` when reusable feature modules under `modules/core/` can express them declaratively.
  - *Separate `limine.nix` and `grub.nix` files*: Colocating `core.limine` and `core.grub` in `modules/core/bootloader.nix` keeps `modules/core/` concise while exposing independent `core.limine` and `core.grub` feature attributes.

## Decision 2: Shared Shell Shortcuts and Native `programs.fish.shellAbbrs`

- **Decision**: Factor `systemdAliases` and `gitAliases` into a top-level `let` block in `modules/core/base.nix`. On `nixos`, set both `environment.shellAliases = systemdAliases // gitAliases;` and `programs.fish.shellAbbrs = systemdAliases // gitAliases;`. On `darwin`, set both `environment.shellAliases = gitAliases;` and `programs.fish.shellAbbrs = gitAliases;`. Remove the 42-line `complete -c ... -w ...` `interactiveShellInit` block from `modules/core/base.nix`.
- **Rationale**:
  - Both NixOS (`nixos/modules/programs/fish.nix`) and `nix-darwin` support `programs.fish.shellAbbrs` (`attrsOf str`), generating `abbr -a <name> -- <expansion>` in `/etc/fish/config.fish` (validated via `fish_indent`, including abbreviations containing `!` like `gc!`, `gca!`, `gcan!`).
  - Native Fish abbreviations expand inline on `<Space>` or `<Enter>`, automatically providing full native command and argument completions for `systemctl`, `journalctl`, and `git` without manual `complete -c` wrappers.
  - Retaining `environment.shellAliases` preserves full alias availability in Bash (used by `root` on NixOS and non-Fish shells), satisfying Constitutional Principle VI (Dual-Shell Parity).
- **Alternatives Considered**:
  - *Configure abbreviations via Home Manager (`programs.fish.shellAbbrs`)*: Rejected because `homelab` sets `enableHomeManager = false;` and relies on system-level `programs.fish` in `core.base`. Configuring `programs.fish.shellAbbrs` in `core.base` (`nixos` and `darwin`) covers all hosts (`desktop-pc`, `homelab`, `macbook-air-m4-15`) uniformly.

## Decision 3: Centralized User Identity in `modules/services/ssh.nix`

- **Decision**: Update `modules/services/ssh.nix` `homeManager` module signature from `_:` to `{vars, ...}:` and replace `User = "laurent";` with `User = vars.userName;`.
- **Rationale**:
  - Both `mkHost` and `mkDarwinHost` in `modules/core/lib.nix` pass `vars = config.flake.vars` via `home-manager.extraSpecialArgs`.
  - Satisfies Issue #36 item 1 and Constitutional Principle II (`config.flake.vars` as single source of truth for user identity).
- **Alternatives Considered**: None; direct replacement with `vars.userName` is standard across all other modules (`modules/core/git.nix`, `modules/core/base.nix`).
