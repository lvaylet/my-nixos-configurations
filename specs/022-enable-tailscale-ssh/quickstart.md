# Quickstart & Validation Guide: Enable Tailscale SSH

**Feature Branch**: `022-enable-tailscale-ssh` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

This guide documents the runnable validation steps to verify that Tailscale SSH is declaratively enabled, coexists with physical LAN OpenSSH, and passes all repository quality gates.

---

## 1. Prerequisites

Ensure you are on the feature branch `022-enable-tailscale-ssh`:

### Bash / Fish

```bash
git switch 022-enable-tailscale-ssh
```

---

## 2. Verify NixOS Option & Systemd Unit Evaluation

Verify that `services.tailscale.extraSetFlags` and `systemd.services.tailscaled-set` evaluate as specified in [tailscale-ssh-contract.md](contracts/tailscale-ssh-contract.md):

### Bash / Fish

```bash
# 1. Verify extraSetFlags on homelab and desktop-pc
nix eval .#nixosConfigurations.homelab.config.services.tailscale.extraSetFlags --json
nix eval .#nixosConfigurations.desktop-pc.config.services.tailscale.extraSetFlags --json

# 2. Verify tailscaled-set.service script is generated on homelab
nix eval .#nixosConfigurations.homelab.config.systemd.services.tailscaled-set.script --raw

# 3. Verify OpenSSH LAN fallback remains enabled on homelab
nix eval .#nixosConfigurations.homelab.config.services.openssh.enable --json
```

**Expected Outcome**:

- `extraSetFlags` evaluates to `["--ssh"]` on both `homelab` and `desktop-pc`.
- `tailscaled-set.script` outputs `/nix/store/...-tailscale-.../bin/tailscale set '--ssh'`.
- `services.openssh.enable` evaluates to `true`.

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

## 4. Live Host Deployment & End-to-End Verification

### 4.1 Configure Tailscale Admin Console ACLs

In the [Tailscale Admin Console Access Controls](https://login.tailscale.com/admin/acls), ensure the `ssh` section authorizes `laurent` and `root` on `homelab`:

```jsonc
"ssh": [
  {
    "action": "check",
    "src": ["autogroup:member"],
    "dst": ["homelab"],
    "users": ["laurent", "root"]
  }
]
```

### 4.2 Deploy to `homelab`

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

### 4.3 Verify Runtime Service & Connections

1. **Check `tailscaled-set.service` on `homelab`**:

   ```sh
   systemctl status tailscaled-set.service
   ```

2. **Test Tailscale SSH from any tailnet-authenticated device (without requiring local SSH keys)**:

   ```sh
   ssh laurent@100.127.199.88
   # Or using Tailscale CLI / MagicDNS:
   tailscale ssh laurent@homelab
   ```

3. **Confirm LAN OpenSSH fallback remains functional**:

   ```sh
   ssh homelab
   ```
