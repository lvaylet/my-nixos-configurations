# Feature Specification: Refactor Core Modules, Bootloaders, Shell Abbreviations, and SSH Identity

**Feature Branch**: `027-refactor-core-modules`

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "Travaille sur https://github.com/lvaylet/my-nixos-configurations/issues/36. Avance de manière autonome sur les étapes "/speckit.plan", "/speckit.tasks" puis "/speckit.implement" si aucune intervention de ma part n'est nécessaire, par exemple pour clarifier ou analyser tes propositions. Après la phase d'implémentation, crée une Pull Request dédiée. Je la validerai manuellement."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Decouple Bootloaders into Modular Features (Priority: P1)

As a system maintainer, I want bootloader configurations (Limine and GRUB 2) decoupled from the shared base system module (`core.base`) into modular core features so that hosts can select their bootloader declaratively without forcing overrides (`lib.mkForce false`) on non-Limine machines.

**Why this priority**: Coupling Limine directly inside `core.base` violates dendritic modularity by forcing every NixOS host to inherit desktop-specific Limine settings (including Windows 11 dual-boot entries and artwork wallpapers) and requiring `homelab` to override `boot.loader.limine.enable` and `boot.loader.efi.canTouchEfiVariables` using `lib.mkForce`.

**Independent Test**: Can be independently tested by evaluating the `desktop-pc` and `homelab` NixOS configurations to verify that `desktop-pc` enables Limine via its feature list, `homelab` enables GRUB 2 via its feature list without `lib.mkForce` overrides, and `core.base` contains zero `boot.loader` definitions.

**Acceptance Scenarios**:

1. **Given** `modules/core/base.nix`, **When** a maintainer inspects `core.base`, **Then** no `boot.loader` settings are defined in `core.base`.
2. **Given** `desktop-pc`, **When** its NixOS configuration is evaluated, **Then** `boot.loader.limine.enable` is `true`, `boot.loader.efi.canTouchEfiVariables` is `true`, and all existing Limine settings (maxGenerations, `remember_last_entry`, Windows 11 entry, and NixOS artwork wallpapers) remain intact.
3. **Given** `homelab`, **When** its NixOS configuration is evaluated, **Then** `boot.loader.grub.enable` is `true`, `boot.loader.limine.enable` is `false` by default without `lib.mkForce`, and `homelab.nix` selects its bootloader through modular features rather than inline `extraModules` overrides.

---

### User Story 2 - Deduplicate Shell Shortcuts and Use Native Fish Abbreviations (Priority: P2)

As an operator working across NixOS (`desktop-pc`, `homelab`) and macOS (`macbook-air-m4-15`), I want shared shell shortcuts defined without duplication across platforms and registered as native Fish abbreviations (`programs.fish.shellAbbrs`) so that interactive Fish sessions expand shortcuts inline and provide full native argument autocompletion without manual `complete -c` wrapper scripts.

**Why this priority**: `modules/core/base.nix` currently duplicates ~42 lines of Git aliases between NixOS and Darwin and maintains ~45 lines of manual `complete -c ... -w ...` wrapper commands in `programs.fish.interactiveShellInit`. Using a single shared definition and native `programs.fish.shellAbbrs` eliminates ~85 lines of redundant boilerplate while providing superior interactive command expansion and native completion in Fish across both Linux and macOS.

**Independent Test**: Can be independently tested by evaluating both NixOS (`desktop-pc`, `homelab`) and Darwin (`macbook-air-m4-15`) configurations to verify that `programs.fish.shellAbbrs` and `environment.shellAliases` contain the expected shortcuts, `programs.fish.interactiveShellInit` in `core.base` no longer contains manual `complete -c` lines, and Git shortcuts are defined only once in `modules/core/base.nix`.

**Acceptance Scenarios**:

1. **Given** `modules/core/base.nix`, **When** inspecting the alias/abbreviation definitions, **Then** Git shortcuts are declared once in a shared binding and reused across both `nixos` and `darwin` targets without duplication.
2. **Given** any NixOS or Darwin host enabling `core.base`, **When** evaluating `programs.fish.shellAbbrs`, **Then** all platform-appropriate shortcuts (`systemctl`, `journalctl`, and `git` on NixOS; `git` on Darwin) are registered as native Fish abbreviations and zero manual `complete -c` lines remain in `core.base`.
3. **Given** Bash sessions (such as `root` on NixOS or non-Fish scripts), **When** evaluating `environment.shellAliases`, **Then** all shared `systemctl`, `journalctl`, and `git` aliases remain available for dual-shell parity.

---

### User Story 3 - Reference Centralized User Identity in SSH Client Configuration (Priority: P3)

As a system maintainer, I want the SSH client configuration in `modules/services/ssh.nix` to reference the centralized `vars.userName` option instead of a hardcoded `"laurent"` string so that all identity properties follow the repository's single source of truth.

**Why this priority**: Hardcoding `"laurent"` in `modules/services/ssh.nix` violates Constitutional Principle II (Dendritic Modularity & Feature-Centric Composition), which mandates that shared identity parameters be consumed from `config.flake.vars` (`vars.userName`).

**Independent Test**: Can be independently tested by inspecting `modules/services/ssh.nix` and evaluating the Home Manager SSH configuration on `desktop-pc` and `macbook-air-m4-15` to confirm `programs.ssh.settings.homelab.User` resolves dynamically from `vars.userName`.

**Acceptance Scenarios**:

1. **Given** `modules/services/ssh.nix`, **When** inspecting the `homelab` host entry under `programs.ssh.settings`, **Then** `User` is set to `vars.userName` with no hardcoded username literal.
2. **Given** `desktop-pc` and `macbook-air-m4-15`, **When** evaluating their Home Manager configurations, **Then** `programs.ssh.settings.homelab.User` evaluates to `"laurent"` via `vars.userName`.

---

### Edge Cases

- What happens to Bash users (such as `root` on `homelab` or `desktop-pc`) when Fish switches to `programs.fish.shellAbbrs`? Retaining `environment.shellAliases` alongside `programs.fish.shellAbbrs` ensures Bash continues to have all `systemctl`, `journalctl`, and `git` aliases while Fish users get interactive abbreviation expansion and native argument completions.
- What happens to Git shortcuts containing special characters such as `gc!`, `gca!`, and `gcan!` in `programs.fish.shellAbbrs`? NixOS and `nix-darwin` generate valid `abbr -a` entries formatted via `fish_indent`, supporting `!` in abbreviation names cleanly.
- What happens to the custom installer ISO (`iso`) when bootloaders are extracted from `core.base`? The `iso` host uses `core.iso` and `installation-cd-minimal.nix` directly and remains completely unaffected.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `modules/services/ssh.nix` MUST use `vars.userName` instead of the hardcoded `"laurent"` string for the `homelab` SSH host configuration in Home Manager.
- **FR-002**: `modules/core/base.nix` MUST NOT define `boot.loader` settings; bootloader configurations MUST be factored into modular core features (`core.limine` and `core.grub` in `modules/core/bootloader.nix`).
- **FR-003**: `modules/hosts/desktop-pc.nix` MUST enable `core.limine` in its `features` list, preserving the exact Limine configuration (EFI variable support, max 5 generations, `remember_last_entry: yes`, Windows 11 dual-boot entry, and NixOS artwork wallpapers).
- **FR-004**: `modules/hosts/homelab.nix` MUST enable `core.grub` in its `features` list and remove inline `boot.loader` overrides and `lib.mkForce` workarounds from `extraModules`, preserving its exact GRUB 2 EFI removable configuration.
- **FR-005**: `modules/core/base.nix` MUST factor shared shell shortcuts (`systemdAliases` and `gitAliases`) into top-level `let` bindings so Git shortcuts are defined once and shared between `nixos` and `darwin` without duplication.
- **FR-006**: `modules/core/base.nix` MUST configure `programs.fish.shellAbbrs` on both `nixos` (`systemdAliases // gitAliases`) and `darwin` (`gitAliases`) and remove the manual `complete -c` completion wrapper block from `programs.fish.interactiveShellInit`.
- **FR-007**: `modules/core/base.nix` MUST retain `environment.shellAliases` on `nixos` (`systemdAliases // gitAliases`) and `darwin` (`gitAliases`) to preserve dual-shell alias parity for Bash (`root`) and non-Fish shells.
- **FR-008**: `README.md` MUST be updated to reflect the native Fish abbreviations (`programs.fish.shellAbbrs`) and modular bootloader architecture in accordance with Constitutional Principle VI.
- **FR-009**: All Nix files and configurations MUST pass `just fmt`, `just lint`, `just check`, and host build/evaluation checks with zero errors or warnings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero hardcoded username literals (`"laurent"`) exist in `modules/services/ssh.nix`.
- **SC-002**: Zero `boot.loader` definitions remain in `modules/core/base.nix`, and zero `boot.loader` `lib.mkForce` overrides remain in `modules/hosts/homelab.nix`.
- **SC-003**: Duplicate Git alias definitions in `modules/core/base.nix` are reduced from 2 copies (~84 lines total) to 1 shared definition (~42 lines), and manual `complete -c` wrapper commands in `modules/core/base.nix` are reduced from 42 lines to 0.
- **SC-004**: 100% of host configurations (`desktop-pc`, `homelab`, `iso`, `macbook-air-m4-15`) and repository quality gates (`just fmt`, `just lint`, `just check`) succeed with exit code 0.

## Assumptions

- `core.limine` and `core.grub` can be colocated in a single auto-discovered module file `modules/core/bootloader.nix` following the Dendritic Pattern (`flake.modules.core.limine` and `flake.modules.core.grub`).
- Keeping `environment.shellAliases` alongside `programs.fish.shellAbbrs` preserves full compatibility for `root` (which uses Bash) and non-interactive alias usage while giving interactive Fish sessions native abbreviation expansion on both NixOS and macOS (`nix-darwin`).
