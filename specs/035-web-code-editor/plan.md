# Implementation Plan: Remote Web Code Editor on Homelab

**Branch**: `035-web-code-editor` | **Date**: 2026-10-30 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/035-web-code-editor/spec.md`

## Summary

Deploy a web-based code editor on `homelab` to allow remote inspection and editing of code through a web browser when SSH connectivity is unavailable. Following user decisions and technical research, the implementation uses **`code-server`** (v4.x by Coder) via the native NixOS service module (`services.code-server`).

Following the repository's dendritic module architecture, a cohesive feature module `modules/services/code-server.nix` is created to colocate:
1. Native `services.code-server` configuration running under unprivileged user `laurent:users`, bound strictly to `127.0.0.1:4444`.
2. Workspace root default set to `/home/laurent` with the development toolchain (`git`, `just`, `nh`, `nix`, `nixos-rebuild`, `ripgrep`, `direnv`) provided in the integrated terminal's `PATH`.
3. Authentication delegated to the private Tailscale network overlay (`auth = "none"`), providing direct keyless access without secondary password prompts.
4. Centralized Caddy reverse proxy integration on `code.homelab.vaylet.fr` with automatic Cloudflare DNS-01 TLS certificate provisioning.
5. Ephemeral state preservation under `/persistent/home/laurent` for user extensions (`.local/share/code-server`) and preferences (`.config/code-server`).
6. Feature composition in `modules/hosts/homelab.nix` and living documentation updates in `README.md` with explicit dual Bash and Fish instructions.

---

## Technical Context

**Language/Version**: Nix (Flakes, Nixpkgs unstable, Flake-parts)

**Primary Dependencies**:
- `code-server` (packaged in `nixpkgs` via `services.code-server`)
- `services.caddy` (Centralized Caddy reverse proxy with Cloudflare DNS-01 in `modules/services/caddy.nix`)
- `preservation` (`github:nix-community/preservation` in `modules/core/preservation.nix`)
- `flake-parts` (`github:hercules-ci/flake-parts`) & `import-tree` (`github:denful/import-tree`)

**Storage**:
- Preserved user directories under `/persistent/home/laurent`:
  - `.local/share/code-server` (`0755`, `laurent:users`) for extensions and session cache.
  - `.config/code-server` (`0755`, `laurent:users`) for user configuration and keymaps.
- Workspace root `/home/laurent` (with `/home/laurent/workspace` already preserved across boots).

**Testing**:
- Formatting & static analysis: `just fmt` (`alejandra`), `just lint` (`statix`, `deadnix`).
- Flake evaluation: `nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`.
- Hermetic sandbox checks: `just check` (`nix flake check`).
- Activation test on target: `just test homelab` (`nh os test .#homelab`).

**Target Platform**:
- Intel N150 Alder Lake-N mini PC (`homelab`, `x86_64-linux`).

**Project Type**: Infrastructure as Code (Nix Flake, NixOS system configuration).

**Performance Goals**:
- Web code editor opens and loads files in under 5 seconds over Tailscale (`SC-001`).
- 100% of file edits written to host filesystem reliably without corruption (`SC-002`).
- 100% of web requests served via HTTPS with valid TLS certificate (`SC-003`).
- Service recovers and restores availability within 15 seconds after host restart (`SC-004`).
- Integrated terminal executes shell commands with full parity to local terminal sessions (`SC-005`).

**Constraints**:
- Strict Dendritic Pattern compliance: `modules/hosts/homelab.nix` only lists `services.code-server` in `features`; zero inline service definitions (Principle II).
- Impermanent root persistence: `.local/share/code-server` and `.config/code-server` preserved across tmpfs reboots (Principle I & II).
- Loopback isolation: `code-server` binds strictly to `127.0.0.1:4444`, avoiding conflicts with all existing services (`3001`, `3002`, `4096`, `5679`, `8000`, `8080`, `8081`, `8096`, `8123`, `9443`).
- Security model: Tailscale CGNAT IP isolation with `auth = "none"` in code-server (Principle IV).
- Living documentation synchronization: `README.md` updated in same branch with dual Bash and Fish instructions (Principle VI).
- Dedicated branch workflow: Changes isolated to branch `035-web-code-editor` (Principle VII).

**Scale/Scope**:
- 1 new feature module: `modules/services/code-server.nix`.
- 1 updated host definition: `modules/hosts/homelab.nix` (adding `services.code-server` to `features`).
- 1 updated documentation file: `README.md` (updating architecture, hosted services table, reverse proxy table, and access guide with dual-shell instructions).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic** | Nix flakes, pinned `flake.lock`, pure evaluation, no imperative `$HOME` or `/etc` drift | **PASS** | `services.code-server`, systemd unit, Caddy virtual host, and `/persistent` preservation are 100% declared in Nix expressions. |
| **II. Dendritic Modularity & Feature-Centric Composition** | Feature-centric colocation under `modules/`, auto-discovery via `import-tree`, zero inline services in host declarations | **PASS** | `modules/services/code-server.nix` colocates NixOS service, Caddy proxy, and user preservation. `modules/hosts/homelab.nix` only adds `services.code-server` to `features`. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | `alejandra` formatting, zero `statix`/`deadnix` errors, clean `nix flake check` sandbox | **PASS** | Module adheres to `alejandra`, `statix`, and `deadnix` standards; verification pipeline defined in `quickstart.md`. |
| **IV. Zero-Secrets Leakage & Security First** | No plaintext secrets, cryptographic password hashes, public keys only | **PASS** | `auth = "none"` eliminates plaintext password management; access is restricted exclusively to authenticated Tailscale devices over private CGNAT overlay. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` -> non-destructive evaluation before deployment | **PASS** | Flake evaluation, `just check`, and `just test homelab` verification workflow defined in `quickstart.md`. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` updated in same branch for any added/modified service; Bash/Fish parity | **PASS** | `README.md` updates contracted in `contracts/homelab-host-contract.md` with explicit dual Bash and Fish code blocks. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in dedicated branch (`035-web-code-editor`), no direct commits to `main` | **PASS** | Active development is on dedicated branch `035-web-code-editor`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/035-web-code-editor/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Entities, attributes, schemas & invariants (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   ├── code-server-service-contract.md
│   └── homelab-host-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code (repository root)

```text
modules/
├── services/
│   ├── code-server.nix                  # New: code-server service + Caddy proxy + state preservation
│   ├── caddy.nix                        # Existing centralized Caddy reverse proxy
│   ├── opencode.nix                     # Existing OpenCode service
│   └── ...
├── hosts/
│   ├── homelab.nix                      # Updated: add services.code-server to features
│   └── ...
README.md                                # Updated: services table, reverse proxy table, dual-shell guide
```

**Structure Decision**: A new feature module `modules/services/code-server.nix` is created in accordance with the dendritic architecture. The `homelab` host definition in `modules/hosts/homelab.nix` is updated to include `services.code-server` in its `features` array. Living documentation in `README.md` is updated synchronously.

---

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No violations. All constitution quality gates pass cleanly.*
