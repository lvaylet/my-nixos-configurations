# Phase 0 Research: Replace `sgdf-utils` with `sgdf-tools` API on Homelab

**Branch**: `039-replace-sgdf-tools-api` | **Date**: 2026-11-01 | **Spec**: [spec.md](spec.md)

## 1. Upstream `sgdf-tools` Flake & NixOS Module Architecture

- **Decision**: Import `inputs.sgdf-tools.nixosModules.default` in `modules/services/sgdf-tools.nix` and configure `services.sgdf-api`, while also installing `inputs.sgdf-tools.packages.${pkgs.stdenv.hostPlatform.system}.sgdf-cli` in `environment.systemPackages`.
- **Rationale**:
  - Inspection of `https://github.com/lvaylet/sgdf-tools/blob/main/flake.nix` confirms `sgdf-tools` exports:
    1. `packages.<system>.default` (full Cargo workspace binaries), `packages.<system>.sgdf-api`, and `packages.<system>.sgdf-cli` (providing `sgdf` and `sgdf-cli` binaries).
    2. `nixosModules.default`, which defines `options.services.sgdf-api` (`enable`, `package`, `port`, `host`, `dataDir`, `environmentFile`) and configures `systemd.services.sgdf-api` with `SGDF_PORT`, `SGDF_HOST`, and `SGDF_DATABASE_URL=sqlite://${cfg.dataDir}/sgdf.db?mode=rwc`.
  - Following `nixpkgs` via `inputs.nixpkgs.follows = "nixpkgs"` in `flake.nix` satisfies Constitution Principle I and avoids duplicate nixpkgs instances in `flake.lock`.
- **Alternatives Considered**:
  - *Writing a custom systemd unit from scratch without importing `inputs.sgdf-tools.nixosModules.default`*: Rejected because reusing the upstream NixOS module ensures automatic alignment with upstream environment variables (`SGDF_DATABASE_URL`, `SGDF_PORT`, `SGDF_HOST`) while allowing clean overrides on `systemd.services.sgdf-api`.

## 2. Loopback Port Allocation & Reverse Proxy Continuity

- **Decision**: Configure `services.sgdf-api` with `host = "127.0.0.1"` and `port = 8000`, proxy `sgdf.${vars.homelabDomain}` (`https://sgdf.homelab.vaylet.fr`) to `127.0.0.1:8000` in Caddy, and set `environment.variables.SGDF_API_URL = "http://127.0.0.1:8000"` on `homelab`.
- **Rationale**:
  - Upstream `services.sgdf-api.port` defaults to `3000`, which is already reserved in `modules/services/adguardhome.nix`.
  - Port `8000` on `127.0.0.1` was previously allocated to `sgdf-utils` and is completely free once `sgdf-utils` is removed, avoiding all other `homelab` ports (`3000` adguardhome, `3001` waha, `3002` uptime-kuma, `4096` opencode, `4444` code-server, `5679` n8n, `8080` qbittorrent, `8081` filebrowser, `8096` jellyfin, `8123` home-assistant, `9443` portainer).
  - Keeping `127.0.0.1:8000` preserves the exact upstream target in Caddy (`reverse_proxy 127.0.0.1:8000`) and setting `SGDF_API_URL = "http://127.0.0.1:8000"` allows local `sgdf` CLI invocations on `homelab` to target the local API port automatically without extra flags.
- **Alternatives Considered**:
  - *Using default port `3000`*: Rejected to preserve the repository-wide port non-collision invariant with `modules/services/adguardhome.nix`.

## 3. Impermanence (`preservation`) & `DynamicUser` Override

- **Decision**: Override `systemd.services.sgdf-api.serviceConfig.DynamicUser = lib.mkForce false`, create a static system user and group `sgdf-tools:sgdf-tools`, order `systemd.services.sgdf-api.after = ["local-fs.target"]`, and register `/var/lib/sgdf-tools` (`user = "sgdf-tools"`, `group = "sgdf-tools"`, `mode = "0750"`) in `preservation.preserveAt."/persistent".directories`.
- **Rationale**:
  - Upstream `sgdf-tools` sets `DynamicUser = true` and `StateDirectory = "sgdf-tools"`. On `homelab`'s ephemeral `tmpfs` root filesystem managed by `nix-community/preservation`, `/var/lib/sgdf-tools` is a bind mount from `/persistent/var/lib/sgdf-tools`. Systemd's `DynamicUser = true` attempts to convert `/var/lib/sgdf-tools` into a symlink pointing to `/var/lib/private/sgdf-tools`, which fails when the path is a mount point.
  - Using a static `sgdf-tools:sgdf-tools` user/group with `DynamicUser = lib.mkForce false` is the proven pattern established in `modules/services/sgdf-utils.nix` and `modules/services/uptime-kuma.nix`.
- **Alternatives Considered**:
  - *Preserving `/var/lib/private/sgdf-tools` with `DynamicUser = true`*: Rejected because dynamic UID/GID allocation across reboots causes ownership mismatches on `/persistent` bind mounts (`specs/031-fix-preservation-permissions`).

## 4. First-Boot `SGDF_AUTH_TOKEN` Bootstrapping & Fresh SQLite Database

- **Decision**: Configure `systemd.services.sgdf-api.serviceConfig.EnvironmentFile = "-/var/lib/sgdf-tools/sgdf-tools.env"` and use `preStart` to generate `SGDF_AUTH_TOKEN=<64-hex-chars>` (`0600`) when `/var/lib/sgdf-tools/sgdf-tools.env` is absent or empty. Do not migrate legacy `sgdf-utils` database files; start with a clean `/var/lib/sgdf-tools/sgdf.db`.
- **Rationale**:
  - `sgdf-api` uses Bearer token authentication configured via the `SGDF_AUTH_TOKEN` environment variable (replacing the `SGDF_API_KEY` / `X-API-Key` mechanism of `sgdf-utils`).
  - Prefixing `EnvironmentFile` with `-` allows systemd to run `ExecStartPre` (`preStart`) on first boot before the file exists, and then load the newly generated `SGDF_AUTH_TOKEN` when starting `ExecStart` (`sgdf-api`).
  - Per user clarification, the SQLite database schema in `sgdf-tools` (`sgdf.db`) is completely different from `sgdf-utils` (`sgdf.sqlite3`), so any legacy database is discarded and `sgdf-api` runs its embedded SQLx migrations automatically on a fresh `sgdf.db` at startup.
- **Alternatives Considered**:
  - *Passing `services.sgdf-api.environmentFile = "/var/lib/sgdf-tools/sgdf-tools.env"` directly*: Upstream's module sets `EnvironmentFile = cfg.environmentFile` without a leading `-`, which causes systemd to abort with `ENOENT` on first boot before `preStart` can create the file. Setting `EnvironmentFile = "-/var/lib/sgdf-tools/sgdf-tools.env"` in `systemd.services.sgdf-api.serviceConfig` solves this cleanly.
