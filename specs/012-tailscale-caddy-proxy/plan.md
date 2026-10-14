# Implementation Plan: Secure Remote Service Exposure via Tailscale and Caddy

**Branch**: `feat-https-with-tailscale-and-caddy` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/012-tailscale-caddy-proxy/spec.md`

## Summary

Implement secure remote access for internal homelab services (Home Assistant and n8n) over the private Tailscale mesh network using Caddy as a centralized reverse proxy with native Tailscale TLS certificate management. By setting `services.tailscale.permitCertUid = "caddy"`, the Caddy system user is authorized to query the local Tailscale daemon socket (`TS_PERMIT_CERT_UID`), automatically acquiring and renewing trusted Let's Encrypt certificates for the host's Tailscale domain name (`<hostname>.<tailscaleDomain>`). Home Assistant is exposed on standard HTTPS port 443 (reverse proxying to `127.0.0.1:8123` with WebSocket streaming and trusted proxy support), while n8n is exposed on HTTPS port 5678 (reverse proxying to loopback port `127.0.0.1:5679`). The design adheres strictly to the repository's dendritic architecture, preserves certificate state under `/persistent`, and exposes zero ports on the home router.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:
- Caddy reverse proxy (`services.caddy`)
- Tailscale mesh networking daemon (`services.tailscale`)
- Podman container engine (`virtualisation.oci-containers`)
- State preservation (`github:nix-community/preservation`)
- Flake architecture (`github:hercules-ci/flake-parts`, `github:denful/import-tree`)

**Storage**:
- `/var/lib/caddy`: Persistent host directory containing Let's Encrypt TLS certificates, keys, and reverse proxy state, preserved under `/persistent/var/lib/caddy`.
- `/var/lib/n8n`: Persistent storage for workflows, credentials, and SQLite database preserved under `/persistent/var/lib/n8n`.
- `/var/lib/home-assistant`: Persistent configuration directory preserved under `/persistent/var/lib/home-assistant`.

**Testing**:
- Formatting & linting: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Flake evaluation: `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`.
- Target regression testing: `desktop-pc` and `iso` toplevel evaluation.
- Hermetic pre-commit checks: `just check` (`nix flake check`).

**Target Platform**: Intel N150 (Alder Lake-N) Beelink S13 mini PC (`homelab`, `x86_64-linux`).

**Project Type**: Infrastructure as Code (Nix Flake, NixOS system configuration).

**Performance Goals**:
- Dashboard load times under 3 seconds over Tailscale overlay connections.
- Proxy routing overhead under 200 milliseconds.
- Bi-directional WebSocket streaming without connection timeouts or dropouts.

**Constraints**:
- Strict Dendritic Pattern compliance: `modules/hosts/homelab.nix` must only assemble hardware and feature modules; zero inline service definitions.
- Declarative state preservation: `/var/lib/caddy` must survive ephemeral tmpfs root reboots.
- Zero plaintext secrets committed to version control.
- Zero open ports forwarded on the home router (WAN).
- No regressions on `desktop-pc` or `iso` targets.

**Scale/Scope**:
- 1 variable option added: `tailscaleDomain` in `modules/core/vars.nix`.
- 4 service modules updated:
  - `modules/services/tailscale.nix` (`permitCertUid = "caddy"`)
  - `modules/services/caddy.nix` (startup ordering after `tailscaled.service`)
  - `modules/services/home-automation.nix` (Caddy virtualHost on 443, firewall port 443)
  - `modules/services/n8n.nix` (Caddy virtualHost on 5678, loopback container binding)
- 0 host file changes required (`homelab.nix` already enables these features).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
|---|---|---|---|
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` drift | **PASS** | Entire reverse proxy, TLS permissioning, and service endpoints declared purely in NixOS modules with state preservation under `/persistent`. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | `tailscaleDomain` declared in `modules/core/vars.nix`. Service endpoints colocated in their respective service modules (`home-automation.nix`, `n8n.nix`). Zero inline service logic in `homelab.nix`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | All modules verified with `alejandra`, `statix`, and `deadnix`. Evaluation commands documented in `quickstart.md`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | No certificates or tokens committed to git. Certificates fetched at runtime from Tailscale daemon over local socket. External access restricted to private mesh overlay. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Flake evaluation and sandbox checks documented in `quickstart.md`. Safe deployment via `just test` before permanent switch. |

---

## Project Structure

### Documentation (this feature)

```text
specs/012-tailscale-caddy-proxy/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Entities, attributes, schemas & invariants (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   ├── caddy-tailscale-proxy-contract.md
│   └── service-endpoints-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
├── core/
│   └── vars.nix                 # Adds config.flake.vars.tailscaleDomain
└── services/
    ├── tailscale.nix            # Adds services.tailscale.permitCertUid = "caddy"
    ├── caddy.nix                # Adds systemd ordering after tailscaled.service
    ├── home-automation.nix      # Adds Caddy virtual host on port 443 + firewall port 443
    └── n8n.nix                  # Updates Caddy virtual host on port 5678 with Tailscale TLS
```

**Structure Decision**:
Follows the repository's standardized dendritic domain hierarchy. Shared domain identity is declared in `modules/core/vars.nix`. Service endpoints are colocated within their existing capability modules (`modules/services/home-automation.nix`, `modules/services/n8n.nix`, `modules/services/caddy.nix`, `modules/services/tailscale.nix`) without creating monolithic files or host-level boilerplate.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *None* | All designs strictly comply with Constitution Principles I–V | N/A |
