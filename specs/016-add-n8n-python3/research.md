# Technical Research: Enable Python 3 Script Execution for n8n Code Nodes on Homelab

**Branch**: `016-add-n8n-python3` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This document consolidates the root-cause analysis, architectural decisions, rationale, and alternatives evaluated for adding Python 3 to `homelab` and enabling Python 3 script execution inside n8n `Code` nodes.

---

## 1. Root Cause Analysis: Why n8n Fails to Run Python Code Nodes

### Findings

1. **Removal of Pyodide & Distroless/Hardened n8n Base Image**:
   - In modern n8n releases (`docker.io/n8nio/n8n:latest`, n8n >= 2.0), legacy WebAssembly Pyodide execution was removed in favor of **Native Python Task Runners**.
   - The main `docker.io/n8nio/n8n:latest` image is built on a minimal Node.js runtime (`n8nio/base`) that contains neither a `python3` binary nor the `@n8n/task-runner-python` virtual environment (`.venv`).
   - When `N8N_RUNNERS_MODE` is left at its default (`internal`), `PyTaskRunnerProcess.checkRequirements()` executes `python3 --version` and checks for `/usr/local/lib/node_modules/n8n/node_modules/@n8n/task-runner-python/.venv/bin/python` inside the `n8n` container. Because neither exists in `n8nio/n8n:latest`, n8n logs and displays:
     > `Failed to start Python task runner in internal mode. because Python 3 is missing from this system. Launching a Python runner in internal mode is intended only for debugging and is not recommended for production. Users are encouraged to deploy in external mode.`
2. **Host-Level Python 3 Absence**:
   - On the `homelab` NixOS host, `environment.systemPackages` (`modules/core/base.nix`) and `users.users.laurent.packages` (`modules/hosts/homelab.nix`) do not currently include `pkgs.python3`.
   - Even when `pkgs.python3` is installed on the `homelab` host, the containerized `n8n` service runs in an isolated Podman mount namespace and additionally requires the `@n8n/task-runner-python` package and external task runner architecture to execute Python `Code` nodes.

---

## 2. Architecture for n8n Python Code Execution: External Task Runner Sidecar (`n8nio/runners`)

### Decision

1. Install `pkgs.python3` system-wide on `homelab` via `environment.systemPackages` in `modules/services/n8n.nix` so Python 3 is directly available on the `homelab` host for CLI/administrative use (`FR-001`).
2. Configure `virtualisation.oci-containers.containers.n8n` in **external task runner mode** (`N8N_RUNNERS_MODE = "external"`, `N8N_RUNNERS_ENABLED = "true"`, `N8N_NATIVE_PYTHON_RUNNER = "true"`, `N8N_RUNNERS_BROKER_LISTEN_ADDRESS = "0.0.0.0"`, `N8N_RUNNERS_BROKER_PORT = "5679"`).
3. Deploy the official `docker.io/n8nio/runners:latest` image as a companion Podman OCI sidecar container (`virtualisation.oci-containers.containers.n8n-runners`) with `dependsOn = [ "n8n" ]`, connecting to the n8n task broker over the internal Podman bridge network (`N8N_RUNNERS_TASK_BROKER_URI = "http://n8n:5679"`).

### Rationale

- **Upstream-Supported Architecture**: Upstream n8n explicitly deprecates `internal` mode and ships the Python 3.13 interpreter and pre-built `@n8n/task-runner-python` virtual environment (`/opt/runners/task-runner-python/.venv/bin/python`) exclusively in the `docker.io/n8nio/runners:latest` image.
- **Process & Security Isolation**: Running `n8nio/runners` as a dedicated sidecar container isolates user-authored Python and JavaScript `Code` node execution from the main n8n process, database, and stored credentials.
- **Zero Local Image Compilation**: Using the official pre-built `docker.io/n8nio/runners:latest` OCI image avoids compiling custom container images or Python environments on the low-power Intel N150 `homelab` CPU.
- **Podman DNS Integration**: `modules/services/podman.nix` already enables `defaultNetwork.settings.dns_enabled = true`, allowing `n8n-runners` to resolve `http://n8n:5679` directly over the isolated Podman bridge network without exposing the broker port on the host LAN.

### Alternatives Considered

- **Installing `pkgs.python3` on the NixOS host only**: Insufficient on its own because `n8n` runs inside an isolated Podman OCI container (`docker.io/n8nio/n8n:latest`) and still requires the `@n8n/task-runner-python` WebSocket client package and `.venv`.
- **Bind-mounting Nix store `python3` into `n8nio/n8n:latest` in `internal` mode**: Rejected. Even if `python3` is mounted into the `n8n` container, `PyTaskRunnerProcess.checkRequirements()` immediately fails on its second check (`access(PyTaskRunnerProcess.getVenvPath())`) because `@n8n/task-runner-python/.venv` is not built in `n8nio/n8n:latest`. Furthermore, `internal` mode is deprecated upstream.
- **Building a custom Dockerfile extending `n8nio/n8n`**: Rejected. Introduces imperative image build steps or heavy Nix `dockerTools` rebuilds instead of using the official upstream `docker.io/n8nio/runners:latest` image.

---

## 3. Enabling Python Standard Library Imports & Timezone Parity (`/etc/n8n-task-runners.json`)

### Decision

Generate a declarative task runner launcher configuration file via `pkgs.writeText "n8n-task-runners.json"` and mount it read-only into the `n8n-runners` container at `/etc/n8n-task-runners.json:ro`:

- For `"runner-type": "python"`, configure `"env-overrides"` with:
  - `"N8N_RUNNERS_STDLIB_ALLOW": "*"` (enables importing all Python 3 standard library modules such as `json`, `datetime`, `re`, `math`, `urllib`, `hashlib`, `csv`, `collections`, `itertools`).
  - `"N8N_RUNNERS_EXTERNAL_ALLOW": "*"` (enables any third-party packages present in the runner environment).
- Include `"TZ"` and `"GENERIC_TIMEZONE"` in `"allowed-env"` for both `"javascript"` and `"python"` runners so Python scripts execute in `Europe/Paris` local time (`FR-005`).

### Rationale

- **Default Upstream Lockdown**: By default, `/etc/n8n-task-runners.json` inside `docker.io/n8nio/runners:latest` sets `"N8N_RUNNERS_STDLIB_ALLOW": ""` (empty string), which blocks every `import` statement in Python `Code` nodes—even standard library modules like `import json` or `import datetime`.
- **Launcher Override Mechanism**: In external mode, n8n's `task-runner-launcher` ignores `N8N_RUNNERS_STDLIB_ALLOW` set on the container environment because `/etc/n8n-task-runners.json` explicitly overrides it with `""` in `env-overrides`. Mounting a declarative `/etc/n8n-task-runners.json` from the Nix store cleanly enables standard library imports in a 100% reproducible, read-only manner.

### Alternatives Considered

- **Setting `N8N_RUNNERS_STDLIB_ALLOW=*` only as a container environment variable**: Rejected because the default `/etc/n8n-task-runners.json` inside `n8nio/runners:latest` contains `"env-overrides": { "N8N_RUNNERS_STDLIB_ALLOW": "" }`, which overwrites the container environment variable with an empty string.

---

## 4. Zero-Touch Shared Authentication Token (`N8N_RUNNERS_AUTH_TOKEN`)

### Decision

1. Store the shared task broker authentication token (`N8N_RUNNERS_AUTH_TOKEN`) in `/var/lib/n8n/runners.env` on the `homelab` host (automatically persisted under `/persistent/var/lib/n8n/runners.env`).
2. Auto-generate `/var/lib/n8n/runners.env` idempotently in `systemd.services."podman-n8n".preStart` if the file does not yet exist or is empty, using 32 bytes (64 hex characters) from `/dev/urandom` with `0600` permissions (`umask 0077`).
3. Pass `environmentFiles = [ "/var/lib/n8n/runners.env" ];` to both `virtualisation.oci-containers.containers.n8n` and `virtualisation.oci-containers.containers.n8n-runners`.

### Rationale

- **Zero Secrets in Git (Principle IV)**: No static token is hardcoded in `.nix` files or committed to version control.
- **Zero Manual Provisioning**: Unlike external API keys (Cloudflare, WAHA), `N8N_RUNNERS_AUTH_TOKEN` is strictly an internal shared secret between `n8n` and `n8n-runners` on the same host. Auto-generating it on first start eliminates manual SSH setup steps while keeping the token stable across restarts.
- **Pipefail Safety**: Using `head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n'` avoids `SIGPIPE` (exit code 141) under NixOS's `set -o errexit -o pipefail` in `preStart` scripts.

### Alternatives Considered

- **Hardcoding a static token in `modules/services/n8n.nix`**: Rejected as a violation of Constitution Principle IV (*Zero-Secrets Leakage & Security First*) and triggers secret-scanning hooks (`ripsecrets`, `trufflehog`).
- **Requiring manual `.env` creation by the operator before deployment**: Unnecessary operational friction for an internal inter-container handshake token; auto-generation in `preStart` is both secure and self-bootstrapping (while still allowing manual override if desired).
