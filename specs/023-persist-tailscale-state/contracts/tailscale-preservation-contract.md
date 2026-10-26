# Contract: Tailscale State Preservation Module & Documentation

**Feature**: `023-persist-tailscale-state`
**Date**: 2026-10-26

---

## 1. Dendritic Module Contract (`modules/services/tailscale.nix`)

The `services.tailscale` dendritic feature module MUST declare `preservation.preserveAt."/persistent".directories` guarded by `lib.mkIf config.services.tailscale.enable` alongside its existing `services.tailscale` and `systemd.services.tailscaled-set` definitions:

```nix
{
  flake.modules.services.tailscale = {
    nixos = {
      config,
      lib,
      ...
    }: {
      # Tailscale
      # Reference: https://mynixos.com/nixpkgs/options/services.tailscale
      services.tailscale = {
        enable = true;
        # Authorize Caddy to fetch TLS certificates via LocalAPI
        permitCertUid = "caddy";
        # Enable Tailscale SSH for identity-based access over the tailnet
        extraSetFlags = [
          "--ssh"
        ];
      };

      # Ensure tailscaled-set runs immediately during `nixos-rebuild switch`
      # (via multi-user.target) without requiring a manual tailscaled restart.
      systemd.services.tailscaled-set = {
        wantedBy = ["multi-user.target"];
        partOf = ["tailscaled.service"];
        serviceConfig.RemainAfterExit = true;
      };

      preservation.preserveAt."/persistent".directories = lib.mkIf config.services.tailscale.enable [
        {
          directory = "/var/lib/tailscale";
          user = "root";
          group = "root";
          mode = "0700";
        }
      ];
    };
  };
}
```

### Evaluation Postconditions

1. On `homelab`:
   - `config.preservation.enable == true`
   - `config.services.tailscale.enable == true`
   - `config.preservation.preserveAt."/persistent".directories` contains an entry with:
     - `directory == "/var/lib/tailscale"`
     - `user == "root"`
     - `group == "root"`
     - `mode == "0700"`
2. On `desktop-pc`:
   - `config.preservation.enable == false`
   - `config.services.tailscale.enable == true`
   - Host configuration evaluates cleanly with zero errors.

---

## 2. Documentation Contract (`README.md`)

`README.md` MUST be updated within the same branch to:

1. Include **Tailscale** in the `Homelab Hosted Services` table (or document `/var/lib/tailscale` persistence clearly in the `Homelab Hosted Services` / `Tailscale SSH Access Control Policy` sections) showing that `/var/lib/tailscale` is persisted under `/persistent/var/lib/tailscale` (`root:root`, `0700`) across ephemeral `tmpfs` reboots.
2. Provide explicit **Bash** and **Fish** command variants whenever shell syntax differs.
