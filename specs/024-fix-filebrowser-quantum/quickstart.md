# Quickstart & Validation Guide: Fix FileBrowser Quantum Config Persistence and Localhost Binding

**Feature Branch**: `024-fix-filebrowser-quantum` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

This guide documents the runnable validation steps to verify that FileBrowser Quantum mounts `/var/lib/filebrowser:/config`, binds strictly to `127.0.0.1:8081:80`, removes `8081` from the host firewall, and passes all repository quality gates.

---

## 1. Prerequisites

Ensure you are on the dedicated feature branch:

### Bash / Fish

```bash
git switch 024-fix-filebrowser-quantum
```

---

## 2. Verify NixOS Option Evaluation

Verify that `homelab` evaluates with the expected container volumes, loopback port binding, and firewall rules as specified in [filebrowser-service-contract.md](contracts/filebrowser-service-contract.md):

### Bash / Fish

```bash
# 1. Verify container volumes include both /data:/srv and /var/lib/filebrowser:/config
nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.filebrowser.volumes --json

# 2. Verify container port is strictly bound to 127.0.0.1:8081:80
nix eval .#nixosConfigurations.homelab.config.virtualisation.oci-containers.containers.filebrowser.ports --json

# 3. Verify port 8081 is NOT present in networking.firewall.allowedTCPPorts
nix eval .#nixosConfigurations.homelab.config.networking.firewall.allowedTCPPorts --apply 'ports: !(builtins.elem 8081 ports)' --json
```

**Expected Outcome**:

- Command 1 returns `["/data:/srv","/var/lib/filebrowser:/config"]`.
- Command 2 returns `["127.0.0.1:8081:80"]`.
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

### 4.2 Verify Runtime Container Mounts and Loopback Socket

1. **Check that port `8081` listens strictly on `127.0.0.1` and `/var/lib/filebrowser` is mounted at `/config`**:

   ```sh
   ssh laurent@homelab "sudo ss -tlnp | grep 8081 && sudo podman inspect filebrowser --format '{{json .Mounts}}'"
   ```

   **Expected Outcome**:
   - `ss` shows `127.0.0.1:8081` (not `0.0.0.0:8081` or `*:8081`).
   - `podman inspect` shows `/var/lib/filebrowser` mounted to `/config` and `/data` mounted to `/srv`.

2. **Verify HTTPS Reverse Proxy Access**:

   Open `https://fb.homelab.vaylet.fr` from a Tailscale-connected device and confirm the FileBrowser Quantum web UI loads and retains user accounts across `sudo systemctl restart podman-filebrowser`.
