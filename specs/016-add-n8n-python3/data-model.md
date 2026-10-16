# Data Model: Enable Python 3 Script Execution for n8n Code Nodes on Homelab

**Branch**: `016-add-n8n-python3` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This document formalizes the entities, configuration schemas, relationships, and validation invariants for enabling Python 3 on `homelab` and inside n8n `Code` nodes.

---

## 1. Entities & Configuration Schemas

### Entity 1: Enhanced n8n Service Feature Module (`modules/services/n8n.nix`)

Represents the dendritic capability module encapsulating host Python 3 installation, the main `n8n` container in external task runner mode, the `n8n-runners` sidecar container, declarative runner configuration, token bootstrap, Caddy reverse proxy, and `/persistent` state preservation.

| Category | Option / Attribute | Value / Schema | Purpose |
| --- | --- | --- | --- |
| **Host Python 3** | `environment.systemPackages` | `[ pkgs.python3 ]` | Installs Python 3 system-wide on `homelab` (`FR-001`) |
| **Main Container (`n8n`)** | `virtualisation.oci-containers.containers.n8n.image` | `"docker.io/n8nio/n8n:latest"` | Upstream n8n application image |
| | `...environment.N8N_RUNNERS_ENABLED` | `"true"` | Enables task runners |
| | `...environment.N8N_RUNNERS_MODE` | `"external"` | Delegates Code node execution to external runner sidecar |
| | `...environment.N8N_RUNNERS_BROKER_LISTEN_ADDRESS` | `"0.0.0.0"` | Listens on container bridge interface for sidecar connection |
| | `...environment.N8N_RUNNERS_BROKER_PORT` | `"5679"` | Internal container port for task broker WebSocket server |
| | `...environment.N8N_NATIVE_PYTHON_RUNNER` | `"true"` | Enables native Python 3 runner in Code nodes (`FR-002`) |
| | `...environmentFiles` | `[ "/var/lib/n8n/runners.env" ]` | Injects shared `N8N_RUNNERS_AUTH_TOKEN` |
| **Runner Sidecar (`n8n-runners`)** | `virtualisation.oci-containers.containers.n8n-runners.image` | `"docker.io/n8nio/runners:latest"` | Official n8n JavaScript + Python 3.13 task runner image |
| | `...dependsOn` | `[ "n8n" ]` | Orders startup after `podman-n8n` and binds lifecycle |
| | `...user` | `"1000:1000"` | Non-root `runner:runner` user matching `node:node` |
| | `...environment.TZ` | `"Europe/Paris"` | Container process timezone (`FR-005`) |
| | `...environment.GENERIC_TIMEZONE` | `"Europe/Paris"` | Task runner timezone (`FR-005`) |
| | `...environment.N8N_RUNNERS_TASK_BROKER_URI` | `"http://n8n:5679"` | Connects to `n8n` task broker over internal Podman DNS network |
| | `...environmentFiles` | `[ "/var/lib/n8n/runners.env" ]` | Injects matching `N8N_RUNNERS_AUTH_TOKEN` |
| | `...volumes` | `[ "${taskRunnersConfig}:/etc/n8n-task-runners.json:ro" ]` | Mounts declarative launcher config enabling Python stdlib |
| **Systemd Supervision** | `systemd.services."podman-n8n".after` | `[ "local-fs.target" ]` | Waits for `/persistent` mounts before starting |
| | `systemd.services."podman-n8n".preStart` | Shell script generating `/var/lib/n8n/runners.env` if absent | Idempotent zero-touch generation of 256-bit `N8N_RUNNERS_AUTH_TOKEN` |
| | `systemd.services."podman-n8n-runners".after` | `[ "local-fs.target" "podman-n8n.service" ]` | Waits for local mounts and `podman-n8n` token bootstrap |

#### Relationships

- **Depends on**: `modules/services/podman.nix` for Podman container runtime and container-to-container DNS resolution (`defaultNetwork.settings.dns_enabled = true`).
- **Depends on**: `modules/core/preservation.nix` for preserving `/var/lib/n8n` (including `runners.env`) at `/persistent/var/lib/n8n`.
- **Depends on**: `modules/services/caddy.nix` for TLS termination on `https://n8n.homelab.vaylet.fr`.
- **Composed into**: `modules/hosts/homelab.nix` via `config.flake.modules.services.n8n`.

---

### Entity 2: Declarative Task Runner Launcher Configuration (`/etc/n8n-task-runners.json`)

Represents the read-only JSON configuration file generated in the Nix store via `pkgs.writeText "n8n-task-runners.json"` and mounted into `n8n-runners` at `/etc/n8n-task-runners.json:ro`.

| Runner Type | Field | Value | Purpose |
| --- | --- | --- | --- |
| `javascript` | `command` | `"/usr/local/bin/node"` | Node.js runtime for JS Code nodes |
| `javascript` | `env-overrides.NODE_FUNCTION_ALLOW_BUILTIN` | `"*"` | Allows built-in Node.js modules (including `crypto`) |
| `javascript` | `env-overrides.NODE_FUNCTION_ALLOW_EXTERNAL` | `"moment"` | Preserves built-in `moment` package compatibility |
| `python` | `command` | `"/opt/runners/task-runner-python/.venv/bin/python"` | Pre-built Python 3 virtual environment in `n8nio/runners` |
| `python` | `args` | `[ "-I" "-B" "-X" "disable_remote_debug" "-m" "src.main" ]` | Isolated native Python task runner entrypoint |
| `python` | `allowed-env` | Includes `"TZ"`, `"GENERIC_TIMEZONE"`, `"PATH"`, etc. | Propagates `Europe/Paris` timezone to Python scripts |
| `python` | `env-overrides.N8N_RUNNERS_STDLIB_ALLOW` | `"*"` | Allows importing all Python 3 standard library modules (`FR-003`) |
| `python` | `env-overrides.N8N_RUNNERS_EXTERNAL_ALLOW` | `"*"` | Allows importing any installed third-party Python modules |

---

### Entity 3: Persistent Storage Layout (`/persistent/var/lib/n8n`)

```text
/persistent/var/lib/n8n/
├── config                     # n8n encryption key and instance settings (1000:1000, 0600)
├── database.sqlite            # Primary SQLite database (workflows, credentials, executions)
├── runners.env                # Auto-generated shared N8N_RUNNERS_AUTH_TOKEN (root:root, 0600)
└── binaryData/                # Filesystem binary payload storage
```

| Path | Type | Owner:Group | Mode | Persistence Requirement |
| --- | --- | --- | --- | --- |
| `/var/lib/n8n` | Directory | `1000:1000` | `0750` | Preserved at `/persistent/var/lib/n8n` |
| `/var/lib/n8n/runners.env` | File | `0:0` (`root:root`) | `0600` | Read by rootful Podman (`--env-file`) for both `n8n` and `n8n-runners`; preserved across reboots |

---

## 2. Invariants & Validation Rules

1. **Host Python 3 Availability Invariant**: `pkgs.python3` MUST be present in `environment.systemPackages` on `homelab` so `python3 --version` succeeds in interactive and non-interactive sessions (`FR-001`).
2. **Task Broker Isolation Invariant**: The `n8n` task broker (`N8N_RUNNERS_BROKER_PORT = "5679"` inside the `n8n` container) MUST only be reachable on the internal Podman container network (`http://n8n:5679`) and MUST NOT be exposed on external host interfaces. Host loopback `127.0.0.1:5679` continues to map strictly to container web port `5678` for Caddy (`"127.0.0.1:5679:5678"`).
3. **Zero-Secrets Invariant**: `N8N_RUNNERS_AUTH_TOKEN` MUST NEVER appear in Nix source files or Git history; it is generated at runtime into `/var/lib/n8n/runners.env` if missing.
4. **Standard Library Allowlist Invariant**: `/etc/n8n-task-runners.json` in `n8n-runners` MUST set `"N8N_RUNNERS_STDLIB_ALLOW": "*"` so Python `Code` nodes can import standard library modules (`json`, `datetime`, `re`, `math`, `urllib`, `hashlib`, etc.) without restriction (`FR-003`).
5. **Target Isolation Invariant**: `desktop-pc` and `iso` NixOS configurations MUST remain completely unaffected.
