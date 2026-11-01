# Quickstart & Verification Guide: Automated Container Image Updates via Podman

**Feature Branch**: `037-podman-auto-update`
**Date**: 2026-11-01
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

This guide walks through verifying the declarative configuration, systemd timers, container labels, and operational recipes for automated container image updates.

---

## 1. Prerequisites

- Working copy on branch `037-podman-auto-update`.
- Nix with flakes enabled.
- Access to `just` task runner.

---

## 2. Declarative Flake Evaluation Checks

Verify that the systemd timer and container labels evaluate accurately without building the full OS:

### A. Verify Systemd Timer & Service Configuration

**Bash & Fish:**

```shell
nix eval .#nixosConfigurations.homelab.config.systemd.timers.podman-auto-update.timerConfig --json
```

**Expected Output:**

```json
{
  "OnCalendar": "daily",
  "Persistent": true,
  "RandomizedDelaySec": 900
}
```

Check the service definition:

```shell
nix eval .#nixosConfigurations.homelab.config.systemd.services.podman-auto-update.serviceConfig.Type --json
```

**Expected Output:**

```json
"oneshot"
```

### B. Verify Container Labels Across Services

Verify that each container has the `io.containers.autoupdate=registry` label configured:

**Bash & Fish:**

```shell
nix eval --expr '
let
  f = builtins.getFlake (toString ./.);
  containers = f.nixosConfigurations.homelab.config.virtualisation.oci-containers.containers;
in
  builtins.mapAttrs (_: c: c.extraOptions) containers
' --json
```

**Expected Output:**
Every container (`filebrowser`, `homeassistant`, `n8n`, `n8n-runners`, `portainer`, `waha`) contains `"--label=io.containers.autoupdate=registry"` in its `extraOptions` list.

---

## 3. Hermetic Repository Quality Gates

Run formatting, linting, and sandbox check:

**Bash & Fish:**

```shell
just fmt
just lint
just check
```

**Expected Outcome**: All gates pass with exit code 0.

---

## 4. Live Runtime Verification (on `homelab`)

After deployment via `just switch homelab`:

### A. Check Systemd Timer Status

**Bash & Fish:**

```shell
systemctl list-timers podman-auto-update.timer
```

**Expected Output:**
The timer is active (`active (waiting)`), scheduled for the next daily recurrence.

### B. Trigger Manual Update via Justfile

From a workstation targeting `homelab`:

**Bash:**

```bash
just update-containers homelab
```

**Fish:**

```fish
just update-containers homelab
```

Or locally on `homelab`:

**Bash & Fish:**

```shell
sudo podman auto-update
```

**Expected Output:**
Podman contacts the registries for all labeled containers, prints an update report (e.g., container name, image repository, old digest, new digest, and update status `identical` or `updated`), and restarts any service whose image was updated.
