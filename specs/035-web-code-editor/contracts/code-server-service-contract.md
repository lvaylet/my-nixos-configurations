# Service Contract: Code-Server Service (`modules/services/code-server.nix`)

**Feature**: `035-web-code-editor`
**Contract Type**: NixOS Feature Module Interface
**Status**: Active

## 1. Module Export Specification

The module MUST be exported as a dendritic flake-parts module following repository architecture:

```nix
{
  flake.modules.services.code-server = {
    nixos = {
      config,
      lib,
      pkgs,
      vars,
      ...
    }: {
      # Declarations
    };
  };
}
```

---

## 2. Service Configuration Contract

The module MUST configure `services.code-server` with the following parameters:

```nix
services.code-server = {
  enable = true;
  user = vars.userName;
  group = "users";
  auth = "none";
  host = "127.0.0.1";
  port = 4444;
  disableTelemetry = true;
  disableUpdateCheck = true;
  extraArguments = [
    "/home/${vars.userName}"
  ];
  extraPackages = with pkgs; [
    bash
    coreutils
    direnv
    git
    just
    nh
    nix
    nixos-rebuild
    ripgrep
  ];
};
```

---

## 3. Reverse Proxy Contract

When `config.services.caddy.enable` is true, the module MUST declare the virtual host in Caddy:

```nix
services.caddy = lib.mkIf config.services.caddy.enable {
  virtualHosts."code.${vars.homelabDomain}" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:4444
    '';
  };
};
```

---

## 4. Preservation Storage Contract

When `config.services.caddy.enable` is true, the module MUST declare persistence bindings under the primary user:

```nix
preservation.preserveAt."/persistent".users.${vars.userName}.directories =
  lib.mkIf config.services.caddy.enable [
    ".local/share/code-server"
    ".config/code-server"
  ];
```

---

## 5. Security & Verification Rules

1. **Loopback Only**: `host = "127.0.0.1"` ensures `code-server` never listens on `0.0.0.0` or external network adapters.
2. **No Secondary Auth**: `auth = "none"` relies on Tailscale network isolation and Caddy HTTPS proxy.
3. **Impermanence Safe**: State and installed extensions must survive system generation reboots.
