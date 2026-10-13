# Implementation Plan: Enable Bluetooth Connectivity on Desktop-PC

**Branch**: `010-enable-desktop-bluetooth` | **Date**: 2026-10-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/010-enable-desktop-bluetooth/spec.md`

---

## Summary

Enable Bluetooth connectivity on `desktop-pc` by introducing a dedicated dendritic service module at `modules/services/bluetooth.nix` and composing it into `modules/hosts/desktop-pc.nix`. The module enables the core BlueZ stack with boot-time adapter power and experimental battery status reporting, integrates Blueman for graphical/desktop tray management, leverages existing WirePlumber audio routing for wireless sound endpoints, and guarantees that headless server configurations (`homelab`) remain unburdened and isolated.

---

## Technical Context

**Language/Version**: Nix (Nixpkgs unstable, Flakes)

**Primary Dependencies**:

- BlueZ 5 (Linux Bluetooth protocol stack daemon)
- Blueman (GTK Bluetooth manager and D-Bus mechanism)
- PipeWire & WirePlumber (audio routing and Bluetooth SPA plugin)
- `flake-parts` (`github:hercules-ci/flake-parts`)
- `import-tree` (`github:denful/import-tree`)

**Storage**:

- BlueZ pairing credentials and adapter state stored at `/var/lib/bluetooth` (already declared in `modules/core/preservation.nix`).

**Testing**:

- Flake option evaluation: `nix eval .#nixosConfigurations.desktop-pc.config.hardware.bluetooth.enable` and `services.blueman.enable`.
- Toplevel derivation evaluation: `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`.
- Headless isolation verification: `nix eval .#nixosConfigurations.homelab.config.hardware.bluetooth.enable` (evaluates to `false`).
- Code formatting & linting: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Pre-commit integrity gates: `just check` (`nix flake check`).

**Target Platform**: Linux x86_64 (`desktop-pc`).

**Project Type**: Infrastructure as Code (Nix Flakes, NixOS modular architecture).

**Performance Goals**:

- 0 evaluation duration regression during flake builds.
- Immediate controller power initialization upon boot (`powerOnBoot = true`).
- Rapid peripheral reconnection (<5 seconds) when devices power on in range.

**Constraints**:

- Strict adherence to repository constitution quality gates (I, II, III, IV, V).
- Complete isolation: zero Bluetooth overhead or daemons on headless server hosts (`homelab`).
- Zero secrets or private keys committed.

**Scale/Scope**: 1 new dendritic service module (`modules/services/bluetooth.nix`), 1 host composition update (`modules/hosts/desktop-pc.nix`).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic** | Pinned `flake.lock`, purely declarative configuration, no imperative drift | **PASS** | Bluetooth daemon, controller power policy, and management tools are 100% declared via NixOS options; no manual configuration files in `/etc`. |
| **II. Dendritic Modularity** | Feature-centric colocation under `modules/services/`, zero boilerplate | **PASS** | Implemented as `modules/services/bluetooth.nix` (`flake.modules.services.bluetooth`), discovered automatically via `import-tree ./modules`, composed cleanly into `modules/hosts/desktop-pc.nix`. No inline service definitions in host file. |
| **III. Shift-Left Quality** | Clean formatting (`alejandra`), zero `statix`/`deadnix` errors, clean pre-commit hooks | **PASS** | Validated using `alejandra`, `statix check`, and `deadnix`. Verified hermetically via `just check` / `nix flake check`. |
| **IV. Zero-Secrets Leakage** | No private keys or credentials in plaintext | **PASS** | No credentials, API tokens, or secrets involved; pairing keys are generated locally at runtime and stored in `/var/lib/bluetooth`. |
| **V. Rigorous Verification** | Safe evaluation, `just check`, non-destructive testing before activation | **PASS** | Validated via `nix eval` option inspection and derivation checks before staging activation with `just test`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/010-enable-desktop-bluetooth/
├── plan.md              # Implementation Plan (/speckit.plan command output)
├── research.md          # Technical research and design decisions (Phase 0)
├── data-model.md        # Entities, attributes, schemas, and state lifecycles (Phase 1)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1)
├── contracts/           # Interface contracts (Phase 1)
│   ├── bluetooth-service-contract.md
│   └── host-composition-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
├── hosts/
│   └── desktop-pc.nix   # Composes services.bluetooth into features list
└── services/
    └── bluetooth.nix    # New dendritic module declaring BlueZ and Blueman
```

**Structure Decision**:

- Creates `modules/services/bluetooth.nix` encapsulating `flake.modules.services.bluetooth` with `hardware.bluetooth` and `services.blueman`.
- Updates `modules/hosts/desktop-pc.nix` to include `services.bluetooth` in its `features` list.
- Leaves `modules/hosts/homelab.nix` untouched, ensuring server isolation.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *None* | N/A | No constitution violations detected. Standard dendritic service module pattern with declarative NixOS options. |
