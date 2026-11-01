# Contract: Homelab Host Composition & Living Documentation (`modules/hosts/homelab.nix` & `README.md`)

**Branch**: `039-replace-sgdf-tools-api` | **Date**: 2026-11-01

## 1. Flake Inputs Contract (`flake.nix`)

- Remove `inputs.sgdf-utils`.
- Add `inputs.sgdf-tools`:

```nix
    # SGDF local scout group management REST API & CLI tools
    sgdf-tools = {
      url = "github:lvaylet/sgdf-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

## 2. Host Composition Contract (`modules/hosts/homelab.nix`)

- In `flake.nixosConfigurations.homelab` `features` list:
  - Replace `services.sgdf-utils` with `services.sgdf-tools` (maintaining alphabetical order among `services.*`).
  - Zero inline service definitions in `modules/hosts/homelab.nix`.

## 3. Living Documentation Contract (`README.md`)

In accordance with Constitution Principle VI:

1. **Hosted Services Table**:
   - Replace the **SGDF Contacts API** (`sgdf-utils`) row with **SGDF Tools API** (`sgdf-tools` / `sgdf-api`), documenting:
     - Type: `Native Service`
     - Network / Ports: `443` (HTTPS via Caddy)
     - Storage / Data: `/var/lib/sgdf-tools`
     - Description: Rust/Axum HTTP REST API (`sgdf-api`), CLI (`sgdf`), and SQLite repository (`sgdf.db`) for SGDF intranet export ingestion, legal representative deduplication, Google Contacts export, and WhatsApp differential audits with n8n and WAHA (`sgdf-tools:sgdf-tools`, `0750` preserved under `/persistent`).
2. **Reverse Proxy Table**:
   - Update row to `| **SGDF Tools API** (`sgdf-api`) |`<https://sgdf.homelab.vaylet.fr`> | `127.0.0.1:8000` | N/A (loopback bound) |`.
3. **Post-Deployment Setup Section (Item 8)**:
   - Update **SGDF Tools API (`sgdf-tools`) Setup & n8n Integration** to document:
     - Native `sgdf-api` systemd service on `127.0.0.1:8000` under `sgdf-tools:sgdf-tools`, exposed via Caddy at `https://sgdf.homelab.vaylet.fr` (health check at `https://sgdf.homelab.vaylet.fr/health`), plus `sgdf` CLI pre-installed on `homelab`.
     - State preservation of `/var/lib/sgdf-tools` (`/var/lib/sgdf-tools/sgdf.db` and `/var/lib/sgdf-tools/sgdf-tools.env`) under `/persistent/var/lib/sgdf-tools` (`0750`).
     - Dual **Bash** and **Fish** commands to retrieve `SGDF_AUTH_TOKEN` from `/var/lib/sgdf-tools/sgdf-tools.env`, import an intranet export with `sgdf`, and optionally remove the obsolete `/persistent/var/lib/sgdf-utils` directory.
     - Calling from n8n using *Bearer Auth* (or `Authorization: Bearer <SGDF_AUTH_TOKEN>`) against `https://sgdf.homelab.vaylet.fr`.
