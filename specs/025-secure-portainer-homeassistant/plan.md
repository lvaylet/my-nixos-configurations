# Implementation Plan: Secure Portainer and Home Assistant Network Exposure and Container Privileges

**Branch**: `025-secure-portainer-homeassistant` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/025-secure-portainer-homeassistant/spec.md`

## Summary

Resolve [Issue #32](https://github.com/lvaylet/my-nixos-configurations/issues/32) by restricting Portainer and Home Assistant network exposure to the central Caddy HTTPS reverse proxy and removing `--privileged` from the Portainer OCI container.

Technical approach:

1. Update `modules/services/portainer.nix`:
   - Bind Portainer's HTTPS web interface strictly to the host loopback interface (`ports = ["127.0.0.1:9443:9443"]`) and remove the unused Edge Agent port (`8000:8000`).
   - Remove `extraOptions = ["--privileged"]` so Portainer runs with standard container isolation and communicates with Podman strictly via the mounted `/var/run/podman/podman.sock:/var/run/docker.sock` UNIX socket.
   - Remove `networking.firewall.allowedTCPPorts = [8000 9443]` (relying on `modules/services/caddy.nix` for port `443`).
   - Preserve existing `/var/lib/portainer:/data` volume, `podman-portainer` systemd ordering, Caddy virtualHost (`portainer.${vars.homelabDomain}` -> `https://127.0.0.1:9443`), and `/var/lib/portainer` preservation rules.
2. Update `modules/services/home-automation.nix`:
   - Remove `networking.firewall.allowedTCPPorts = [443 8123]`, eliminating the redundant port `443` rule (already declared in `modules/services/caddy.nix`) and closing direct unencrypted LAN HTTP access on port `8123` so all external access is routed over HTTPS through Caddy (`https://ha.${vars.homelabDomain}` -> `127.0.0.1:8123`).
   - Preserve `--network=host` and `/run/dbus:/run/dbus:ro` so local mDNS/UPnP/Bluetooth discovery continues functioning on the local network.
3. Update `README.md` (`Homelab Hosted Services` table, `Reverse Proxy & Secure HTTPS Access` table, and `Home Assistant Reverse Proxy Authorization (UI Configuration)` section) to reflect loopback-only access (`N/A (loopback bound)`) and provide dual-shell (Bash/Fish) SSH tunnel instructions for initial Home Assistant reverse proxy setup.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable)

**Primary Dependencies**:

- `nixpkgs` (NixOS `virtualisation.oci-containers`, `virtualisation.podman`, `services.caddy`, `networking.firewall`)
- `preservation` (`github:nix-community/preservation`)
- `flake-parts` (`github:hercules-ci/flake-parts`)
- `import-tree` (`github:denful/import-tree`)
- Container images:
  - `docker.io/portainer/portainer-ce:lts` (Portainer CE)
  - `ghcr.io/home-assistant/home-assistant:2026.10` (Home Assistant)

**Storage**:

- `/var/lib/portainer:/data`: Persistent Portainer state preserved at `/persistent/var/lib/portainer` (`mode = "0755"`).
- `/var/lib/home-assistant:/config`: Persistent Home Assistant configuration preserved at `/persistent/var/lib/home-assistant` (`mode = "0750"`).

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix check`, `deadnix`)
- Flake evaluation & pre-commit checks: `just check` (`nix flake check`)
- Targeted attribute evaluation:
  - `nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.portainer.ports --json`
  - `nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.portainer.extraOptions --json`
  - `nix eval .#nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts --json`

**Target Platform**: NixOS (`x86_64-linux`) on `homelab`

**Project Type**: Infrastructure as Code / NixOS Multi-Host Configuration (Dendritic Pattern)

**Performance Goals**:

- Zero runtime overhead; eliminates two unnecessary host-wide port forwarders (`0.0.0.0:8000` and `0.0.0.0:9443`) in favour of a single loopback listener (`127.0.0.1:9443`).
- Clean flake evaluation across all configurations (`desktop-pc`, `homelab`, `iso`, `macbook-air-m4-15`).

**Constraints**:

- Strict Dendritic Pattern compliance: All Portainer and Home Assistant configuration rules remain colocated within `modules/services/portainer.nix` and `modules/services/home-automation.nix`.
- Security-first container & network hardening: Portainer must not use `--privileged` or expose ports `8000`/`9443` externally; Home Assistant must not expose port `8123` in `networking.firewall.allowedTCPPorts`.
- Living documentation: `README.md` must be updated in the same branch with dual Bash/Fish command parity.

**Scale/Scope**:

- 2 modified feature modules: `modules/services/portainer.nix`, `modules/services/home-automation.nix`
- 1 modified documentation file: `README.md`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic Configuration** | Pure evaluation, pinned `flake.lock`, no imperative state drift | **PASS** | All port bindings, container privilege flags, and firewall rules are declared purely in `modules/services/portainer.nix` and `modules/services/home-automation.nix`. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline host services | **PASS** | Changes are strictly encapsulated within `modules/services/portainer.nix` and `modules/services/home-automation.nix`; `modules/hosts/homelab.nix` remains unchanged. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean sandbox checks | **PASS** | Verified via `just fmt`, `just lint`, and `just check`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext credentials in repo; least-privilege container and network exposure | **PASS** | Removes `--privileged` from Portainer, binds Portainer to `127.0.0.1:9443`, and removes `8000`, `9443`, and `8123` from `networking.firewall.allowedTCPPorts`. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` and derivation evaluation prior to switching | **PASS** | Verified via `nix eval` of `homelab` container and firewall attributes and `just check`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` synchronized in the same branch with dual Bash/Fish syntax | **PASS** | `README.md` service tables, reverse proxy tables, and Home Assistant setup instructions updated with explicit Bash and Fish command blocks. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in a dedicated branch associated with a PR | **PASS** | Tracked under `025-secure-portainer-homeassistant` for Issue #32. |

---

## Project Structure

### Documentation (this feature)

```text
specs/025-secure-portainer-homeassistant/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── portainer-homeassistant-security-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
modules/
├── services/
│   ├── caddy.nix                  # Unchanged (central reverse proxy opening TCP port 443)
│   ├── home-automation.nix        # Updated: remove redundant 443 and unencrypted 8123 from firewall
│   └── portainer.nix              # Updated: bind 127.0.0.1:9443:9443, remove --privileged, remove 8000/9443 from firewall
└── hosts/
    └── homelab.nix                # Unchanged (enables services.portainer and services.home-automation)
README.md                          # Updated: reflect loopback-only binding and SSH tunnel setup in service tables and docs
```

**Structure Decision**: Single declarative Nix flake repository following the Dendritic Pattern (`modules/services/portainer.nix`, `modules/services/home-automation.nix`, and `README.md`).

---

## Complexity Tracking

No constitutional violations. Complexity tracking not required.
