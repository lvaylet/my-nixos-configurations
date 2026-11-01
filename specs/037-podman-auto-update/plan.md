# Implementation Plan: Automated Container Image Updates via Podman and Systemd Timer

**Branch**: `037-podman-auto-update` | **Date**: 2026-11-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/037-podman-auto-update/spec.md`

## Summary

Automate daily container image updates across all homelab OCI containers (Portainer CE, Home Assistant, Filebrowser, n8n, n8n-runners, WAHA) using Podman's native `podman auto-update` engine and a persistent daily systemd timer declared in NixOS.

Technical approach:

1. Declare `systemd.timers.podman-auto-update` and `systemd.services.podman-auto-update` in `modules/services/podman.nix` with daily execution, persistent catch-up, randomized delay, and post-update image pruning.
2. Add `--label=io.containers.autoupdate=registry` to the `extraOptions` of all declarative container services:
   - `modules/services/portainer.nix` (`portainer`)
   - `modules/services/home-automation.nix` (`homeassistant`)
   - `modules/services/filebrowser.nix` (`filebrowser`)
   - `modules/services/waha.nix` (`waha`)
   - `modules/services/n8n.nix` (`n8n` and `n8n-runners`)
3. Add a dedicated recipe `update-containers` to `justfile` under `[group('container-management')]` supporting both local and remote SSH invocation.
4. Update `README.md` to document the daily automated update mechanism, systemd timer monitoring, and manual update triggers with dual Bash and Fish command examples.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable), Bash

**Primary Dependencies**:

- `nixpkgs` (`virtualisation.podman`, `virtualisation.oci-containers`, `systemd`)
- `podman` (v6.1.4+ native `podman auto-update`)
- `just` (task runner)

**Storage**:

- Preserved rootful Podman image store and layers: `/persistent/var/lib/containers` and `/persistent/var/tmp`
- Container state mounts under `/persistent/var/lib/` (`portainer`, `home-assistant`, `filebrowser`, `n8n`, `waha`)

**Testing**:

- Static analysis & linting: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`)
- Flake evaluation & pre-commit checks: `just check` (`nix flake check`)
- Targeted evaluation:
  - `nix eval .#nixosConfigurations.homelab.config.systemd.timers.podman-auto-update.timerConfig --json`
  - `nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.<name>.extraOptions --json`
- Live inspection: `systemctl list-timers podman-auto-update.timer` and `sudo podman auto-update --dry-run`

**Target Platform**: NixOS (`x86_64-linux`) on `homelab` (and compatible with `desktop-pc`)

**Project Type**: Infrastructure as Code / NixOS Service Configuration (Dendritic Pattern)

**Performance Goals**:

- Zero ongoing CPU/memory daemon overhead; utilizes a oneshot daily timer rather than a long-running polling daemon (like Watchtower).
- Jittered execution (`RandomizedDelaySec = "900"`) spreads registry queries across a 15-minute window.

**Constraints**:

- Strict Dendritic Pattern compliance: `modules/services/podman.nix` encapsulates the timer/service; individual service modules declare their own container labels.
- Dual-shell documentation parity: All commands in `README.md` must provide explicit Bash and Fish variants.
- Zero data loss: Containers restart using existing volume binds without resetting persistent state.

**Scale/Scope**:

- 6 modified service modules: `modules/services/podman.nix`, `modules/services/portainer.nix`, `modules/services/home-automation.nix`, `modules/services/filebrowser.nix`, `modules/services/waha.nix`, `modules/services/n8n.nix`
- 1 modified CLI recipe file: `justfile`
- 1 modified documentation file: `README.md`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic Configuration** | Pure evaluation, pinned `flake.lock`, no imperative state drift | **PASS** | Timer, service, and container labels declared purely in Nix modules without imperative ad-hoc state. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline host services | **PASS** | Container labels are colocated within their respective service modules; Podman timer is in `podman.nix`. Host modules (`modules/hosts/homelab.nix`) remain free of inline service logic. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean sandbox checks | **PASS** | Verified via `just fmt`, `just lint`, and `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext credentials in repo; least-privilege container exposure | **PASS** | Automated updates use public digest comparison without requiring credentials in repository code. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` and derivation evaluation prior to switching | **PASS** | Verified via `nix eval` queries and `just check` hermetic checks. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronized in the same branch with dual Bash/Fish syntax | **PASS** | `README.md` updated with container auto-update documentation, service monitoring commands, and dual Bash/Fish operational recipes. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in a dedicated branch associated with a PR | **PASS** | Tracked under dedicated branch `037-podman-auto-update`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/037-podman-auto-update/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output: auto-update mechanism, scheduling, and recipe choices
├── data-model.md        # Phase 1 output: systemd timer, service, and container policy matrix
├── quickstart.md        # Phase 1 output: verification commands (eval, static analysis, runtime)
├── contracts/           # Phase 1 output: configuration and CLI invariants
│   └── container-auto-update-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
modules/
└── services/
    ├── podman.nix          # Updated: declares systemd.timers and systemd.services for podman-auto-update
    ├── portainer.nix       # Updated: adds io.containers.autoupdate=registry to extraOptions
    ├── home-automation.nix # Updated: adds io.containers.autoupdate=registry to extraOptions
    ├── filebrowser.nix     # Updated: adds io.containers.autoupdate=registry to extraOptions
    ├── waha.nix            # Updated: adds io.containers.autoupdate=registry to extraOptions
    └── n8n.nix             # Updated: adds io.containers.autoupdate=registry to n8n and n8n-runners extraOptions
justfile                    # Updated: adds update-containers recipe under [group('container-management')]
README.md                   # Updated: documents automated timer, manual triggers, and dual-shell commands
```

**Structure Decision**: Standard dendritic NixOS configuration layout. No new architectural directories needed; changes integrate into existing service modules and operational tooling.

---

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitutional violations. Complexity tracking not required.
