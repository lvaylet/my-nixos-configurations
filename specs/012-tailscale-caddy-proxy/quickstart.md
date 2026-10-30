# Quickstart Validation Guide: Secure Remote Service Exposure via Tailscale and Caddy

**Branch**: `feat-https-with-tailscale-and-caddy` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

This guide provides step-by-step procedures to validate that the Caddy and Tailscale TLS integration for Home Assistant and n8n satisfies all requirements, contracts, and quality gates.

---

## Prerequisites

1. Working tree on branch `feat-https-with-tailscale-and-caddy`.
2. Nix with Flakes enabled (`nix-command flakes`).
3. `just` command runner available in the development environment.

---

## Scenario 1: Verify Code Formatting & Static Analysis

Verify that all updated Nix modules adhere to formatting rules and contain zero unused bindings or lint issues.

```bash
# 1. Format Nix expressions with alejandra
just fmt

# 2. Check for dead code (unused bindings) and syntax lints
just lint
```

**Expected Outcome**:

- All `.nix` files format cleanly with zero modifications needed after `just fmt`.
- `deadnix` and `statix check` complete with exit code 0 and zero warnings.

---

## Scenario 2: Validate Flake Evaluation & Target Isolation

Ensure that configuration changes evaluate cleanly across all host targets without regressions.

```bash
# 1. Evaluate homelab system toplevel derivation
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath

# 2. Ensure existing desktop-pc target evaluates without regression
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath

# 3. Ensure iso target evaluates without regression
nix eval .#nixosConfigurations.iso.config.system.build.toplevel.drvPath
```

**Expected Outcome**:

- All three evaluation commands succeed, returning valid `.drv` store paths without syntax, type, or evaluation errors.

---

## Scenario 3: Verify Tailscale TLS Permissions & Systemd Dependencies

Inspect the evaluated Tailscale and Caddy system configurations on `homelab`.

```bash
# 1. Verify Tailscale certificate authorization for Caddy
nix eval .#nixosConfigurations.homelab.config.services.tailscale.permitCertUid
# Expected output: "caddy"

# 2. Verify Caddy startup ordering waits for Tailscale daemon and storage
nix eval .#nixosConfigurations.homelab.config.systemd.services.caddy.after
# Expected output: list containing "local-fs.target" and "tailscaled.service"
```

**Expected Outcome**:

- Caddy is authorized to fetch Tailscale certificates.
- Caddy service orders after `tailscaled.service` and `local-fs.target`.

---

## Scenario 4: Verify Caddy Virtual Hosts & Reverse Proxy Routing

Inspect the virtual host declarations for Home Assistant and n8n.

```bash
# 1. Check virtual hosts registered in Caddy
nix eval --json .#nixosConfigurations.homelab.config.services.caddy.virtualHosts | jq 'keys'
# Expected output: JSON array containing "<hostname>.<tailscaleDomain>" and "<hostname>.<tailscaleDomain>:5678"

# 2. Inspect Home Assistant reverse proxy upstream
nix eval --raw .#nixosConfigurations.homelab.config.services.caddy.virtualHosts."homelab.tailnet-2900.ts.net".extraConfig
# Expected output contains: "reverse_proxy 127.0.0.1:8123"

# 3. Inspect n8n reverse proxy upstream
nix eval --raw .#nixosConfigurations.homelab.config.services.caddy.virtualHosts."homelab.tailnet-2900.ts.net:5678".extraConfig
# Expected output contains: "reverse_proxy 127.0.0.1:5679"

# 4. Verify n8n container loopback binding
nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.n8n.ports
# Expected output: [ "127.0.0.1:5679:5678" ]
```

**Expected Outcome**:

- Both virtual hosts route correctly to their respective local backend ports.
- n8n container port 5678 binds strictly to loopback (`127.0.0.1:5679`).

---

## Scenario 5: Verify Firewall Allowed Ports

Ensure required external ports are opened in the host firewall.

```bash
nix eval .#nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts
```

**Expected Outcome**:

- Output includes ports `443` (Home Assistant HTTPS), `5678` (n8n HTTPS), and `8123` (Home Assistant direct LAN access).

---

## Scenario 6: Verify State Preservation Across Reboots

Ensure Caddy certificates and n8n databases are preserved under `/persistent`.

```bash
nix eval .#nixosConfigurations.homelab.config.preservation.preserveAt."/persistent".directories
```

**Expected Outcome**:

- Output contains `/var/lib/caddy` owned by `caddy:caddy` (mode `0750`).
- Output contains `/var/lib/n8n` owned by `1000:1000` (mode `0750`).

---

## Scenario 7: Run Repository Quality Check (Hermetic Sandbox)

Execute the complete suite of git-hooks and flake checks in an isolated Nix sandbox.

```bash
just check
```

**Expected Outcome**:

- All pre-commit hooks, secret scanners, formatters, and flake check derivations pass with exit code 0.

---

## Scenario 8: Live Operational Verification (Post-Deployment)

1. Deploy or test configuration on `homelab`:

   ```bash
   just test configuration="homelab"
   ```

2. On a client device connected to the tailnet, open:
   - `https://homelab.<tailscaleDomain>`: Home Assistant dashboard loads over HTTPS with a trusted certificate; WebSockets connect without error.
   - `https://homelab.<tailscaleDomain>:5678`: n8n workflow editor loads over HTTPS with a trusted certificate.
3. Verify TLS certificate in browser or via curl:

   ```bash
   curl -Iv https://homelab.<tailscaleDomain>
   ```

   Confirm TLS handshake succeeds with a Let's Encrypt certificate matching the Tailscale domain name.
