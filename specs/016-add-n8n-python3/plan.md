# Implementation Plan: Enable Python 3 Script Execution for n8n Code Nodes on Homelab

**Branch**: `016-add-n8n-python3` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/016-add-n8n-python3/spec.md`

## Summary

Add Python 3 on the `homelab` server and enable n8n to execute Python 3 scripts inside n8n `Code` nodes. Because upstream `docker.io/n8nio/n8n:latest` (n8n 2.x) uses a minimal Node.js runtime without a bundled Python interpreter or `@n8n/task-runner-python` virtual environment—and deprecates `internal` task runner mode—this plan:

1. Installs `pkgs.python3` system-wide on `homelab` via `environment.systemPackages` in `modules/services/n8n.nix` (`FR-001`).
2. Configures the `n8n` OCI container (`virtualisation.oci-containers.containers.n8n`) in **external task runner mode** (`N8N_RUNNERS_ENABLED = "true"`, `N8N_RUNNERS_MODE = "external"`, `N8N_RUNNERS_BROKER_LISTEN_ADDRESS = "0.0.0.0"`, `N8N_RUNNERS_BROKER_PORT = "5679"`, `N8N_NATIVE_PYTHON_RUNNER = "true"`).
3. Deploys the official `docker.io/n8nio/runners:latest` companion OCI container (`virtualisation.oci-containers.containers.n8n-runners`) with `dependsOn = [ "n8n" ]`, connecting to `http://n8n:5679` over the internal Podman DNS bridge network (`modules/services/podman.nix`).
4. Mounts a declarative `/etc/n8n-task-runners.json` generated via `pkgs.writeText` into `n8n-runners` to allowlist the Python 3 standard library (`N8N_RUNNERS_STDLIB_ALLOW = "*"`) and external modules (`N8N_RUNNERS_EXTERNAL_ALLOW = "*"`), while propagating `TZ` and `GENERIC_TIMEZONE` (`Europe/Paris`).
5. Bootstraps `/var/lib/n8n/runners.env` idempotently in `systemd.services."podman-n8n".preStart` with a 256-bit cryptographically random `N8N_RUNNERS_AUTH_TOKEN` (persisted at `/persistent/var/lib/n8n/runners.env`, `0600`) shared by both `n8n` and `n8n-runners` via `environmentFiles`.
6. Updates `README.md` to document the `n8n-runners` sidecar and Python 3 capability in accordance with Constitution Principle VI.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable), Python 3 (`pkgs.python3` on host + Python 3.13 in `docker.io/n8nio/runners:latest`)

**Primary Dependencies**:
- `pkgs.python3` (NixOS host system package)
- `virtualisation.oci-containers` (Podman backend configured in `modules/services/podman.nix`)
- `docker.io/n8nio/n8n:latest` & `docker.io/n8nio/runners:latest` OCI container images
- `preservation` (`github:nix-community/preservation` in `modules/core/preservation.nix`)
- `flake-parts` (`github:hercules-ci/flake-parts`) & `import-tree` (`github:mightyiam/import-tree`)

**Storage**:
- Persistent host directory `/var/lib/n8n` preserved at `/persistent/var/lib/n8n` (`user = "1000"`, `group = "1000"`, `mode = "0750"`):
  - `/var/lib/n8n/database.sqlite` & `/var/lib/n8n/config` (existing workflows, credentials, encryption key)
  - `/var/lib/n8n/runners.env` (`0600`, auto-generated shared `N8N_RUNNERS_AUTH_TOKEN` loaded via `environmentFiles`)
- Read-only Nix store file `n8n-task-runners.json` mounted at `/etc/n8n-task-runners.json:ro` in `n8n-runners`.

**Testing**:
- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Flake evaluation: `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`.
- Target regression checks: `desktop-pc` and `iso` toplevel evaluation.
- Hermetic sandbox checks: `just check` (`nix flake check`).
- Runtime verification: `just test configuration="homelab" target="homelab"`, `python3 --version`, `scs podman-n8n podman-n8n-runners`, and executing a Python `Code` node in n8n.

**Target Platform**: Intel N150 (Alder Lake-N) Beelink S13 mini PC (`homelab`, `x86_64-linux`).

**Project Type**: Infrastructure as Code (Nix Flake, NixOS system configuration).

**Performance Goals**:
- Python 3 `Code` nodes processing standard workflow payloads complete within 2 seconds (`SC-002`).
- Zero local compilation overhead by using pre-built upstream `docker.io/n8nio/runners:latest` and cached `pkgs.python3`.

**Constraints**:
- Strict Dendritic Pattern compliance: all n8n service and runner definitions remain encapsulated in `modules/services/n8n.nix`; `modules/hosts/homelab.nix` contains zero inline service logic.
- Zero plaintext secrets in Git: `N8N_RUNNERS_AUTH_TOKEN` is generated at runtime in `/var/lib/n8n/runners.env`.
- Internal-only broker networking: the task broker port (`5679` inside the `n8n` container) is only reachable on the internal Podman bridge network (`http://n8n:5679`) and never exposed externally.
- Full `README.md` synchronization within the same branch (Principle VI) and dedicated branch/PR isolation (Principle VII).

**Scale/Scope**:
- 1 feature module updated: `modules/services/n8n.nix`.
- 1 documentation file updated: `README.md`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic Configuration** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` or `/etc` drift | **PASS** | Host `pkgs.python3`, `n8n` + `n8n-runners` OCI containers, and `/etc/n8n-task-runners.json` are 100% declaratively defined in NixOS modules. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | All Python 3 host packages, `n8n-runners` sidecar container, launcher config, and systemd ordering are colocated inside `modules/services/n8n.nix`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | All Nix expressions and generated JSON config adhere to `alejandra`, `statix`, and `deadnix` rules. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets in Git, pass `ripsecrets`/`trufflehog` | **PASS** | `N8N_RUNNERS_AUTH_TOKEN` is generated dynamically at service startup into `/var/lib/n8n/runners.env` (`0600`) on persistent storage outside Git. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` and `just test` before `just switch` | **PASS** | Verification and safe activation testing documented in `quickstart.md`. |
| **VI. Living Documentation & Dual-Shell Parity** | Update `README.md` in same branch; provide explicit Bash/Fish variants where syntax differs | **PASS** | `README.md` service table updated in the same branch to document n8n's `n8nio/runners` Python 3 & JS task runner sidecar. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work in a dedicated branch associated with a PR targeting `main` | **PASS** | Feature implementation and PR workflow target dedicated branch `016-add-n8n-python3`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/016-add-n8n-python3/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & root-cause decisions (Phase 0 output)
├── data-model.md        # Entities, attributes, schemas & invariants (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   └── n8n-python-runner-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
├── services/
│   ├── n8n.nix                 # Updated: pkgs.python3 + n8n external runner config + n8n-runners sidecar
│   ├── podman.nix              # Existing Podman backend with container DNS enabled
│   ├── caddy.nix               # Existing Caddy reverse proxy
│   └── ...
└── hosts/
    └── homelab.nix             # Existing host composition (already enables services.n8n)
README.md                       # Updated Homelab Hosted Services table for n8n Python 3 support
```

**Structure Decision**:
Follows the repository's standardized dendritic domain hierarchy. `modules/services/n8n.nix` colocates the host `pkgs.python3` package, the `n8n` main container configuration, the `n8n-runners` sidecar container, the declarative `/etc/n8n-task-runners.json` Nix store derivation, and the `preStart` token bootstrap script.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| *None* | All designs strictly comply with Constitution Principles I–VII | N/A |
