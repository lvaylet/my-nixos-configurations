# Quickstart & Verification Guide: OpenCode v2 on Homelab

**Feature Branch**: `022-add-opencode-homelab` | **Date**: 2026-10-25

This guide provides step-by-step procedures to validate the OpenCode v2 integration on `homelab` and its mutualized configuration across machines.

---

## Prerequisites

1. Active repository clone on dedicated branch `022-add-opencode-homelab`.
2. Flake inputs resolved and locked (`nix flake check` / `just check` passing).
3. Access to `homelab` host via SSH or local console.

---

## 1. Code Quality & Flake Evaluation Verification

Before deploying to hardware, verify that all Nix expressions format cleanly, pass static analysis, and evaluate without errors.

### Bash

```bash
# 1. Format all code
just fmt

# 2. Run static analysis & linting
just lint

# 3. Verify flake evaluation for all target configurations
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath
nix eval .#darwinConfigurations.macbook-air-m4-15.config.system.build.toplevel.drvPath

# 4. Run isolated hermetic sandbox checks
just check
```

### Fish

```fish
# 1. Format all code
just fmt

# 2. Run static analysis & linting
just lint

# 3. Verify flake evaluation for all target configurations
nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath
nix eval .#darwinConfigurations.macbook-air-m4-15.config.system.build.toplevel.drvPath

# 4. Run isolated hermetic sandbox checks
just check
```

**Expected Outcome**: All formatting, linting, evaluation, and sandbox checks complete with exit code 0.

---

## 2. Interactive CLI Shell Verification on `homelab`

Verify that OpenCode v2 is available directly in the shell on `homelab` with the shared Nord theme applied.

### Steps

1. Log into `homelab` via SSH:

   ```bash
   ssh laurent@homelab
   ```

2. Verify the binary version:

   ```bash
   opencode --version
   ```

   *Expected Outcome*: Prints OpenCode version 2.x (e.g., `2.1.4`).
3. Launch an interactive session:

   ```bash
   opencode
   ```

   *Expected Outcome*: OpenCode TUI launches immediately (under 2 seconds, satisfying `SC-001`), styled with the Nord color palette.

---

## 3. Web Service & Daemon Verification on `homelab`

Verify that the systemd background daemon is active and listening on the designated loopback port.

### Bash

```bash
# Check service status
ssh laurent@homelab "sudo systemctl status opencode-web.service"

# Verify loopback listener on port 4096
ssh laurent@homelab "sudo ss -tulpn | grep 4096"
```

### Fish

```fish
# Check service status
ssh laurent@homelab "sudo systemctl status opencode-web.service"

# Verify loopback listener on port 4096
ssh laurent@homelab "sudo ss -tulpn | grep 4096"
```

**Expected Outcome**: Service is `active (running)` and listening exclusively on `127.0.0.1:4096`.

---

## 4. HTTPS Remote Access & TLS Verification

Verify that the Caddy reverse proxy terminates TLS and routes traffic to the OpenCode web service.

### Bash

```bash
# Verify HTTP to HTTPS automatic redirection
curl -I "http://opencode.homelab.vaylet.fr"

# Test HTTPS endpoint
curl -I "https://opencode.homelab.vaylet.fr"
```

### Fish

```fish
# Verify HTTP to HTTPS automatic redirection
curl -I "http://opencode.homelab.vaylet.fr"

# Test HTTPS endpoint
curl -I "https://opencode.homelab.vaylet.fr"
```

**Expected Outcome**:

- Plaintext HTTP responds with `HTTP/1.1 308 Permanent Redirect` to `https://opencode.homelab.vaylet.fr`.
- HTTPS responds with a valid TLS certificate and `HTTP/2 200` (or `401 Unauthorized` before login).
- Web browser loads the UI in under 3 seconds (`SC-002`).

---

## 5. Persistence & Reboot Resilience Verification

Verify that OpenCode data and credentials survive system reboots on `homelab`'s ephemeral `tmpfs` root.

### Bash

```bash
# 1. Verify existence of persisted directory and credentials
ssh laurent@homelab "ls -ld /persistent/var/lib/opencode"

# 2. Trigger host reboot
ssh laurent@homelab "sudo reboot"

# 3. Wait for host to come back online (under 30s) and check service availability
ssh laurent@homelab "sudo systemctl is-active opencode-web.service"
```

### Fish

```fish
# 1. Verify existence of persisted directory and credentials
ssh laurent@homelab "ls -ld /persistent/var/lib/opencode"

# 2. Trigger host reboot
ssh laurent@homelab "sudo reboot"

# 3. Wait for host to come back online (under 30s) and check service availability
ssh laurent@homelab "sudo systemctl is-active opencode-web.service"
```

**Expected Outcome**:

- `/persistent/var/lib/opencode` exists and is mounted at `/var/lib/opencode`.
- `opencode-web.service` is active within 30 seconds of system boot (`SC-004`).
- Session history and configuration remain intact.
