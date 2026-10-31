# Interface Contract: Caddy & Tailscale TLS Integration

**Branch**: `feat-https-with-tailscale-and-caddy` | **Date**: 2026-10-14 | **Spec**: [spec.md](../spec.md)

This contract defines the schema, configuration options, and system-level guarantees for the Caddy reverse proxy and Tailscale TLS integration.

---

## 1. Tailscale Permission Contract (`modules/services/tailscale.nix`)

The Tailscale service module MUST declare permissions allowing the `caddy` system user to request TLS certificates:

```nix
{
  flake.modules.services.tailscale = {
    nixos = {
      services.tailscale = {
        enable = true;
        permitCertUid = "caddy";
      };
    };
  };
}
```

### Behavioral Guarantees

- Sets `TS_PERMIT_CERT_UID=caddy` in the `tailscaled.service` environment.
- Tailscale daemon authorizes LocalAPI certificate fetching over `/run/tailscale/tailscaled.sock` for user `caddy`.

---

## 2. Shared Identity Option Contract (`modules/core/vars.nix`)

The global variables submodule MUST define the base domain names:

```nix
options.flake.vars = lib.mkOption {
  type = lib.types.submodule {
    options = {
      # ...
      tailscaleDomain = lib.mkOption {
        type = lib.types.str;
        default = "tailc5cc8b.ts.net";
        description = "Tailscale tailnet base domain name";
      };
      homelabDomain = lib.mkOption {
        type = lib.types.str;
        default = "homelab.vaylet.fr";
        description = "Base domain for homelab services";
      };
    };
  };
};
```

---

## 3. Caddy Base Reverse Proxy Contract (`modules/services/caddy.nix`)

The centralized Caddy reverse proxy module MUST adhere to the following specification:

```nix
{
  flake.modules.services.caddy = {
    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
          hash = "sha256-tubXIDCJnO2mvdnPlZclwDhNGaeeYLSt7lnni3+pXDo=";
        };
        globalConfig = ''
          acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
          skip_install_trust
        '';
      };

      systemd.services.caddy = {
        after = [
          "local-fs.target"
          "tailscaled.service"
        ];
        serviceConfig.EnvironmentFile = [
          "-/var/lib/caddy/cloudflare.env"
        ];
      };

      preservation.preserveAt."/persistent".directories = lib.mkIf config.services.caddy.enable [
        {
          directory = "/var/lib/caddy";
          user = "caddy";
          group = "caddy";
          mode = "0750";
        }
      ];
    };
  };
}
```

### Behavioral Guarantees

1. **Startup Ordering**: `systemd.services.caddy` waits for both `local-fs.target` (ensuring `/var/lib/caddy` is mounted from `/persistent`) and `tailscaled.service`.
2. **Environment File Injection**: Caddy reads `CLOUDFLARE_API_TOKEN` from `/var/lib/caddy/cloudflare.env` without exposing credentials in Nix store files or git.
3. **State Preservation**: All Let's Encrypt certificates retrieved and cached in `/var/lib/caddy` survive host reboots.
4. **No Root CA Manipulation**: `skip_install_trust` ensures Caddy does not attempt write operations to read-only NixOS system paths.
