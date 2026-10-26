# Implementation Plan: Fix FileBrowser Quantum Config Persistence and Localhost Binding

**Branch**: `024-fix-filebrowser-quantum` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/024-fix-filebrowser-quantum/spec.md`

## Summary

Resolve [Issue #30](https://github.com/lvaylet/my-nixos-configurations/issues/30) in `modules/services/filebrowser.nix` by mounting the preserved host directory `/var/lib/filebrowser` to `/config` inside the FileBrowser Quantum container (`/var/lib/filebrowser:/config`), binding the container port strictly to localhost (`127.0.0.1:8081:80`), and replacing TCP port `8081` with `443` in `networking.firewall.allowedTCPPorts` so that all external access goes through the Caddy HTTPS reverse proxy (`https://fb.<homelabDomain>`).

Technical approach:

1. Update `modules/services/filebrowser.nix`:
   - Uncomment and enable `"/var/lib/filebrowser:/config"` in `virtualisation.oci-containers.containers.filebrowser.volumes`.
   - Bind the host port strictly to `127.0.0.1:8081:80` in `virtualisation.oci-containers.containers.filebrowser.ports` (consistent with `n8n`, `waha`, and `uptime-kuma`).
   - Remove `8081` from `networking.firewall.allowedTCPPorts` (exposing only `443` for Caddy HTTPS, consistent with `n8n`, `waha`, and `uptime-kuma`).
   - Preserve existing `/data:/srv` volume, `PUID`/`PGID`/`UMASK` environment variables, `--group-add=995`, `CAP_NET_BIND_SERVICE`, Caddy virtualHost (`fb.${vars.homelabDomain}`), and `preservation.preserveAt."/persistent".directories` declarations.
2. Update `README.md` (`Homelab Hosted Services` and `Reverse Proxy & Secure HTTPS Access` tables) to reflect that FileBrowser Quantum is accessible exclusively via HTTPS (`443` via Caddy), mounts `/var/lib/filebrowser:/config`, and has no direct LAN HTTP endpoint (`N/A (loopback bound)`).

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:

- `nixpkgs` (NixOS `virtualisation.oci-containers`, `services.caddy`, `networking.firewall`)
- `preservation` (`github:nix-community/preservation`)
- `flake-parts` (`github:hercules-ci/flake-parts`)
- `import-tree` (`github:denful/import-tree`)
- Container image: `ghcr.io/gtsteffaniak/filebrowser:2-stable` (FileBrowser Quantum)

**Storage**:

- `/data:/srv`: Shared media and downloads storage managed by `modules/services/media.nix` (`filebrowser` UID `992`, `multimedia` GID `995`).
- `/var/lib/filebrowser:/config`: Persistent FileBrowser Quantum configuration and SQLite database directory preserved at `/persistent/var/lib/filebrowser` (`filebrowser:filebrowser`, mode `0700`).

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix check`, `deadnix`)
- Flake evaluation & pre-commit checks: `just check` (`nix flake check`)
- Targeted attribute evaluation:
  - `nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.filebrowser.volumes --json`
  - `nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.filebrowser.ports --json`
  - `nix eval .#nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts --json`

**Target Platform**: NixOS (`x86_64-linux`) on `homelab`

**Project Type**: Infrastructure as Code / NixOS Multi-Host Configuration (Dendritic Pattern)

**Performance Goals**:

- Zero runtime overhead; eliminates container rootfs copy-on-write state churn for the SQLite database by bind-mounting `/var/lib/filebrowser:/config`.
- Clean flake evaluation across all configurations (`desktop-pc`, `homelab`, `iso`, `macbook-air-m4-15`).

**Constraints**:

- Strict Dendritic Pattern compliance: All FileBrowser Quantum container, reverse proxy, firewall, and preservation rules remain encapsulated within `modules/services/filebrowser.nix`.
- Security-first networking: Port `8081` must bind only to `127.0.0.1` and must not appear in `networking.firewall.allowedTCPPorts`.
- Living documentation: `README.md` must be updated in the same branch with dual Bash/Fish command parity.

**Scale/Scope**:

- 1 modified feature module: `modules/services/filebrowser.nix`
- 1 modified documentation file: `README.md`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic Configuration** | Pure evaluation, pinned `flake.lock`, no imperative state drift | **PASS** | Container volumes, port bindings, firewall rules, and state preservation are declared purely in `modules/services/filebrowser.nix`. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline host services | **PASS** | All changes are colocated inside `modules/services/filebrowser.nix`; `modules/hosts/homelab.nix` remains a pure feature list. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean sandbox checks | **PASS** | Verified via `just fmt`, `just lint`, and `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext credentials in repo; least-privilege network exposure | **PASS** | Removes cleartext HTTP exposure on `0.0.0.0:8081` and closes port `8081` on the firewall, enforcing TLS termination via Caddy on port `443`. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` and derivation evaluation prior to switching | **PASS** | Verified via `nix eval` of `homelab` container and firewall attributes and `just check`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronized in the same branch with dual Bash/Fish syntax | **PASS** | `README.md` service and reverse proxy tables updated to reflect loopback-only binding and `/var/lib/filebrowser:/config` persistence. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in a dedicated branch associated with a PR | **PASS** | Tracked under `024-fix-filebrowser-quantum` for Issue #30. |

---

## Project Structure

### Documentation (this feature)

```text
specs/024-fix-filebrowser-quantum/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── filebrowser-service-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
modules/
├── services/
│   ├── caddy.nix                  # Unchanged (central reverse proxy on port 443)
│   ├── filebrowser.nix            # Updated: mount /var/lib/filebrowser:/config, bind 127.0.0.1:8081:80, remove 8081 from firewall
│   └── media.nix                  # Unchanged (defines filebrowser user UID 992 and multimedia group GID 995)
└── hosts/
    └── homelab.nix                # Unchanged (enables services.filebrowser)
README.md                          # Updated: reflect loopback-only binding and /var/lib/filebrowser:/config in service tables
```

**Structure Decision**: Single declarative Nix flake repository following the Dendritic Pattern (`modules/services/filebrowser.nix` + `README.md`).

---

## Complexity Tracking

No constitutional violations. Complexity tracking not required.
