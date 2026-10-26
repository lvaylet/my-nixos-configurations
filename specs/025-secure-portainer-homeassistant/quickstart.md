# Quickstart & Validation Guide: Secure Portainer and Home Assistant Network Exposure and Container Privileges

**Feature Branch**: `025-secure-portainer-homeassistant` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

This guide documents the runnable validation steps to verify that Portainer binds strictly to `127.0.0.1:9443:9443` without `--privileged`, ports `8000`, `9443`, and `8123` are removed from the host firewall while port `443` remains open via Caddy, and all repository quality gates pass.

---

## 1. Prerequisites

Ensure you are on the dedicated feature branch:

### Bash / Fish

```bash
git switch 025-secure-portainer-homeassistant
```

---

## 2. Verify NixOS Option Evaluation

Verify that `homelab` evaluates with the expected Portainer port bindings, container options, and firewall rules as specified in [portainer-homeassistant-security-contract.md](contracts/portainer-homeassistant-security-contract.md):

### Bash / Fish

```bash
# 1. Verify Portainer binds strictly to 127.0.0.1:9443:9443 (port 8000 removed)
nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.portainer.ports --json

# 2. Verify Portainer runs without --privileged (extraOptions is empty)
nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.portainer.extraOptions --json

# 3. Verify ports 8000, 9443, and 8123 are absent from networking.firewall.allowedTCPPorts while 443 is present
nix eval .#nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts --apply 'ports: (builtins.elem 443 ports) && !(builtins.elem 8000 ports) && !(builtins.elem 9443 ports) && !(builtins.elem 8123 ports)' --json
```

**Expected Outcome**:

- Command 1 returns `["127.0.0.1:9443:9443"]`.
- Command 2 returns `[]`.
- Command 3 returns `true`.

---

## 3. Formatting, Linting & Flake Checks

Run all repository quality gates:

### Bash / Fish

```bash
just fmt
just lint
just check
```

**Expected Outcome**: All three commands exit with code `0` and zero warnings or errors.

---

## 4. Live Host Deployment & Verification

### 4.1 Deploy to `homelab`

#### Bash

```bash
export TARGET_IP=192.168.1.180
just deploy-homelab target="${TARGET_IP}"
```

#### Fish

```fish
set -gx TARGET_IP 192.168.1.180
just deploy-homelab target="$TARGET_IP"
```

### 4.2 Verify Runtime Container Security & Reverse Proxy Access

1. **Check that Portainer listens strictly on `127.0.0.1:9443` and runs with `Privileged: false`**:

   ```sh
   ssh laurent@homelab "sudo ss -tlnp | grep 9443 && sudo podman inspect portainer --format '{{.HostConfig.Privileged}}'"
   ```

   **Expected Outcome**:
   - `ss` shows `127.0.0.1:9443` (not `0.0.0.0:9443` or `*:9443`) and no listener on port `8000`.
   - `podman inspect` returns `false`.

2. **Verify HTTPS Reverse Proxy Access**:

   Open `https://portainer.homelab.vaylet.fr` and `https://ha.homelab.vaylet.fr` from a Tailscale-connected device and confirm both applications load over HTTPS and Portainer lists and manages local Podman containers via the socket.
