# Feature Specification: Harmonize Task Runner (`justfile`) Recipes and Syntax Across Hosts

**Feature Branch**: `028-harmonize-justfile-recipes`

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "Harmonise les recettes et les syntaxes de @justfile pour les différentes machines. Actuellement, les mots-clés pour le test et le déploiement sur les différentes machines sont différents."

## Clarifications

### Session 2026-10-26

- Q: Which recipe naming and invocation pattern should be adopted across machines (`desktop-pc`, `homelab`, `macbook-air-m4-15`)? → A: **Option A (Unified parameterized recipes only)**: Replace host-suffixed lifecycle recipes (`build-darwin`, `test-darwin`, `switch-darwin`, `deploy-homelab`, `test-homelab`, `install-homelab`) with a single unified set of parameterized verbs (`build`, `test`, `switch`, `boot`, `install`) plus `build-iso`. When `configuration` is omitted, auto-detect the local host (`macbook-air-m4-15` on Darwin, or local hostname / `desktop-pc` fallback on Linux).
- Q: Which privilege and remote SSH execution strategy should be standardized across `homelab`, `desktop-pc`, and `macbook-air-m4-15`? → A: **Option B (Current user + `sudo` / `--use-remote-sudo`)**: Connect as the standard user (`laurent`, where `wheelNeedsPassword = false` and SSH keys are authorized on both `desktop-pc` and `homelab`) with remote sudo elevation (`nh os <action> .#<configuration> --target-host <target>` or `nixos-rebuild <action> --flake .#<configuration> --target-host <target> --use-remote-sudo`), and use `sudo` on macOS (`macbook-air-m4-15`) for `test` and `switch`. Only initial bare-metal installation (`just install` via `nixos-anywhere`) defaults to `root@<target>`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unified Lifecycle Verbs Across All Machines (Priority: P1)

As a system operator managing `desktop-pc`, `homelab`, and `macbook-air-m4-15`, I want a single, unified set of task runner lifecycle verbs (`build`, `test`, `switch`, `boot`, `install`) with automatic platform and host detection so that I use the exact same commands and syntax regardless of which machine I am operating or targeting.

**Why this priority**: Previously, the `justfile` used divergent recipe names and verbs depending on the target machine (`switch` for `desktop-pc`, `deploy-homelab` for `homelab`, `switch-darwin` for `macbook-air-m4-15`, and lacked `build` or `boot` equivalents for `homelab`). Unifying all hosts under a single set of parameterized verbs eliminates cognitive overhead and command inconsistency.

**Independent Test**: Can be independently tested by running `just --list` and verifying that `build`, `test`, `switch`, `boot`, and `install` are the sole machine lifecycle recipes (alongside `build-iso`), and that invoking `just build`, `just test`, or `just switch` automatically adapts to Darwin (`macbook-air-m4-15`) and NixOS (`desktop-pc`, `homelab`).

**Acceptance Scenarios**:

1. **Given** an operator running `just --list`, **When** inspecting the `(re)build` group, **Then** only the unified recipes (`build`, `test`, `switch`, `boot`, `install`, and `build-iso`) are present, and legacy host-suffixed recipes (`*-darwin`, `*-homelab`) are removed.
2. **Given** an operator on `macbook-air-m4-15` (macOS) or passing `configuration="macbook-air-m4-15"`, **When** running `just build`, `just test`, or `just switch`, **Then** the recipe targets `.#darwinConfigurations.macbook-air-m4-15` and executes `sudo` for activation during `test` and `switch`.
3. **Given** an operator on `desktop-pc` or `homelab` (NixOS), **When** running `just build`, `just test`, `just switch`, or `just boot` without arguments, **Then** the recipe auto-detects the current host configuration and executes locally using `nh os` (or `sudo nixos-rebuild` fallback).

---

### User Story 2 - Seamless Local & Remote Targeting with `sudo` Elevation (Priority: P2)

As a system operator deploying or testing configurations locally or remotely over SSH across `homelab`, `desktop-pc`, and `macbook-air-m4-15`, I want parameter signatures (`configuration="" target=""`) and privilege elevation (`sudo` locally, `--use-remote-sudo` remotely) to work uniformly across all machines so that I can target any host without manual SSH user workarounds or root login incompatibilities.

**Why this priority**: `desktop-pc` forbids direct `root` SSH login (`PermitRootLogin = "no"`) while allowing passwordless `sudo` for `laurent`, `homelab` configures SSH client access as `laurent` with passwordless `sudo`, and `macbook-air-m4-15` requires `sudo` for `nix-darwin` activation. Standardizing on user-level SSH + `sudo` elevation allows targeting any machine with identical semantics.

**Independent Test**: Can be independently tested by dry-running or inspecting recipe execution paths for local and remote invocations targeting `homelab`, `desktop-pc`, and `macbook-air-m4-15`.

**Acceptance Scenarios**:

1. **Given** an operator on `desktop-pc` (or another Linux host) targeting a remote NixOS host (`just test homelab` or `just switch homelab <target>`), **When** the target configuration differs from the local hostname or `target` is explicitly provided, **Then** the recipe deploys over SSH using `nh os <action> .#<configuration> --target-host <target>` (or `nixos-rebuild <action> --flake .#<configuration> --target-host <target> --use-remote-sudo`).
2. **Given** an operator running `just test` or `just switch` on `macbook-air-m4-15`, **When** the Darwin configuration is activated, **Then** activation runs with `sudo` (`sudo "${systemConfig}/activate"` for `test`, and `sudo nix run nix-darwin -- switch --flake .#<configuration>` for `switch`).
3. **Given** an operator bootstrapping a fresh NixOS machine from the custom installer ISO, **When** running `just install <target> [configuration="homelab"]`, **Then** `nixos-anywhere` deploys `.#<configuration>` to `root@<target>` (preserving any explicit `user@` prefix if provided).

---

### User Story 3 - Synchronized Living Documentation & Dual-Shell Parity (Priority: P3)

As a contributor or operator reading `README.md`, I want all `just` command references, the `just --list` overview, and all Bash/Fish operational snippets updated to the unified recipe syntax so that repository documentation matches the actual task runner behavior without stale `deploy-homelab` or `*-darwin` references.

**Why this priority**: Required by Constitutional Principle VI (*Living Documentation & Dual-Shell Parity*) to prevent documentation drift across `README.md`.

**Independent Test**: Can be independently tested by searching `README.md` for `just` commands and confirming zero references remain to removed recipes (`deploy-homelab`, `test-homelab`, `install-homelab`, `build-darwin`, `test-darwin`, `switch-darwin`) and that all Bash/Fish code blocks are accurate.

**Acceptance Scenarios**:

1. **Given** `README.md`, **When** inspecting the `Operational Recipes (justfile)` section, **Then** the displayed `just` output matches the unified `just --list` output.
2. **Given** `README.md` sections for macOS (`macbook-air-m4-15`) and Homelab (`homelab`), **When** reviewing build, test, switch, and install instructions, **Then** all commands use the unified `just build`, `just test`, `just switch`, `just boot`, and `just install` syntax with both Bash and Fish variants where applicable.

---

### Edge Cases

- **Auto-Detection of Default `configuration` Across OSes**: When `configuration` is omitted (`configuration=""`), the recipe detects `Darwin` (`uname -s == "Darwin"`) and defaults to `macbook-air-m4-15`; on Linux, if `/etc/NIXOS` exists, it defaults to the current `hostname` (if matching a known NixOS configuration) or `desktop-pc`.
- **Smart Default for Remote `target` When Targeting Another NixOS Host**: When running `just test homelab` or `just switch homelab` on `desktop-pc` (or on a non-NixOS Linux machine) without explicitly specifying `target`, the recipe automatically defaults `target` to `{{configuration}}` (e.g., `homelab`) instead of attempting to apply `homelab`'s configuration to the local machine or failing.
- **Executing Unsupported Cross-OS Local Operations**:
  - Running `just boot` or `just install` for `macbook-air-m4-15` fails fast with a clear message explaining that `boot` and `nixos-anywhere` `install` only apply to NixOS configurations.
  - Running `just test` or `just switch` for a Darwin configuration from a Linux machine without a remote target fails fast with a clear error message stating that Darwin activation must be run on macOS.
- **Availability of `nh`**: When `nh` is available locally on Linux, NixOS `build`, `test`, `switch`, and `boot` recipes leverage `nh os`; when `nh` is absent, they gracefully fall back to `nix build` / `nixos-rebuild` with `sudo` (local) or `--use-remote-sudo` (remote).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `justfile` MUST replace host-specific lifecycle recipes (`build-darwin`, `test-darwin`, `switch-darwin`, `deploy-homelab`, `test-homelab`, `install-homelab`) with unified parameterized lifecycle recipes under `[group('(re)build')]`:
  - `build configuration="" target=""`
  - `test configuration="" target=""`
  - `switch configuration="" target=""`
  - `boot configuration="" target=""`
  - `install target configuration="homelab"`
  - `build-iso`
- **FR-002**: When `configuration` is empty (`""`), `build`, `test`, `switch`, and `boot` MUST automatically resolve the default host configuration:
  - On macOS (`uname -s == "Darwin"`): `macbook-air-m4-15`.
  - On Linux: current `hostname -s` if it matches a known NixOS host (`desktop-pc` or `homelab`), otherwise `desktop-pc`.
- **FR-003**: When `configuration` is `macbook-air-m4-15` (a Darwin configuration):
  - `just build`: MUST build `.#darwinConfigurations.{{configuration}}.system` without activating.
  - `just test`: MUST require running on macOS (`Darwin`), build `.#darwinConfigurations.{{configuration}}.system` (`--no-link --print-out-paths`), and run `sudo "${systemConfig}/activate"` without creating a new generation profile.
  - `just switch`: MUST require running on macOS (`Darwin`) and run `sudo nix run nix-darwin -- switch --flake .#{{configuration}}`.
  - `just boot` and `just install`: MUST exit with a clear error message stating that `boot` and `install` are only supported for NixOS hosts.
- **FR-004**: When `configuration` is a NixOS configuration (`desktop-pc`, `homelab`, etc.):
  - If `target` is empty (`""`) and the local machine is not NixOS (`! -e /etc/NIXOS`) or its hostname differs from `configuration` (e.g., running `just switch homelab` from `desktop-pc`), `test`, `switch`, and `boot` MUST automatically default `target` to `configuration` for remote SSH execution (except for `build`, which builds locally when `target` is empty).
  - For local NixOS execution (`target` resolved as empty on the matching NixOS host): recipes MUST use `nh os <action> .#{{configuration}}` when `nh` is available, falling back to `sudo nixos-rebuild <action> --flake .#{{configuration}}` (or `nix build` for `build`).
  - For remote NixOS execution (`target` non-empty): recipes MUST connect using the caller's SSH identity and elevate privileges via `sudo` on the remote host (`nh os <action> .#{{configuration}} --target-host "{{target}}"` if `nh` is available, or `nixos-rebuild <action> --flake .#{{configuration}} --target-host "{{target}}" --use-remote-sudo`, omitting `--use-remote-sudo` for `build`).
- **FR-005**: The `install` recipe (`just install <target> [configuration="homelab"]`) MUST bootstrap the target NixOS configuration using `nixos-anywhere` (`nix run github:nix-community/nixos-anywhere -- --flake .#{{configuration}} "${TARGET_HOST}"`), automatically prefixing `root@` to `target` if no `@` username is specified.
- **FR-006**: `clean` and `clean-all` recipes under `[group('garbage-collection')]` MUST remain compatible across NixOS, non-NixOS Linux, and macOS (using `nh clean` when on NixOS with `nh` installed, and falling back to `nix-collect-garbage` / `sudo nix-collect-garbage --delete-old` on macOS and non-NixOS systems).
- **FR-007**: `README.md` MUST be updated to synchronize the `just --list` output and all operational command examples (including macOS `macbook-air-m4-15` and `homelab` sections) with dual **Bash** and **Fish** snippets wherever shell syntax differs.
- **FR-008**: All repository quality gates (`just fmt`, `just lint`, `just check`) MUST pass with exit code 0.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of machine lifecycle operations across `desktop-pc`, `homelab`, and `macbook-air-m4-15` are handled by the 5 unified lifecycle verbs (`build`, `test`, `switch`, `boot`, `install`) plus `build-iso`, reducing `(re)build` recipe count from 11 heterogeneous recipes to 6 unified recipes.
- **SC-002**: Zero divergent action verbs (`deploy-*`) or host-suffixed recipes (`*-darwin`, `*-homelab`) remain in `justfile` or `README.md`.
- **SC-003**: Local and remote invocations for `desktop-pc`, `homelab`, and `macbook-air-m4-15` use `sudo` / `--use-remote-sudo` consistently without requiring direct `root` SSH login (except initial `just install` via `nixos-anywhere`).
- **SC-004**: 100% of repository quality gates (`just fmt`, `just lint`, `just check`) succeed with exit code 0.

## Assumptions

- `macbook-air-m4-15` is currently the sole Darwin host in `darwinConfigurations`, while `desktop-pc` and `homelab` are the managed NixOS hosts in `nixosConfigurations` (alongside `iso`). Detecting Darwin configurations can check whether `configuration == "macbook-air-m4-15"` (or whether `.#darwinConfigurations.${configuration}` is targeted).
- When running `just test homelab` or `just switch homelab` from `desktop-pc`, automatically inferring `target="homelab"` when `hostname != configuration` provides an ergonomic shorthand (`just switch homelab` instead of `just switch homelab homelab`) while still allowing an explicit custom IP/host (`just switch homelab 192.168.1.180` or `just switch homelab target="192.168.1.180"`).
