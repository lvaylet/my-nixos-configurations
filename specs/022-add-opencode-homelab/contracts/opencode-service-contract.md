# Interface Contract: OpenCode Service & Module

**Feature Branch**: `022-add-opencode-homelab` | **Date**: 2026-10-25

## 1. Module Definition Contract

The OpenCode feature is declared in `modules/services/opencode.nix` complying with the repository's dendritic module hierarchy:

```nix
{
  inputs,
  ...
}: {
  flake.modules.services.opencode = {
    # NixOS system service, shell package, and reverse proxy for homelab and desktop-pc
    nixos = {
      config,
      lib,
      pkgs,
      vars,
      ...
    }: { ... };

    # Home Manager configuration for desktop-pc and macbook-air-m4-15
    homeManager = {
      config,
      lib,
      pkgs,
      ...
    }: { ... };

    # Darwin-specific configuration for macbook-air-m4-15 (if needed)
    darwin = {
      config,
      lib,
      pkgs,
      ...
    }: { ... };
  };
}
```

## 2. NixOS Service Interface Contract

When enabled on `homelab`:

### 2.1 Package & CLI Availability

- `environment.systemPackages` MUST include the OpenCode v2 package derivation (`inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode`).
- The `opencode` binary MUST be directly invocable in interactive shells by the primary user (`laurent`).

### 2.2 Systemd Web Daemon Specification

- **Unit Name**: `systemd.services.opencode-web`
- **Description**: `"OpenCode v2 Web Service"`
- **After**: `[ "network.target" "local-fs.target" ]`
- **Service Configuration**:
  - `ExecStart = "${opencodePackage}/bin/opencode serve --hostname 127.0.0.1 --port 4096"`
  - `WorkingDirectory = "/var/lib/opencode"`
  - `User = "opencode"`
  - `Group = "opencode"`
  - `Restart = "always"`
  - `RestartSec = 5`
  - `EnvironmentFile = "-/var/lib/opencode/opencode.env"`
- **Pre-Start**:
  - Ensures `/var/lib/opencode` exists with permissions `0750` owned by `opencode:opencode`.
  - If `/var/lib/opencode/opencode.env` does not exist, generates a secure random password `OPENCODE_SERVER_PASSWORD=<random>` with permissions `0600`.

### 2.3 Caddy Reverse Proxy Specification

- **Virtual Host**: `opencode.${vars.homelabDomain}` (`opencode.homelab.vaylet.fr`)
- **Directives**:

  ```caddy
  reverse_proxy 127.0.0.1:4096
  ```

- **Firewall**: Port `443` allowed in `networking.firewall.allowedTCPPorts`.

### 2.4 State Preservation

- **Preserved Directory**: `/var/lib/opencode` bound under `/persistent/var/lib/opencode` with mode `0750` owned by `opencode:opencode`.

---

## 3. Home Manager Interface Contract

When enabled on `desktop-pc` and `macbook-air-m4-15`:

- `programs.opencode.enable = true`
- `programs.opencode.package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode`
- `programs.opencode.tui.theme = "nord"`
- Web service on workstations is disabled by default (`programs.opencode.web.enable = false;` unless specifically requested).

---

## 4. Web Access & Authentication Contract

- **Endpoint**: `https://opencode.homelab.vaylet.fr`
- **Protocol**: HTTPS (TLS 1.3/1.2 terminated by Caddy)
- **Authentication**: HTTP Basic Auth or session cookie verified by OpenCode server daemon.
  - Username: `opencode`
  - Password: `${OPENCODE_SERVER_PASSWORD}`
- **Unauthenticated Requests**: Responded with HTTP 401 Unauthorized or redirected to login form.
