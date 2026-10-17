# Implementation Plan: Uptime Kuma Monitoring Service for Homelab

**Branch**: `018-add-uptime-kuma` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/018-add-uptime-kuma/spec.md`

## Summary

Deploy a self-hosted Uptime Kuma monitoring service on the `homelab` host to track availability, response latency, and TLS certificate expiration across internal homelab services and external endpoints. Following the repository's dendritic service architecture (`caddy.nix`, `jellyfin.nix`, `qbittorrent.nix`, `n8n.nix`, `waha.nix`), Uptime Kuma is implemented in `modules/services/uptime-kuma.nix` using the native NixOS module (`services.uptime-kuma.enable = true`, MIT-licensed and pre-cached in `cache.nixos.org`). The service binds strictly to host loopback `127.0.0.1:3002` (avoiding port `3000` reserved by AdGuard Home and port `3001` bound by WAHA) and is exposed externally over HTTPS at `uptime.homelab.vaylet.fr` (`uptime.${vars.homelabDomain}`) via the centralized Caddy reverse proxy. To ensure seamless compatibility with `preservation` bind mounts on `homelab`'s ephemeral `tmpfs` root, `DynamicUser` is overridden to `false` in favor of a dedicated static `uptime-kuma` system user and group, persisting `/var/lib/uptime-kuma` under `/persistent/var/lib/uptime-kuma` (`0750`). Finally, `README.md` is updated within the same branch to document the new service and its reverse proxy endpoint.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:

- `services.uptime-kuma` (`pkgs.uptime-kuma` v2.5.6 in `nixpkgs`)
- `services.caddy` (Centralized Caddy reverse proxy with Cloudflare DNS-01 ACME in `modules/services/caddy.nix`)
- `preservation` (`github:nix-community/preservation` in `modules/core/preservation.nix`)
- `flake-parts` (`github:hercules-ci/flake-parts`) & `import-tree` (`github:denful/import-tree`)

**Storage**:

- Persistent host directory `/var/lib/uptime-kuma` preserved at `/persistent/var/lib/uptime-kuma` (`user = "uptime-kuma"`, `group = "uptime-kuma"`, `mode = "0750"`), storing Uptime Kuma's embedded SQLite database (`kuma.db`), monitor configurations, notification channels, status pages, and heartbeat history.

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Flake evaluation: `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`.
- Target regression checks: `desktop-pc` and `iso` toplevel evaluation.
- Hermetic sandbox checks: `just check` (`nix flake check`).

**Target Platform**: Intel N150 (Alder Lake-N) Beelink S13 mini PC (`homelab`, `x86_64-linux`).

**Project Type**: Infrastructure as Code (Nix Flake, NixOS system configuration).

**Performance Goals**:

- Dashboard at `https://uptime.homelab.vaylet.fr` loads within 3 seconds (`SC-001`).
- Live monitor status and heartbeat updates stream over WebSockets to the browser within 2 seconds (`SC-003`).
- Alert notifications dispatch within 5 seconds of a threshold transition (`SC-004`).
- Full state recovery and automatic monitoring resumption within 60 seconds after a host reboot (`SC-002`).

**Constraints**:

- Strict Dendritic Pattern compliance: `modules/hosts/homelab.nix` must only assemble hardware and feature modules, with zero inline service definitions.
- Declarative state preservation: `/var/lib/uptime-kuma` must be preserved under `/persistent` with a static `uptime-kuma` user/group (`DynamicUser = lib.mkForce false`) to survive ephemeral tmpfs root reboots without systemd `/var/lib/private` symlink conflicts.
- Loopback-only internal listener (`HOST = "127.0.0.1"`, `PORT = "3002"`) avoiding port `3001` (WAHA) and port `3000` (AdGuard Home), with all external traffic TLS-terminated by Caddy on `uptime.homelab.vaylet.fr`.
- Living documentation synchronization: `README.md` updated in the same branch with dual Bash/Fish parity where applicable.
- No regressions on `desktop-pc` or `iso` targets.

**Scale/Scope**:

- 1 new feature module: `modules/services/uptime-kuma.nix`.
- 1 host definition updated: `modules/hosts/homelab.nix` (adding `services.uptime-kuma` to `features`).
- 1 documentation file updated: `README.md` (adding Uptime Kuma to architecture overview, hosted services table, and reverse proxy endpoints table).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` or `/etc` drift | **PASS** | Service, static user/group, Caddy virtual host, firewall rules, and `/persistent` state preservation are 100% declared in NixOS modules. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | `modules/services/uptime-kuma.nix` colocates `services.uptime-kuma`, Caddy virtualHost (`uptime.${vars.homelabDomain}`), firewall, and preservation rules. `modules/hosts/homelab.nix` only adds `services.uptime-kuma` to `features`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | Module structure adheres to `alejandra`, `statix`, and `deadnix` rules; verified in `quickstart.md`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | Administrator credentials and notification tokens are managed interactively in Uptime Kuma's persisted SQLite database (`/persistent/var/lib/uptime-kuma/kuma.db`) outside Git. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Full evaluation and `just check` verification steps documented in `quickstart.md`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` updated in same branch for any added/modified service; Bash/Fish parity | **PASS** | `README.md` updates for service table, reverse proxy table, and architecture summary are explicitly contracted in `contracts/homelab-host-contract.md`. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in dedicated branch (`feat-add-uptime-kuma`), no direct commits to `main` | **PASS** | Active development is on dedicated branch `feat-add-uptime-kuma`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/018-add-uptime-kuma/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Entities, attributes, schemas & invariants (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   ├── uptime-kuma-service-contract.md
│   └── homelab-host-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
├── services/
│   ├── uptime-kuma.nix         # New Uptime Kuma native service + Caddy vhost + firewall + preservation
│   ├── caddy.nix               # Existing centralized Caddy reverse proxy
│   ├── n8n.nix                 # Existing n8n workflow automation service
│   ├── waha.nix                # Existing WAHA service (on 127.0.0.1:3001)
│   ├── filebrowser.nix
│   ├── home-automation.nix
│   ├── portainer.nix
│   ├── jellyfin.nix
│   ├── qbittorrent.nix
│   └── ...
└── hosts/
    └── homelab.nix             # Enabled features list updated with services.uptime-kuma
README.md                       # Updated service and reverse proxy tables
```

**Structure Decision**:
Follows the repository's standardized dendritic domain hierarchy. The new capability is defined in `modules/services/uptime-kuma.nix` with colocated service settings, static user/group, Caddy reverse proxy (`uptime.${vars.homelabDomain}`), firewall, and `/persistent` preservation declarations, enabled in `modules/hosts/homelab.nix` via `services.uptime-kuma`, and documented in `README.md`.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| *None* | All designs strictly comply with Constitution Principles I–VII | N/A |
