# Interface Contract: n8n Python 3 Task Runner Integration

**Branch**: `016-add-n8n-python3` | **Date**: 2026-10-15 | **Spec**: [spec.md](../spec.md)

This contract defines the module structure, container orchestration, and documentation guarantees for enabling Python 3 on `homelab` and inside n8n `Code` nodes (`modules/services/n8n.nix` and `README.md`).

---

## 1. NixOS Service Module Contract (`modules/services/n8n.nix`)

`modules/services/n8n.nix` MUST export `flake.modules.services.n8n` with the following guarantees:

```nix
{
  flake.modules.services.n8n = {
    nixos = {
      config,
      lib,
      pkgs,
      vars,
      ...
    }: let
      taskRunnersConfig = pkgs.writeText "n8n-task-runners.json" (builtins.toJSON {
        task-runners = [
          {
            runner-type = "javascript";
            workdir = "/home/runner";
            command = "/usr/local/bin/node";
            args = [
              "--disallow-code-generation-from-strings"
              "--disable-proto=delete"
              "/opt/runners/task-runner-javascript/dist/start.js"
            ];
            health-check-server-port = "5681";
            allowed-env = [
              "PATH"
              "TZ"
              "GENERIC_TIMEZONE"
              "NODE_OPTIONS"
              "NODE_PATH"
              "N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT"
              "N8N_RUNNERS_GRACEFUL_SHUTDOWN_TIMEOUT"
              "N8N_RUNNERS_SHUTDOWN_FORCE_KILL_MARGIN"
              "N8N_RUNNERS_TASK_TIMEOUT"
              "N8N_RUNNERS_MAX_CONCURRENCY"
              "N8N_SENTRY_DSN"
              "N8N_VERSION"
              "ENVIRONMENT"
              "DEPLOYMENT_NAME"
              "HOME"
            ];
            env-overrides = {
              NODE_FUNCTION_ALLOW_BUILTIN = "*";
              NODE_FUNCTION_ALLOW_EXTERNAL = "moment";
              N8N_RUNNERS_HEALTH_CHECK_SERVER_HOST = "0.0.0.0";
            };
          }
          {
            runner-type = "python";
            workdir = "/home/runner";
            command = "/opt/runners/task-runner-python/.venv/bin/python";
            args = [
              "-I"
              "-B"
              "-X"
              "disable_remote_debug"
              "-m"
              "src.main"
            ];
            health-check-server-port = "5682";
            allowed-env = [
              "PATH"
              "TZ"
              "GENERIC_TIMEZONE"
              "N8N_RUNNERS_LAUNCHER_LOG_LEVEL"
              "N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT"
              "N8N_RUNNERS_GRACEFUL_SHUTDOWN_TIMEOUT"
              "N8N_RUNNERS_TASK_TIMEOUT"
              "N8N_RUNNERS_MAX_CONCURRENCY"
              "N8N_SENTRY_DSN"
              "N8N_VERSION"
              "ENVIRONMENT"
              "DEPLOYMENT_NAME"
            ];
            env-overrides = {
              N8N_RUNNERS_STDLIB_ALLOW = "*";
              N8N_RUNNERS_EXTERNAL_ALLOW = "*";
            };
          }
        ];
      });
    in {
      # Make Python 3 available on the host alongside n8n.
      environment.systemPackages = with pkgs; [
        python3
      ];

      # Run n8n and its task-runners sidecar as OCI containers with `systemd`.
      virtualisation.oci-containers.containers = {
        n8n = {
          image = "docker.io/n8nio/n8n:latest";
          volumes = [
            "/var/lib/n8n:/home/node/.n8n"
          ];
          environment = {
            TZ = "Europe/Paris";
            GENERIC_TIMEZONE = "Europe/Paris";
            N8N_PORT = "5678";
            N8N_PROTOCOL = "https";
            N8N_DEFAULT_BINARY_DATA_MODE = "filesystem";
            N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
            N8N_RUNNERS_ENABLED = "true";
            N8N_RUNNERS_MODE = "external";
            N8N_RUNNERS_BROKER_LISTEN_ADDRESS = "0.0.0.0";
            N8N_RUNNERS_BROKER_PORT = "5679";
            N8N_NATIVE_PYTHON_RUNNER = "true";
            WEBHOOK_URL = "https://n8n.${vars.homelabDomain}/";
          };
          environmentFiles = [
            "/var/lib/n8n/runners.env"
          ];
          ports = [
            # Bind strictly to localhost: external access goes through Caddy reverse proxy on port 443.
            "127.0.0.1:5679:5678"
          ];
          user = "1000:1000";
        };

        n8n-runners = {
          image = "docker.io/n8nio/runners:latest";
          dependsOn = [
            "n8n"
          ];
          volumes = [
            "${taskRunnersConfig}:/etc/n8n-task-runners.json:ro"
          ];
          environment = {
            TZ = "Europe/Paris";
            GENERIC_TIMEZONE = "Europe/Paris";
            N8N_RUNNERS_TASK_BROKER_URI = "http://n8n:5679";
          };
          environmentFiles = [
            "/var/lib/n8n/runners.env"
          ];
          user = "1000:1000";
        };
      };
      ...
    };
  };
}
```

---

## 2. Behavioral & Documentation Guarantees

1. **Systemd Startup & Token Provisioning**:
   - `systemd.services."podman-n8n".preStart` idempotently creates `/var/lib/n8n/runners.env` containing `N8N_RUNNERS_AUTH_TOKEN=<64-hex-chars>` with `0600` permissions if missing.
   - `systemd.services."podman-n8n-runners"` waits for both `local-fs.target` and `podman-n8n.service`.
2. **Living Documentation (`README.md`)**:
   - The **Homelab Hosted Services** table in `README.md` MUST reflect that `n8n` includes the `n8nio/runners` sidecar for native Python 3 and JavaScript `Code` node execution.
