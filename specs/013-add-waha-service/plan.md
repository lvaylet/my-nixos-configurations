# Implementation Plan: WAHA WhatsApp Automation Service for Homelab

**Branch**: `013-add-waha-service` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/013-add-waha-service/spec.md`

## Summary

Deploy a self-hosted WAHA (WhatsApp HTTP API) service on the `homelab` host to automate repetitive manual WhatsApp tasks for the SGDF La Rochelle group (orchestrated with `n8n`). Following the established homelab service architecture (`n8n.nix`, `home-automation.nix`, `filebrowser.nix`, `portainer.nix`), WAHA is implemented as a rootful Podman OCI container (`docker.io/devlikeapro/waha:latest`) supervised by `systemd`. The container binds strictly to host loopback `127.0.0.1:3001:3000` (avoiding port `3000` conflict with `adguardhome.nix`) and is exposed externally over HTTPS at `waha.homelab.vaylet.fr` (`waha.${vars.homelabDomain}`) via the centralized Caddy reverse proxy. Session credentials, media files, and the runtime secret environment file (`/var/lib/waha/waha.env`) are stored under `/var/lib/waha` and declaratively preserved across ephemeral root reboots via `preservation.preserveAt."/persistent".directories`, with `WHATSAPP_RESTART_ALL_SESSIONS = "True"` ensuring automatic session reconnection after restarts.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:

- `virtualisation.oci-containers` (Podman backend configured in `modules/services/podman.nix`)
- `docker.io/devlikeapro/waha:latest` OCI container image
- `services.caddy` (Centralized Caddy reverse proxy with Cloudflare DNS-01 ACME in `modules/services/caddy.nix`)
- `preservation` (`github:nix-community/preservation` in `modules/core/preservation.nix`)
- `flake-parts` (`github:hercules-ci/flake-parts`) & `import-tree` (`github:denful/import-tree`)

**Storage**:

- Persistent host directory `/var/lib/waha` preserved at `/persistent/var/lib/waha` (`mode = "0750"`):
  - `/var/lib/waha/sessions` mounted to container `/app/.sessions` (WhatsApp session state & tokens)
  - `/var/lib/waha/media` mounted to container `/app/.media` (WhatsApp attachments & media)
  - `/var/lib/waha/waha.env` loaded via `environmentFiles` (API key and dashboard/Swagger credentials, never committed to Git)

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Flake evaluation: `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`.
- Target regression checks: `desktop-pc` and `iso` toplevel evaluation.
- Hermetic sandbox checks: `just check` (`nix flake check`).

**Target Platform**: Intel N150 (Alder Lake-N) Beelink S13 mini PC (`homelab`, `x86_64-linux`).

**Project Type**: Infrastructure as Code (Nix Flake, NixOS system configuration).

**Performance Goals**:

- Dashboard and Swagger UI at `https://waha.homelab.vaylet.fr` load within 3 seconds (`SC-001`).
- Automated WhatsApp API calls from local `n8n` workflows process within 2 seconds (`SC-003`).
- Paired WhatsApp sessions automatically reconnect within 60 seconds after service or host restart (`SC-002`).

**Constraints**:

- Strict Dendritic Pattern compliance: `modules/hosts/homelab.nix` must only assemble hardware and feature modules, with zero inline service definitions.
- Declarative state preservation: `/var/lib/waha` must be preserved under `/persistent` to survive ephemeral tmpfs root reboots.
- Zero plaintext secrets committed to version control (`waha.env` provisioned on host persistent storage).
- Loopback-only container port binding (`127.0.0.1:3001:3000`) so all external access is TLS-terminated by Caddy on `waha.homelab.vaylet.fr`.
- No regressions on `desktop-pc` or `iso` targets.

**Scale/Scope**:

- 1 new feature module: `modules/services/waha.nix`.
- 1 host definition updated: `modules/hosts/homelab.nix` (adding `services.waha` to `features`).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` drift | **PASS** | Service, reverse proxy virtual host, firewall rules, and `/persistent` state preservation are 100% declared in NixOS modules. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | `modules/services/waha.nix` colocates OCI container, Caddy virtualHost (`waha.${vars.homelabDomain}`), firewall, and preservation rules. `modules/hosts/homelab.nix` only adds `services.waha` to `features`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | Module structure adheres to `alejandra`, `statix`, and `deadnix` rules; verified in `quickstart.md`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | Dashboard credentials and API keys reside in `/var/lib/waha/waha.env` (`0600`) on persistent host storage outside Git, matching `/var/lib/caddy/cloudflare.env`. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Full evaluation and `just check` verification steps documented in `quickstart.md`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/013-add-waha-service/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Entities, attributes, schemas & invariants (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   ├── waha-service-contract.md
│   └── homelab-host-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
├── services/
│   ├── waha.nix                # New WAHA OCI container + Caddy vhost + firewall + preservation
│   ├── caddy.nix               # Existing centralized Caddy reverse proxy
│   ├── n8n.nix                 # Existing n8n workflow automation service
│   ├── filebrowser.nix
│   ├── home-automation.nix
│   ├── portainer.nix
│   ├── jellyfin.nix
│   ├── qbittorrent.nix
│   ├── podman.nix
│   └── ...
└── hosts/
    └── homelab.nix             # Enabled features list updated with services.waha
```

**Structure Decision**:
Follows the repository's standardized dendritic domain hierarchy. The new capability is defined in `modules/services/waha.nix` with colocated container, Caddy reverse proxy (`waha.${vars.homelabDomain}`), firewall, and `/persistent` preservation declarations, and enabled in `modules/hosts/homelab.nix` via `services.waha`.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *None* | All designs strictly comply with Constitution Principles I–V | N/A |
