# Implementation Plan: OpenCode v2 on Homelab with Shared Configuration and Web Access

**Branch**: `022-add-opencode-homelab` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/022-add-opencode-homelab/spec.md`

## Summary

Deploy OpenCode v2 on the `homelab` host while mutualizing configuration across workstations (`desktop-pc`, `macbook-air-m4-15`) and `homelab`. OpenCode v2 is introduced via a dedicated flake input (`github:anomalyco/opencode/v2.1.4`) pinned in `flake.lock`. Following the repository's dendritic module architecture, a unified module `modules/services/opencode.nix` is created to colocate:

1. Shell/CLI availability on `homelab` via `environment.systemPackages` with declarative user configuration.
2. A headless background daemon `systemd.services.opencode-web` executing `opencode serve --hostname 127.0.0.1 --port 4096` with runtime authentication credentials in `/var/lib/opencode/opencode.env`.
3. Centralized Caddy reverse proxy integration on `opencode.${vars.homelabDomain}` (`https://opencode.homelab.vaylet.fr`) with automatic Cloudflare DNS-01 TLS provisioning and WebSocket proxying.
4. Impermanence state preservation binding `/var/lib/opencode` to `/persistent/var/lib/opencode` (`0750`).
5. Shared Home Manager configuration setting `package = opencodePackage` and `tui.theme = "nord"` consumed across `desktop-pc` and `macbook-air-m4-15`, eliminating duplicate settings in `modules/desktop/apps.nix`.
6. Living documentation updates in `README.md` with explicit dual Bash and Fish command instructions.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable, Flake-parts)

**Primary Dependencies**:

- `opencode` (`github:anomalyco/opencode/v2.1.4` via flake input)
- `home-manager` (`github:nix-community/home-manager` `programs.opencode` module)
- `services.caddy` (Centralized Caddy reverse proxy with Cloudflare DNS-01 in `modules/services/caddy.nix`)
- `preservation` (`github:nix-community/preservation` in `modules/core/preservation.nix`)
- `flake-parts` (`github:hercules-ci/flake-parts`) & `import-tree` (`github:denful/import-tree`)

**Storage**:

- Persistent directory `/var/lib/opencode` preserved under `/persistent/var/lib/opencode` (`user = "opencode"`, `group = "opencode"`, `mode = "0750"`), storing OpenCode SQLite database, project workspaces, session history, and `opencode.env`.
- User configuration deployed to `/home/${vars.userName}/.config/opencode/opencode.json` via declarative tmpfiles rules.

**Testing**:

- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Flake evaluation: `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`.
- Target regression checks: `desktop-pc` and `macbook-air-m4-15` evaluation.
- Hermetic sandbox checks: `just check` (`nix flake check`).

**Target Platform**:

- Intel N150 Alder Lake-N mini PC (`homelab`, `x86_64-linux`).
- AMD Ryzen workstation (`desktop-pc`, `x86_64-linux`).
- Apple Silicon M4 laptop (`macbook-air-m4-15`, `aarch64-darwin`).

**Project Type**: Infrastructure as Code (Nix Flake, NixOS system configuration, Home Manager modules).

**Performance Goals**:

- Interactive CLI launches in under 2 seconds on `homelab` (`SC-001`).
- Web interface loads at `https://opencode.homelab.vaylet.fr` in under 3 seconds (`SC-002`).
- Service recovers and is operational within 30 seconds following a host reboot (`SC-004`).
- 100% of common OpenCode configurations shared without code duplication (`SC-003`).

**Constraints**:

- Strict Dendritic Pattern compliance: `modules/hosts/homelab.nix` only composes hardware and feature modules; zero inline services.
- Declarative state preservation: `/var/lib/opencode` must survive ephemeral tmpfs root reboots.
- Loopback isolation: `opencode serve` binds strictly to `127.0.0.1:4096`, avoiding all existing homelab service ports (`3000`, `3001`, `3002`, `5679`, `8080`, `8081`, `8096`, `8123`, `9443`).
- Zero secrets in version control: Server password stored in runtime `opencode.env` outside the Nix store (Constitution Principle IV).
- Living documentation synchronization: `README.md` updated in same branch with dual Bash and Fish instructions (Constitution Principle VI).
- Dedicated branch workflow: Changes isolated to branch `022-add-opencode-homelab` (Constitution Principle VII).

**Scale/Scope**:

- 1 updated root file: `flake.nix` (adding `opencode` flake input).
- 1 new feature module: `modules/services/opencode.nix`.
- 1 updated feature module: `modules/desktop/apps.nix` (refactoring OpenCode to use shared module).
- 1 updated host definition: `modules/hosts/homelab.nix` (adding `services.opencode` to `features`).
- 1 updated documentation file: `README.md` (updating architecture, hosted services table, and reverse proxy table with dual-shell instructions).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` or `/etc` drift | **PASS** | Flake input `opencode` pinned in `flake.nix`; service, systemd unit, Caddy virtual host, and `/persistent` preservation 100% declared in Nix expressions. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | `modules/services/opencode.nix` colocates NixOS service, Home Manager user settings, and Caddy proxy. `modules/hosts/homelab.nix` only adds `services.opencode` to `features`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | Design conforms strictly to `alejandra`, `statix`, and `deadnix` standards; verification pipeline documented in `quickstart.md`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | Web server authentication password generated/stored in runtime file `/var/lib/opencode/opencode.env` (mode 0600) outside Git and outside the Nix store. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Dry-run evaluations and `just check` sandbox checks specified in `quickstart.md`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` updated in same branch for any added/modified service; Bash/Fish parity | **PASS** | `README.md` updates explicitly contracted in `contracts/homelab-host-contract.md` with dual Bash and Fish code blocks. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in dedicated branch (`022-add-opencode-homelab`), no direct commits to `main` | **PASS** | Active development is on dedicated branch `022-add-opencode-homelab`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/022-add-opencode-homelab/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Entities, attributes, schemas & invariants (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   ├── opencode-service-contract.md
│   └── homelab-host-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
flake.nix                                # Flake inputs: add opencode input
modules/
├── services/
│   ├── opencode.nix                     # New: OpenCode v2 service + CLI + Home Manager config + Caddy proxy
│   ├── caddy.nix                        # Existing centralized Caddy reverse proxy
│   ├── uptime-kuma.nix                  # Existing Uptime Kuma monitoring service
│   ├── n8n.nix                          # Existing n8n workflow service
│   └── ...
├── desktop/
│   └── apps.nix                         # Refactored: consume mutualized OpenCode configuration
└── hosts/
    ├── homelab.nix                      # Updated: add services.opencode to features
    ├── desktop-pc.nix                   # Workstation host
    └── macbook-air-m4-15.nix            # macOS host
README.md                                # Updated service and reverse proxy tables with dual-shell commands
```

**Structure Decision**:
Adheres to the repository's dendritic module architecture. A unified capability module `modules/services/opencode.nix` encapsulates system daemon execution on `homelab`, Caddy reverse proxy configuration on `opencode.${vars.homelabDomain}`, persistent storage rules under `/persistent/var/lib/opencode`, and shared Home Manager configuration (`tui.theme = "nord"`) for `desktop-pc` and `macbook-air-m4-15`. Host declarations in `modules/hosts/homelab.nix` solely compose hardware and feature modules.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| *None* | All designs strictly comply with Constitution Principles I–VII | N/A |
