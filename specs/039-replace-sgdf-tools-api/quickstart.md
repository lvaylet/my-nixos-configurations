# Quickstart & Validation Guide: Replace `sgdf-utils` with `sgdf-tools` API on Homelab

**Branch**: `039-replace-sgdf-tools-api` | **Date**: 2026-11-01 | **Spec**: [spec.md](spec.md)

## 1. Pre-Deployment Evaluation & Quality Gates

Run these checks locally from the repository root to verify the configuration before deploying to `homelab`:

**Bash**:

```bash
# 1. Verify formatting and static analysis
just fmt
just lint

# 2. Verify systemd service and Caddy reverse proxy evaluation on homelab
nix eval .#nixosConfigurations.homelab.config.services.sgdf-api.enable
nix eval .#nixosConfigurations.homelab.config.services.sgdf-api.port
nix eval .#nixosConfigurations.homelab.config.systemd.services.sgdf-api.serviceConfig.DynamicUser
nix eval .#nixosConfigurations.homelab.config.services.caddy.virtualHosts.\"sgdf.homelab.vaylet.fr\".extraConfig

# 3. Run full flake check suite
just check
```

**Fish**:

```fish
# 1. Verify formatting and static analysis
just fmt
just lint

# 2. Verify systemd service and Caddy reverse proxy evaluation on homelab
nix eval .#nixosConfigurations.homelab.config.services.sgdf-api.enable
nix eval .#nixosConfigurations.homelab.config.services.sgdf-api.port
nix eval .#nixosConfigurations.homelab.config.systemd.services.sgdf-api.serviceConfig.DynamicUser
nix eval '.#nixosConfigurations.homelab.config.services.caddy.virtualHosts."sgdf.homelab.vaylet.fr".extraConfig'

# 3. Run full flake check suite
just check
```

**Expected Outcomes**:

- `services.sgdf-api.enable` evaluates to `true`.
- `services.sgdf-api.port` evaluates to `8000`.
- `systemd.services.sgdf-api.serviceConfig.DynamicUser` evaluates to `false`.
- `services.caddy.virtualHosts."sgdf.homelab.vaylet.fr".extraConfig` contains `reverse_proxy 127.0.0.1:8000`.
- `just check` exits with code `0`.

## 2. Deployment & Runtime Verification on `homelab`

1. **Test and switch configuration on `homelab`**:

   **Bash / Fish**:

   ```bash
   just test homelab
   just switch homelab
   ```

2. **Clean up legacy `sgdf-utils` persistent state (and any pre-existing incompatible `sgdf.db`)**:

   **Bash**:

   ```bash
   ssh laurent@homelab "sudo rm -rf /persistent/var/lib/sgdf-utils /var/lib/sgdf-utils"
   ```

   **Fish**:

   ```fish
   ssh laurent@homelab "sudo rm -rf /persistent/var/lib/sgdf-utils /var/lib/sgdf-utils"
   ```

3. **Verify `sgdf-api` service health and retrieve `SGDF_AUTH_TOKEN`**:

   **Bash**:

   ```bash
   curl -fsSL https://sgdf.homelab.vaylet.fr/health
   ssh laurent@homelab "sudo cat /var/lib/sgdf-tools/sgdf-tools.env"
   ```

   **Fish**:

   ```fish
   curl -fsSL https://sgdf.homelab.vaylet.fr/health
   ssh laurent@homelab "sudo cat /var/lib/sgdf-tools/sgdf-tools.env"
   ```

**Expected Outcomes**:

- `https://sgdf.homelab.vaylet.fr/health` returns `OK` (`200 OK`).
- `/var/lib/sgdf-tools/sgdf-tools.env` contains `SGDF_AUTH_TOKEN=<64-hex-chars>` with `0600` permissions owned by `sgdf-tools:sgdf-tools`.
- `/var/lib/sgdf-tools/sgdf.db` is created and initialized with the `sgdf-tools` SQLite schema.
