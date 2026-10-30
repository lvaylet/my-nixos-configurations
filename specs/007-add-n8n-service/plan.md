# Implementation Plan: n8n Workflow Automation Service for Homelab

**Branch**: `007-add-n8n-service` | **Date**: 2026-10-11 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/007-add-n8n-service/spec.md`

## Summary

Deploy a self-hosted n8n workflow automation service on the `homelab` host. Following the architectural patterns established for upstream web applications (`home-automation`, `portainer`, `filebrowser`), the service is implemented as an OCI container supervised by systemd via Podman (`docker.io/n8nio/n8n:latest`). The service exposes port `5678` for web UI access and incoming webhook triggers, opens port `5678` in the host firewall, configures `Europe/Paris` timezone parameters, mounts `/var/lib/n8n` to `/home/node/.n8n`, and preserves `/var/lib/n8n` under `/persistent` with ownership UID/GID `1000:1000`. The capability is encapsulated as a dendritic feature module in `modules/services/n8n.nix` and enabled within `modules/hosts/homelab.nix` with zero inline service logic.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:

- `virtualisation.oci-containers` (Podman backend)
- `docker.io/n8nio/n8n:latest` OCI container image
- `preservation` (`github:nix-community/preservation`)
- `flake-parts` (`github:hercules-ci/flake-parts`)
- `import-tree` (`github:denful/import-tree`)

**Storage**: Persistent host directory `/var/lib/n8n` bound to container path `/home/node/.n8n`, backed by SQLite (`database.sqlite`), declaratively preserved at `/persistent/var/lib/n8n`.

**Testing**:

- Formatting & linting: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Flake evaluation: `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`.
- Regression evaluation: `desktop-pc` and `iso` toplevel evaluation.
- Pre-commit sandboxes: `just check` (`nix flake check`).

**Target Platform**: Intel N150 (Alder Lake-N) Beelink S13 mini PC (`x86_64-linux`).

**Project Type**: Infrastructure as Code (Nix Flake, NixOS system configuration).

**Performance Goals**:

- Web UI and webhook response times under 3 seconds on local network.
- Scheduled triggers execute within 1 second of scheduled time.
- Low memory footprint utilizing embedded SQLite without external database overhead.

**Constraints**:

- Strict Dendritic Pattern compliance: `modules/hosts/homelab.nix` must only assemble hardware and feature modules, with zero inline service definitions.
- Declarative state preservation: `/var/lib/n8n` must be preserved under `/persistent` to survive ephemeral tmpfs root reboots.
- Zero plaintext secrets committed to version control.
- No regressions on `desktop-pc` or `iso` targets.

**Scale/Scope**:

- 1 new feature module: `modules/services/n8n.nix`.
- 1 host definition updated: `modules/hosts/homelab.nix`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` drift | **PASS** | Entire service declared via NixOS OCI container configuration with declarative state preservation under `/persistent`. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | `modules/services/n8n.nix` encapsulates container, firewall, and preservation rules. `modules/hosts/homelab.nix` only adds `services.n8n` to its features list. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | Module verified against `alejandra`, `statix`, and `deadnix`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | n8n encryption keys and user passwords generated and stored in persistent application database, no credentials hardcoded in Nix files. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Flake evaluation and sandbox checks documented in `quickstart.md`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/007-add-n8n-service/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Entities, attributes, schemas & invariants (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   ├── n8n-service-contract.md
│   └── homelab-host-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
├── services/
│   ├── n8n.nix                 # New n8n OCI container service + firewall + preservation
│   ├── filebrowser.nix
│   ├── home-automation.nix
│   ├── portainer.nix
│   ├── jellyfin.nix
│   ├── qbittorrent.nix
│   ├── podman.nix
│   └── ...
└── hosts/
    └── homelab.nix             # Enabled features list updated with services.n8n
```

**Structure Decision**:
Follows the repository's standardized dendritic domain hierarchy. The new service resides in `modules/services/n8n.nix` with colocated firewall and preservation declarations. It is composed into `modules/hosts/homelab.nix` via `config.flake.modules.services.n8n`.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *None* | All designs strictly comply with Constitution Principles I–V | N/A |
