# Contract: Streamlined Continuous Integration Workflow

**File**: `.github/workflows/ci.yml`
**Purpose**: Execute fast, hermetic quality checks and flake validation on Pull Requests, pushes to `main`, scheduled crons, and manual dispatches without building full OS system closures.

---

## 1. Triggers & Event Filters

```yaml
on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main
  schedule:
    - cron: '0 4 * * 1'
  workflow_dispatch:
```

- **Trigger Conditions**:
  - `pull_request`: Any pull request opened, updated, or synchronized targeting `main`.
  - `push`: Any commit integrated into `main`.
  - `schedule`: Weekly scheduled run (Monday at 04:00 UTC) to verify ongoing upstream flake health.
  - `workflow_dispatch`: Manual on-demand execution.
- **Concurrency**:

  ```yaml
  concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true
  ```

  Cancels previous runs when newer commits are pushed to the same ref.

---

## 2. Security & Permissions

```yaml
permissions:
  contents: read
```

- **Read Access**: Clones repository read-only.
- **Least Privilege**: Zero write tokens or privileged credentials granted.

---

## 3. Workflow Structure Contract

### 3.1 Jobs Contract

The workflow MUST contain exactly **one** job:

```yaml
jobs:
  check:
    name: Flake Check & Static Analysis
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install Nix
        uses: DeterminateSystems/nix-installer-action@v16

      - name: Magic Nix Cache
        uses: DeterminateSystems/magic-nix-cache-action@v9

      - name: Run Flake Checks
        run: nix flake check --print-build-logs
```

### 3.2 Omission Contract (Zero Machine Builds)

- The workflow MUST NOT define `jobs.build`.
- No matrix strategy invoking `nix build .#nixosConfigurations.*` or `isoImage` shall be present.

---

## 4. Invariants & Guarantees

- **Invariant 1 (Speed & Quota)**: Workflow duration MUST complete within 3 minutes under normal runner network conditions.
- **Invariant 2 (Comprehensive Quality Gate)**: Any violation of:
  - Code formatting (`alejandra`)
  - Static analysis (`statix check`)
  - Dead code bindings (`deadnix`)
  - Secret detection (`ripsecrets`, `trufflehog`, `detect-private-keys`)
  - Flake syntax and NixOS module configuration evaluation (`nixosConfigurations`)
  MUST result in a non-zero exit code in step `Run Flake Checks` and block PR merge.
- **Invariant 3 (Idempotency)**: The workflow is read-only and idempotent; it never alters git branches or mutates persistent state.
