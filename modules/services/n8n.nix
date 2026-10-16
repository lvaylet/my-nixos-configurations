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

      # Wait for `/var/lib/containers` and `/var/lib/n8n` to be mounted, and bootstrap shared runner token if missing.
      systemd.services = {
        "podman-n8n" = {
          after = [
            "local-fs.target"
          ];
          preStart = lib.mkBefore ''
            install -d -m 0750 -o 1000 -g 1000 /var/lib/n8n
            if [ ! -s /var/lib/n8n/runners.env ]; then
              umask 0077
              printf 'N8N_RUNNERS_AUTH_TOKEN=%s\n' "$(${pkgs.coreutils}/bin/head -c 32 /dev/urandom | ${pkgs.coreutils}/bin/od -An -tx1 | ${pkgs.coreutils}/bin/tr -d ' \n')" > /var/lib/n8n/runners.env
            fi
            chmod 0600 /var/lib/n8n/runners.env
          '';
        };

        "podman-n8n-runners".after = [
          "local-fs.target"
        ];
      };

      # Configure Caddy reverse proxy for n8n on n8n.<homelabDomain>.
      services.caddy = {
        enable = true;
        virtualHosts."n8n.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:5679
          '';
        };
      };

      # Open HTTPS port in firewall.
      networking.firewall.allowedTCPPorts = [
        443
      ];

      preservation.preserveAt."/persistent".directories = lib.mkIf (config.virtualisation.oci-containers.containers ? n8n) [
        # Persist n8n configuration, workflows, credentials, and SQLite database.
        {
          directory = "/var/lib/n8n";
          user = "1000";
          group = "1000";
          mode = "0750";
        }
      ];
    };
  };
}
