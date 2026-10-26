# Quickstart & Validation Guide: Persist Tailscale State on Impermanent Homelab

**Feature Branch**: `023-persist-tailscale-state` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

This guide documents the runnable validation steps to verify that `/var/lib/tailscale` is declaratively registered with `preservation` on `homelab`, evaluates cleanly on `desktop-pc`, and passes all repository quality gates.

---

## 1. Prerequisites

Ensure you are on the feature branch `023-persist-tailscale-state`:

### Bash / Fish

```bash
git switch 023-persist-tailscale-state
```

---

## 2. Verify NixOS Option Evaluation

Verify that `preservation.preserveAt."/persistent".directories` on `homelab` includes `/var/lib/tailscale` with `user = "root"`, `group = "root"`, and `mode = "0700"` as specified in [tailscale-preservation-contract.md](contracts/tailscale-preservation-contract.md):

### Bash / Fish

```bash
# 1. Verify /var/lib/tailscale entry in homelab's preservation directories
nix eval .#nixosConfigurations.homelab.config.preservation.preserveAt.\"/persistent\".directories --apply ' builtins.filter (d: d.directory == "/var/lib/tailscale") ' --json

# 2. Verify preservation remains disabled on desktop-pc while tailscale remains enabled
nix eval .#nixosConfigurations.desktop-pc.config.preservation.enable --json
nix eval .#nixosConfigurations.desktop-pc.config.services.tailscale.enable --json
```

**Expected Outcome**:

- The `homelab` filter returns a single-element list with `"directory": "/var/lib/tailscale"`, `"group": "root"`, `"mode": "0700"`, and `"user": "root"`.
- `desktop-pc.config.preservation.enable` evaluates to `false` and `desktop-pc.config.services.tailscale.enable` evaluates to `true`.

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

## 4. Live Host Deployment & Reboot Persistence Verification

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

### 4.2 Verify Bind Mount, Permissions, and Reboot Survival

1. **Check `/var/lib/tailscale` mount and permissions on `homelab`**:

   ```sh
   ssh laurent@homelab "sudo stat -c '%a %U:%G %n' /var/lib/tailscale /persistent/var/lib/tailscale && findmnt /var/lib/tailscale"
   ```

   **Expected Outcome**: Both paths report `700 root:root` and `findmnt` confirms `/var/lib/tailscale` is bind-mounted from `/persistent/var/lib/tailscale`.

2. **Reboot `homelab` and verify automatic Tailscale reconnection**:

   ```sh
   ssh laurent@homelab "sudo reboot"
   ```

   Wait ~30 seconds for `homelab` to finish booting, then verify Tailscale SSH connectivity without LAN intervention:

   ```sh
   tailscale ssh laurent@homelab "tailscale status"
   ```

   **Expected Outcome**: `homelab` reconnects automatically to the tailnet under the same node identity and IP (`100.127.199.88`) without requiring `tailscale up` or re-authentication.
