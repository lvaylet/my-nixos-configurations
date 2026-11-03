# Implementation Plan: Reorganize README for Progressive Disclosure and Clarity

**Branch**: `040-reorganize-readme` | **Date**: 2026-11-03 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/040-reorganize-readme/spec.md`

---

## Summary

Reorganize the repository documentation by transforming the 612-line monolithic `README.md` into an inviting, high-level hub (< 200 lines) and extracting deep technical runbooks and exhaustive reference tables into a modular `docs/` hierarchy (`docs/hosts/`, `docs/services/`, `docs/reference/`).

Following the architectural choices confirmed during clarification:

1. **Root Hub (`README.md`)**: Provide an elevator pitch, host topology matrix, architecture overview (Dendritic Pattern), quickstart (Devbox and native flakes), common `just` recipes, summary service catalog table, quality gates overview, and an explicit documentation index pointing to `docs/`.
2. **Dedicated Host Runbooks (`docs/hosts/`)**:
   - `docs/hosts/macbook.md`: Full macOS bootstrap (`/etc/synthetic.conf`, `nix-darwin`), daily maintenance, and client access.
   - `docs/hosts/homelab.md`: Full headless impermanent bootstrap (`just build-iso`, `nixos-anywhere`), ephemeral root overview, and updates.
3. **Comprehensive Services Runbook (`docs/services/homelab-services.md`)**:
   - Deep configuration recipes for all 12 services (Caddy Cloudflare DNS tokens, WAHA pairing, Home Assistant proxy authorization, SGDF tools API, Uptime Kuma socket, OpenCode credentials, etc.) and shared `/data` storage permissions.
4. **Exhaustive Reference Guide (`docs/reference/shell-aliases.md`)**:
   - Move all systemctl, journalctl, Git (25+ aliases), and Fish tables, along with Nord theme specs, Noctalia wallpapers, FiraCode typography, and editor setups into a standalone reference document.
5. **Constitution & Quality Compliance**:
   - Maintain strict dual-shell (Bash & Fish) command parity across all documents (Principle VI).
   - Ensure all files pass `just lint-md` (`markdownlint-cli2`) and `just check`.

---

## Technical Context

**Language/Version**: Markdown (GitHub-Flavored Markdown), Nix Flakes tooling.

**Primary Dependencies**:

- `markdownlint-cli2` (Markdown style and formatting enforcement in `.markdownlint-cli2.yaml`)
- `just` (Command runner defined in `justfile`)
- Pre-commit hooks via `git-hooks.nix` in `modules/core/checks.nix`

**Storage**: Documentation files on the local filesystem.

**Testing**:

- Markdown linting: `just lint-md` (`markdownlint-cli2`)
- Markdown auto-formatting: `just fix-md` (`markdownlint-cli2 --fix`)
- Line count verification: `wc -l README.md` (< 200 lines)
- Relative link integrity: Automated script in `quickstart.md`
- Flake sandbox checks: `just check` (`nix flake check`)

**Target Platform**: GitHub web viewer, VS Code / code-server Markdown preview, local terminal viewers.

**Project Type**: Documentation Architecture & Repository Infrastructure.

**Performance Goals**:

- Reduce `README.md` line count from 612 lines down to under 200 lines (>= 65% reduction, `SC-001`).
- Readers find daily operations and dev shell access within 2 viewports (`SC-002`).
- 100% of operational commands maintain dual Bash/Fish parity (`SC-003`).
- 100% of Markdown files pass `markdownlint-cli2` with zero warnings (`SC-004`).

**Constraints**:

- Constitution Principle VI (Living Documentation & Dual-Shell Parity): Retain all service entries, ports, endpoints, and storage paths in the summary tables; keep all operational commands in both Bash and Fish.
- Relative link validity: Breadcrumb links `[← Back to README](../../README.md)` in all sub-documents.
- No plaintext secrets written into documentation.

**Scale/Scope**:

- `README.md` (modified, streamlined from 612 to < 200 lines)
- `docs/hosts/macbook.md` (created)
- `docs/hosts/homelab.md` (created)
- `docs/services/homelab-services.md` (created)
- `docs/reference/shell-aliases.md` (created)

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Status | Design Verification |
| --- | --- | --- | --- |
| **I. Declarative & Hermetic** | Reproducible configuration, pure evaluation | **PASS** | Documentation change only; does not affect Nix evaluations or flake hermeticity. |
| **II. Dendritic Modularity** | Feature colocation, auto-discovery via `import-tree` | **PASS** | Does not alter Nix module tree structure; documents existing architecture. |
| **III. Shift-Left Quality, Formatting & Static Analysis** | Clean formatting, zero lint errors, pre-commit sandbox pass | **PASS** | All markdown files will format cleanly with `markdownlint-cli2` (`just lint-md`). |
| **IV. Zero-Secrets Leakage** | No plaintext credentials in version control | **PASS** | All secret setup instructions use runtime generation commands; no tokens committed. |
| **V. Rigorous Verification & Safe Deployment Workflow** | `just check` passing | **PASS** | Verified via `just check` and `quickstart.md` validation scenarios. |
| **VI. Living Documentation & Dual-Shell Parity** | `README.md` updated in same branch, Bash/Fish parity for all commands | **PASS** | `README.md` retains service summary and reverse proxy tables; all setup recipes in `docs/` provide explicit **Bash** and **Fish** code blocks. |
| **VII. Dedicated Branch & Pull Request Workflow** | Work isolated in dedicated branch (`040-reorganize-readme`) | **PASS** | Work executed exclusively on branch `040-reorganize-readme`. |

---

## Project Structure

### Documentation (this feature)

```text
specs/040-reorganize-readme/
├── plan.md              # Implementation Plan (/speckit.plan output)
├── research.md          # Technical research & decisions (Phase 0 output)
├── data-model.md        # Documentation taxonomy, entities & navigation (Phase 1 output)
├── quickstart.md        # Runnable end-to-end validation scenarios (Phase 1 output)
├── contracts/           # Interface contracts (Phase 1 output)
│   ├── readme-contract.md
│   ├── host-runbooks-contract.md
│   ├── service-runbook-contract.md
│   └── reference-contract.md
├── checklists/
│   └── requirements.md  # Quality checklist (/speckit.specify output)
└── spec.md              # Feature specification (/speckit.specify output)
```

### Source Code / Documentation (repository root)

```text
my-nixos-configurations/
├── README.md                          # Concise landing hub (< 200 lines)
└── docs/
    ├── hosts/
    │   ├── macbook.md                 # Full macOS provisioning & operations
    │   └── homelab.md                 # Headless bare-metal bootstrap (ISO + nixos-anywhere)
    ├── services/
    │   └── homelab-services.md        # Detailed setup recipes for all 12 services
    └── reference/
        └── shell-aliases.md           # Exhaustive Git, systemctl, journalctl & theme specs
```

**Structure Decision**: The modular layout creates a clean separation between high-level orientation (`README.md`), platform provisioning manuals (`docs/hosts/`), service application recipes (`docs/services/`), and developer cheat sheets (`docs/reference/`).

---

## Complexity Tracking

> *No constitutional violations to justify; documentation modularization strictly adheres to all repository standards.*

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| None | N/A | N/A |
