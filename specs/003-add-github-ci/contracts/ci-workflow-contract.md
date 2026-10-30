# Contract: GitHub Actions CI Workflow Interface

**Feature Branch**: `003-add-github-ci` | **Date**: 2026-08-12 | **Spec**: [spec.md](../spec.md)

## 1. Workflow Metadata & Triggers Contract

| Field | Contract Requirement | Description |
|---|---|---|
| **File Location** | `.github/workflows/ci.yml` | Standard GitHub Actions workflow definition path |
| **Workflow Name** | `CI` | Display name in GitHub Actions interface |
| **Permissions** | `contents: read` | Read-only token access for all jobs |
| **Concurrency Group** | `${{ github.workflow }}-${{ github.ref }}` | Groups runs by workflow and branch/PR ref |
| **Cancel In Progress** | `true` | Instantly cancels superseded workflow runs |

### Trigger Definitions

```yaml
on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main
  schedule:
    - cron: '0 4 * * 1' # Every Monday at 04:00 UTC
  workflow_dispatch:
```

---

## 2. Job 1 Contract: `check` (Quality Gate)

### Requirements & Behavior

- **Job ID**: `check`
- **Display Name**: `Flake Check & Static Analysis`
- **Runner**: `ubuntu-latest`
- **Preconditions**: Repository checkout (`actions/checkout@v4`)
- **Nix Installer**: `DeterminateSystems/nix-installer-action@v16`
- **Cache Daemon**: `DeterminateSystems/magic-nix-cache-action@v9`
- **Execution Command**: `nix flake check --all-systems --print-build-logs` (or `nix flake check`)
- **Success Criteria**: Exit code `0`. All formatting, dead code, statix linting, and secret scanning checks pass cleanly.
- **Failure Handling**: Immediate exit with diagnostic log annotations; prevents downstream `build` job from launching.

---

## 3. Job 2 Contract: `build` (Matrix System Closures)

### Requirements & Behavior

- **Job ID**: `build`
- **Display Name**: `Build System (${{ matrix.target }})`
- **Dependencies**: `needs: [check]`
- **Runner**: `ubuntu-latest`
- **Matrix Strategy**:
  - `fail-fast: false` (ensures failure in one configuration does not cancel logs for other targets)
  - `matrix.include`:
    - `target: desktop-pc`, `attr: .#nixosConfigurations.desktop-pc.config.system.build.toplevel`
    - `target: homelab`, `attr: .#nixosConfigurations.homelab.config.system.build.toplevel`
    - `target: iso`, `attr: .#nixosConfigurations.iso.config.system.build.isoImage`
- **Nix Installer**: `DeterminateSystems/nix-installer-action@v16`
- **Cache Daemon**: `DeterminateSystems/magic-nix-cache-action@v9`
- **Execution Command**: `nix build ${{ matrix.attr }} --print-build-logs`
- **Success Criteria**: Exit code `0`. System closure or ISO derivation evaluates and builds successfully.

---

## 4. Local Parity & CLI Mapping Contract

Every CI check must map 1:1 to a reproducible local command executable by developers on their workstations:

| CI Stage / Job | GitHub Actions Command | Local Developer Command (`just`) |
|---|---|---|
| Flake Check & Quality Gate | `nix flake check` | `just check` |
| Format Check | Sandboxed in `pre-commit-check` | `just fmt` |
| Static Linting | Sandboxed in `pre-commit-check` | `just lint` |
| Desktop PC Build | `nix build .#nixosConfigurations.desktop-pc.config.system.build.toplevel` | `just build configuration="desktop-pc"` |
| Homelab Build | `nix build .#nixosConfigurations.homelab.config.system.build.toplevel` | `just build configuration="homelab"` |
| ISO Build | `nix build .#nixosConfigurations.iso.config.system.build.isoImage` | `just build-iso` |
