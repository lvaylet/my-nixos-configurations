# Interface Contract: n8n Service Module

**Branch**: `007-add-n8n-service` | **Date**: 2026-10-11 | **Spec**: [spec.md](../spec.md)

This contract defines the schema, configuration options, and behavioral guarantees for the n8n feature module in `modules/services/n8n.nix`.

---

## 1. Nix Module Interface

`modules/services/n8n.nix` MUST export a dendritic NixOS module under `flake.modules.services.n8n`:

```nix
{
  flake.modules.services.n8n = {
    nixos = {
      config,
      lib,
      ...
    }: {
      # Run service as OCI container with systemd.
      virtualisation.oci-containers.containers.n8n = {
        image = "docker.io/n8nio/n8n:latest";
        volumes = [
          "/var/lib/n8n:/home/node/.n8n"
        ];
        environment = {
          TZ = "Europe/Paris";
          GENERIC_TIMEZONE = "Europe/Paris";
          N8N_PORT = "5678";
          N8N_DEFAULT_BINARY_DATA_MODE = "filesystem";
          N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
        };
        ports = [
          "5678:5678"
        ];
        user = "1000:1000";
      };

      # Wait for local filesystems and preservation bind mounts to complete.
      systemd.services."podman-n8n".after = [
        "local-fs.target"
      ];

      # Open default n8n port in firewall.
      networking.firewall.allowedTCPPorts = [
        5678
      ];

      # Colocated state preservation for workflows, credentials, and SQLite database.
      preservation.preserveAt."/persistent".directories =
        lib.mkIf (config.virtualisation.oci-containers.containers ? n8n) [
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
```

---

## 2. Invariants & Guarantees

1. **Firewall Port Exposure**: TCP port `5678` MUST be included in `networking.firewall.allowedTCPPorts`.
2. **Persistent Directory Ownership**: `/var/lib/n8n` MUST be preserved under `/persistent` and owned by UID `1000` and GID `1000` with permissions `0750`.
3. **Mount Dependency**: The systemd service `podman-n8n` MUST order after `local-fs.target`.
4. **Timezone Harmonization**: Both `TZ` and `GENERIC_TIMEZONE` MUST match the host timezone (`Europe/Paris`).
5. **Auto-Discovery**: The module MUST be discovered automatically via `import-tree` as `config.flake.modules.services.n8n`.
