# Quickstart Validation Guide: Uptime Kuma Monitoring Service for Homelab

**Branch**: `018-add-uptime-kuma` | **Date**: 2026-10-17 | **Spec**: [spec.md](spec.md)

This guide provides step-by-step procedures to validate that the Uptime Kuma monitoring service integration satisfies all functional requirements, contracts, and repository quality gates.

---

## Prerequisites

1. Working copy of `my-nixos-configurations` on branch `feat-add-uptime-kuma` (`018-add-uptime-kuma`).
2. Nix with Flakes enabled (`nix-command flakes`).
3. `just` task runner installed.

---

## Scenario 1: Verify Code Formatting & Static Analysis

Verify that all newly created and updated Nix expressions adhere to formatting rules and contain zero unused bindings or lint warnings.

```bash
# 1. Format Nix expressions with alejandra
just fmt

# 2. Check for dead code (unused bindings) and syntax lints
just lint
```

**Expected Outcome**:

- All files format cleanly without modifications needed after `just fmt`.
- `deadnix` and `statix check` complete with exit code 0 and zero warnings.

---

## Scenario 2: Validate Flake Evaluation & Target Isolation

Ensure that adding the `uptime-kuma` service evaluates cleanly across all host targets without regression.

```bash
# 1. Evaluate homelab system toplevel derivation
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath

# 2. Ensure existing desktop-pc target evaluates without regression
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath

# 3. Ensure iso target evaluates without regression
nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath
```

**Expected Outcome**:

- All three evaluation commands succeed, returning valid `.drv` store paths without evaluation errors.

---

## Scenario 3: Verify Uptime Kuma Service & Systemd Configuration

Inspect the evaluated NixOS configuration for the Uptime Kuma service on `homelab` against [contracts/uptime-kuma-service-contract.md](contracts/uptime-kuma-service-contract.md).

```bash
# Verify service is enabled
nix eval .#nixosConfigurations.homelab.config.services.uptime-kuma.enable
# Expected output: true

# Verify loopback-only listener settings (HOST=127.0.0.1, PORT=3002)
nix eval --json .#nixosConfigurations.homelab.config.services.uptime-kuma.settings
# Expected output includes:
#   "DATA_DIR": "/var/lib/uptime-kuma/"
#   "HOST": "127.0.0.1"
#   "PORT": "3002"

# Verify static user/group, DynamicUser=false, PrivateUsers=false, and Podman socket access on systemd unit
nix eval .#nixosConfigurations.homelab.config.systemd.services.uptime-kuma.serviceConfig.DynamicUser
# Expected output: false

nix eval .#nixosConfigurations.homelab.config.systemd.services.uptime-kuma.serviceConfig.PrivateUsers
# Expected output: false

nix eval .#nixosConfigurations.homelab.config.systemd.services.uptime-kuma.serviceConfig.User
# Expected output: "uptime-kuma"

nix eval --json .#nixosConfigurations.homelab.config.systemd.services.uptime-kuma.serviceConfig.SupplementaryGroups
# Expected output: ["podman"]

nix eval --json .#nixosConfigurations.homelab.config.systemd.services.uptime-kuma.serviceConfig.ReadWritePaths
# Expected output: ["/run/podman"]

nix eval .#nixosConfigurations.homelab.config.virtualisation.podman.dockerSocket.enable
# Expected output: true

# Verify systemd mount and socket ordering includes local-fs.target and podman.socket
nix eval --json .#nixosConfigurations.homelab.config.systemd.services.uptime-kuma.after
# Expected output includes "local-fs.target" and "podman.socket"
```

---

## Scenario 4: Verify Caddy Reverse Proxy & Firewall Configuration

Ensure `uptime.homelab.vaylet.fr` is configured in Caddy and only HTTPS port `443` (not `3002`) is exposed in the firewall.

```bash
# Verify Caddy virtualHost for uptime.homelab.vaylet.fr
nix eval .#nixosConfigurations.homelab.config.services.caddy.virtualHosts.\"uptime.homelab.vaylet.fr\".extraConfig
# Expected output: "reverse_proxy 127.0.0.1:3002\n"

# Verify firewall ports
nix eval --json .#nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts
# Expected output includes 443 and does NOT include 3002
```

---

## Scenario 5: Verify Declarative State Preservation

Ensure `/var/lib/uptime-kuma` is preserved across ephemeral root reboots under `/persistent`.

```bash
nix eval --json .#nixosConfigurations.homelab.config.preservation.preserveAt.\"/persistent\".directories
```

**Expected Outcome**:

- Output contains an entry with `"directory": "/var/lib/uptime-kuma"`, `"user": "uptime-kuma"`, `"group": "uptime-kuma"`, and `"mode": "0750"`.

---

## Scenario 6: Run Repository Quality Check (Hermetic Sandbox)

Execute the full suite of automated pre-commit and flake checks in an isolated sandbox.

```bash
just check
```

**Expected Outcome**:

- All git hooks (`alejandra`, `statix`, `deadnix`, `ripsecrets`, `trufflehog`, etc.) and flake check derivations succeed with exit code 0.

---

## Scenario 7: Post-Deployment Runtime Verification on `homelab`

After deploying the configuration to `homelab`:

1. Deploy the updated configuration:

   ```sh
   just switch configuration="homelab" target="homelab"
   ```

2. Verify the systemd service is active and listening on `127.0.0.1:3002`:

   ```sh
   scs uptime-kuma
   ```

3. Open `https://uptime.homelab.vaylet.fr` in a browser on an authorized Tailscale device, create the administrator account on first launch, and add health check monitors for your homelab services (e.g., `http://127.0.0.1:8123` for Home Assistant, `http://127.0.0.1:5679` for n8n, `http://127.0.0.1:3001` for WAHA, `http://127.0.0.1:8096` for Jellyfin).
