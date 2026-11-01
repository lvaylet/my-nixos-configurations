# Implementation Plan: Replace `sgdf-utils` with `sgdf-tools` API on Homelab

**Branch**: `039-replace-sgdf-tools-api` | **Date**: 2026-11-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/039-replace-sgdf-tools-api/spec.md`

## Summary

Replace the legacy Python/FastAPI `sgdf-utils` service on `homelab` with the new Rust/Axum `sgdf-tools` API (`sgdf-api`) and CLI (`sgdf-cli`) from `github:lvaylet/sgdf-tools`, while preserving the exact external HTTPS endpoint `https://sgdf.homelab.vaylet.fr` so existing scripts and n8n workflows are not disrupted.

Following the repository's dendritic module architecture:

1. **Flake Input Replacement (`flake.nix` & `flake.lock`)**: Remove `inputs.sgdf-utils` and declare `inputs.sgdf-tools` (`github:lvaylet/sgdf-tools`, with `inputs.nixpkgs.follows = "nixpkgs"`).
2. **Dendritic Service Module (`modules/services/sgdf-tools.nix`)**: Remove `modules/services/sgdf-utils.nix` and create `modules/services/sgdf-tools.nix` (`flake.modules.services.sgdf-tools`) importing `inputs.sgdf-tools.nixosModules.default`, enabling `services.sgdf-api` on `127.0.0.1:8000` with `dataDir = "/var/lib/sgdf-tools"`, installing `inputs.sgdf-tools.packages.${pkgs.stdenv.hostPlatform.system}.sgdf-cli` into `environment.systemPackages` (with `SGDF_API_URL = "http://127.0.0.1:8000"` in `environment.variables`), configuring a static `sgdf-tools:sgdf-tools` system user/group (`DynamicUser = lib.mkForce false`), bootstrapping a random 64-character hex `SGDF_AUTH_TOKEN` in `/var/lib/sgdf-tools/sgdf-tools.env` (`0600`) on first start, routing `sgdf.${vars.homelabDomain}` via Caddy to `127.0.0.1:8000`, and preserving `/var/lib/sgdf-tools` (`0750`, `sgdf-tools:sgdf-tools`) under `/persistent`.
3. **Host Feature Composition (`modules/hosts/homelab.nix`)**: Replace `services.sgdf-utils` with `services.sgdf-tools` in `features`.
4. **Living Documentation (`README.md`)**: Synchronize the Homelab services table, Caddy reverse proxy table, and post-deployment setup instructions (including dual Bash/Fish commands for retrieving `SGDF_AUTH_TOKEN`, importing intranet exports via `sgdf`, and cleaning up legacy `/persistent/var/lib/sgdf-utils` state).

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable, Flake-parts); upstream service written in Rust (Axum + SQLx SQLite).

**Primary Dependencies**:

- `sgdf-tools` (`github:lvaylet/sgdf-tools`, exporting `nixosModules.default` with `services.sgdf-api` and `packages.<system>.{sgdf-api,sgdf-cli}`)
- `services.caddy` (Centralized Caddy reverse proxy with Cloudflare DNS-01 in `modules/services/caddy.nix`)
- `preservation` (`github:nix-community/preservation` in `modules/core/preservation.nix`)
- `flake-parts` (`github:hercules-ci/flake-parts`) & `import-tree` (`github:denful/import-tree`)

**Storage**:

- Preserved state directory under `/persistent/var/lib/sgdf-tools` mounted at `/var/lib/sgdf-tools` (`0750`, `sgdf-tools:sgdf-tools`):
  - `/var/lib/sgdf-tools/sgdf.db`: Fresh SQLite database initialized automatically by `sgdf-api` SQLx migrations on startup (no migration of legacy `sgdf-utils` database).
  - `/var/lib/sgdf-tools/sgdf-tools.env`: Auto-generated environment file (`0600`, `sgdf-tools:sgdf-tools`) storing `SGDF_AUTH_TOKEN=<64-hex-chars>`.

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Flake evaluation: `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`.
- Hermetic sandbox checks: `just check` (`nix flake check`).
- Activation test on target: `just test homelab` (`nh os test .#homelab`).

**Target Platform**:

- Intel N150 Alder Lake-N mini PC (`homelab`, `x86_64-linux`).

**Project Type**: Infrastructure as Code (Nix Flake, NixOS system configuration).

**Performance Goals**:

- Zero disruption to the external endpoint URL `https://sgdf.homelab.vaylet.fr` (`SC-001`, `SC-003`).
- `GET https://sgdf.homelab.vaylet.fr/health` returns `200 OK` (`OK`) and authenticated endpoints respond over HTTPS (`SC-003`).
- 100% pass rate on repository static checks and `nix flake check` (`SC-002`).

**Constraints**:

- Strict Dendritic Pattern compliance: `modules/hosts/homelab.nix` only declares `services.sgdf-tools` in `features`; zero inline service definitions (Principle II).
- Impermanent root compatibility: Override upstream `DynamicUser = true` with `DynamicUser = lib.mkForce false` and static user/group `sgdf-tools:sgdf-tools` so `preservation` bind-mounts `/persistent/var/lib/sgdf-tools` cleanly (Principle I & II).
- Loopback isolation: Bind strictly to `127.0.0.1:8000` (avoiding `3000` reserved in `adguardhome.nix`, `3001` WAHA, `3002` Uptime Kuma, `4096` OpenCode, `4444` Code-Server, `5679` n8n, `8080` qBittorrent, `8081` Filebrowser, `8096` Jellyfin, `8123` Home Assistant, `9443` Portainer).
- Zero plaintext secrets in git: `SGDF_AUTH_TOKEN` generated dynamically at runtime in `/var/lib/sgdf-tools/sgdf-tools.env` (Principle IV).
- Living documentation synchronization: Update `README.md` in the same branch with dual Bash/Fish commands (Principle VI).
- Dedicated branch workflow: Work isolated in branch `039-replace-sgdf-tools-api` (Principle VII).

**Scale/Scope**:

- `flake.nix` and `flake.lock`: Replace `sgdf-utils` input with `sgdf-tools`.
- `modules/services/sgdf-utils.nix` (deleted) -> `modules/services/sgdf-tools.nix` (created).
- `modules/hosts/homelab.nix`: Replace `services.sgdf-utils` with `services.sgdf-tools`.
- `README.md`: Update service tables, reverse proxy table, and post-deployment instructions.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, pure evaluation, auxiliary inputs follow `nixpkgs` | **PASS** | `inputs.sgdf-tools` follows `nixpkgs` and is locked in `flake.lock`; `services.sgdf-api`, `sgdf-cli`, Caddy vhost, and `/persistent` preservation are 100% declarative. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | `modules/services/sgdf-tools.nix` colocates the NixOS service, CLI package, Caddy virtual host, and state preservation; `modules/hosts/homelab.nix` only lists `services.sgdf-tools` in `features`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | Verified via `just fmt`, `just lint`, and `just check` as defined in `quickstart.md`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets in git; strong runtime secret generation | **PASS** | `SGDF_AUTH_TOKEN` is generated at first boot via `/dev/urandom` into `/var/lib/sgdf-tools/sgdf-tools.env` (`0600`) on persistent storage, never committed to git. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> `just test` before `just switch` | **PASS** | Verification steps documented in `quickstart.md`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` updated in same branch for any added/modified/removed service; Bash/Fish parity | **PASS** | `README.md` updates specified in `contracts/homelab-host-contract.md` with explicit Bash and Fish command blocks. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in dedicated branch (`039-replace-sgdf-tools-api`), no direct commits to `main` | **PASS** | Active development is on branch `039-replace-sgdf-tools-api`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/039-replace-sgdf-tools-api/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Entities, attributes, schemas & invariants (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   ├── sgdf-tools-service-contract.md
│   └── homelab-host-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
flake.nix                                # Updated: replace sgdf-utils input with sgdf-tools
flake.lock                               # Updated: lock sgdf-tools and remove sgdf-utils
modules/
├── services/
│   ├── sgdf-tools.nix                   # New: sgdf-api service + sgdf-cli + Caddy proxy + preservation
│   ├── caddy.nix                        # Existing centralized Caddy reverse proxy
│   └── ...                              # (modules/services/sgdf-utils.nix removed)
├── hosts/
│   ├── homelab.nix                      # Updated: replace services.sgdf-utils with services.sgdf-tools
│   └── ...
README.md                                # Updated: services table, reverse proxy table, dual-shell guide
```

**Structure Decision**: Replace `modules/services/sgdf-utils.nix` with `modules/services/sgdf-tools.nix` (`flake.modules.services.sgdf-tools`), automatically discovered by `inputs.import-tree ./modules`. Update `modules/hosts/homelab.nix` and `README.md` in lockstep.

---

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No violations. All constitution quality gates pass cleanly.*
