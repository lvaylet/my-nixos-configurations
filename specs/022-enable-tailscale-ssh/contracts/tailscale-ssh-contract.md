# Contract: Tailscale SSH Module & ACL Policy

**Feature**: `022-enable-tailscale-ssh`
**Date**: 2026-10-25

---

## 1. Dendritic Module Contract (`modules/services/tailscale.nix`)

The `services.tailscale` dendritic feature module MUST declare `extraSetFlags = ["--ssh"];` alongside `enable = true;` and `permitCertUid = "caddy";`:

```nix
{
  flake.modules.services.tailscale = {
    nixos = {
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
    };
  };
}
```

### Evaluation Postconditions

For every NixOS host importing `config.flake.modules.services.tailscale` (`homelab` and `desktop-pc`):

1. `config.services.tailscale.enable == true`
2. `config.services.tailscale.permitCertUid == "caddy"`
3. `config.services.tailscale.extraSetFlags == ["--ssh"]`
4. `config.systemd.services.tailscaled-set.wantedBy == ["tailscaled.service" "multi-user.target"]`
5. `config.systemd.services.tailscaled-set.serviceConfig.Type == "oneshot"` and `RemainAfterExit == true`
6. `config.systemd.services.tailscaled-set.script` contains `tailscale set --ssh`

---

## 2. Tailscale Admin Console ACL Contract

To authorize Tailscale SSH connections to `homelab` for both `laurent` and `root`, the tailnet policy file in the Tailscale Admin Console MUST include the following `ssh` stanza:

```jsonc
{
  "ssh": [
    {
      "action": "check",
      "src": ["autogroup:member"],
      "dst": ["homelab"],
      "users": ["laurent", "root"]
    }
  ]
}
```

---

## 3. Coexistence & Documentation Contract (`README.md`)

1. `modules/services/ssh.nix`, `modules/core/base.nix`, and `modules/hosts/homelab.nix` MUST retain their existing OpenSSH (`services.openssh`) and `authorizedKeys` declarations for physical LAN fallback (`192.168.1.180`).
2. `README.md` MUST document:
   - Tailscale SSH access (`ssh laurent@homelab` / `tailscale ssh laurent@homelab` or `100.127.199.88`) without static key distribution for new tailnet machines.
   - The required Tailscale ACL `ssh` policy snippet for the Admin Console.
   - Physical LAN OpenSSH fallback coexistence (`192.168.1.180`).
   - Dual **Bash** and **Fish** command blocks wherever shell-specific syntax is used.
