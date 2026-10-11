# Interface Contract: Homelab Host Composition

**Branch**: `006-integrate-homelab-config` | **Date**: 2026-10-10 | **Spec**: [spec.md](../spec.md)

This contract defines the schema and composition rules for the `homelab` target machine definition in `modules/hosts/homelab.nix`.

---

## 1. Host Composition Schema

`modules/hosts/homelab.nix` MUST be a top-level module registered through `flake.nixosConfigurations.homelab` via `config.flake.lib.mkHost`:

```nix
{ config, lib, ... }: {
  flake.nixosConfigurations.homelab = config.flake.lib.mkHost {
    system = "x86_64-linux";

    # Hardware & Partitioning (isolated from dendritic discovery)
    hardware = ./_hardware/homelab.nix;

    # Enabled Feature Modules
    features = with config.flake.modules; [
      # Core OS & Preservation
      core.base
      core.git
      core.preservation

      # Server Capabilities & Applications
      services.network
      services.ssh
      services.media
      services.filebrowser
      services.home-automation
      services.jellyfin
      services.qbittorrent
      services.portainer
      services.podman
      services.nix-ld
      services.ssd
    ];

    # Host-Specific Overrides
    extraModules = [
      {
        networking.hostName = "homelab";

        # Override default Limine bootloader in favor of GRUB 2 for hybrid MBR/GPT Disko
        boot.loader.limine.enable = lib.mkForce false;
        boot.loader.grub = {
          enable = true;
          efiSupport = true;
          efiInstallAsRemovable = true;
        };

        # Permit Root Login via SSH public keys for headless administrative access
        services.openssh.settings.PermitRootLogin = "prohibit-password";
        users.users.root.openssh.authorizedKeys.keys = [
          config.flake.vars.sshPublicKeyPersonal
        ] ++ config.flake.vars.sshPublicKeysWork;
      }
    ];
  };
}
```

---

## 2. Invariants & Rules

1. **Zero Inline Services**: `features` MUST only reference modular features from `config.flake.modules`. No service configuration, package lists, or firewall rules may be defined inline in `homelab.nix`.
2. **Excluded Legacy Services**: `services.adguardhome`, and non-source automation components (`mosquitto`, `zigbee2mqtt`) MUST NOT be included in `features`.
3. **No Breakage of Other Hosts**: Changes to shared feature modules MUST not affect `desktop-pc` or `iso` hosts.
