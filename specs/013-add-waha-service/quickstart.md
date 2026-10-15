# Quickstart Validation Guide: WAHA WhatsApp Automation Service for Homelab

**Branch**: `013-add-waha-service` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

This guide provides step-by-step procedures to validate that the WAHA WhatsApp automation service integration satisfies all functional requirements, contracts, and repository quality gates.

---

## Prerequisites

1. Working copy of `my-nixos-configurations` on branch `013-add-waha-service`.
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

Ensure that adding the `waha` service evaluates cleanly across all host targets without regression.

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

## Scenario 3: Verify WAHA Container & Environment Configuration

Inspect the evaluated container configuration for the WAHA service on `homelab` against [contracts/waha-service-contract.md](contracts/waha-service-contract.md).

```bash
# Verify container image
nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.waha.image
# Expected output: "docker.io/devlikeapro/waha:latest"

# Verify loopback-only port binding
nix eval --json .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.waha.ports
# Expected output: ["127.0.0.1:3001:3000"]

# Verify environment variables (timezone, base URL, auto-restart sessions)
nix eval --json .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.waha.environment
# Expected output includes:
#   "TZ": "Europe/Paris"
#   "WAHA_BASE_URL": "https://waha.homelab.vaylet.fr"
#   "WHATSAPP_RESTART_ALL_SESSIONS": "True"

# Verify persistent environment file wiring
nix eval --json .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.waha.environmentFiles
# Expected output: ["/var/lib/waha/waha.env"]

# Verify volume bindings
nix eval --json .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.waha.volumes
# Expected output: ["/var/lib/waha/sessions:/app/.sessions","/var/lib/waha/media:/app/.media"]
```

---

## Scenario 4: Verify Caddy Reverse Proxy & Firewall Configuration

Ensure `waha.homelab.vaylet.fr` is configured in Caddy and only HTTPS port `443` (not `3000` or `3001`) is exposed in the firewall.

```bash
# Verify Caddy virtualHost for waha.homelab.vaylet.fr
nix eval .#nixosConfigurations.homelab.config.services.caddy.virtualHosts.\"waha.homelab.vaylet.fr\".extraConfig
# Expected output: "reverse_proxy 127.0.0.1:3001\n"

# Verify firewall ports
nix eval --json .#nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts
# Expected output includes 443 and does NOT include 3000 or 3001
```

---

## Scenario 5: Verify Declarative State Preservation

Ensure `/var/lib/waha` is preserved across ephemeral root reboots under `/persistent`.

```bash
nix eval --json .#nixosConfigurations.homelab.config.preservation.preserveAt.\"/persistent\".directories
```

**Expected Outcome**:

- Output contains an entry with `"directory": "/var/lib/waha"` and `"mode": "0750"`.

---

## Scenario 6: Run Repository Quality Check (Hermetic Sandbox)

Execute the full suite of automated pre-commit and flake checks in an isolated sandbox.

```bash
just check
```

**Expected Outcome**:

- All git hooks (`alejandra`, `statix`, `deadnix`, `ripsecrets`, `trufflehog`, etc.) and flake check derivations succeed with exit code 0.

---

## Scenario 7: Post-Deployment Runtime Provisioning on `homelab`

After deploying the configuration to `homelab`:

1. Populate `/var/lib/waha/waha.env` (persisted at `/persistent/var/lib/waha/waha.env`) with your chosen credentials:

   ```ini
   WAHA_API_KEY=<your-random-api-key>
   WAHA_DASHBOARD_USERNAME=admin
   WAHA_DASHBOARD_PASSWORD=<your-dashboard-password>
   WHATSAPP_SWAGGER_USERNAME=admin
   WHATSAPP_SWAGGER_PASSWORD=<your-swagger-password>
   ```

2. Restart the service to pick up the credentials:

   ```bash
   sudo systemctl restart podman-waha.service
   ```

3. Open `https://waha.homelab.vaylet.fr/dashboard` in a browser, log in, start the `default` session, and pair your WhatsApp account via QR code or pairing code.
4. Connect `n8n` (`https://n8n.homelab.vaylet.fr`) to WAHA using base URL `http://127.0.0.1:3001` (or `https://waha.homelab.vaylet.fr`) and the `X-Api-Key` defined in `/var/lib/waha/waha.env`.
