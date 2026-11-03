# Homelab Hosted Services & Configuration Guide

[← Back to README](../../README.md)

The `homelab` server hosts containerized and native services organized under `modules/services/` with coordinated access to shared storage (`/data`) and state preservation under `/persistent`.

---

## Service Catalog

| **Service** | **Type** | **Network / Ports** | **Storage / Data** | **Description** |
| --- | --- | --- | --- | --- |
| **Tailscale** | Native Service | `41641/udp` (WireGuard), `22` (Tailscale SSH on `tailscale0`) | `/var/lib/tailscale` | Private mesh VPN, Tailscale SSH server, and LocalAPI TLS certificate provider for Caddy (`root:root`, `0700` preserved under `/persistent`). |
| **Caddy** | Native Service | `443` (HTTPS) | `/var/lib/caddy` | Central reverse proxy with Cloudflare DNS-01 ACME plugin and Let's Encrypt TLS. |
| **Filebrowser Quantum** | OCI Container | `443` (HTTPS via Caddy) | `/data:/srv`, `/var/lib/filebrowser:/config` | Web-based file manager for browsing, uploading, and organizing files. |
| **Home Assistant** | OCI Container | `443` (HTTPS via Caddy) | `/var/lib/home-assistant:/config` | Home automation platform with local network discovery and Tailscale HTTPS access. |
| **Portainer CE** | OCI Container | `443` (HTTPS via Caddy) | `/var/lib/portainer`, Docker socket | Container management Web UI. |
| **n8n** (+ `n8n-runners`) | OCI Containers | `443` (HTTPS via Caddy) | `/var/lib/n8n` | Workflow automation platform with visual node-based editor, webhook integration, and isolated `n8nio/runners` sidecar for native Python 3 and JavaScript `Code` nodes. |
| **Uptime Kuma** | Native Service | `443` (HTTPS via Caddy) | `/var/lib/uptime-kuma`, Docker socket | Self-hosted monitoring tool for tracking service availability, Portainer/Podman container status, response latency, and TLS certificate expiration with real-time alerts. |
| **OpenCode** | Native Service | `443` (HTTPS via Caddy) | `/var/lib/opencode`, `/home/laurent/workspace`, `/home/laurent/.agents`, `/home/laurent/.local/share/opencode` | AI coding agent built for the terminal with web interface, declarative AI engineering skills (Matt Pocock & Addy Osmani), Node.js/Python tool runners (`npm`, `npx`, `uv`, `uvx`), and headless server daemon running under the primary user account with full access to cloned Git workspaces. |
| **Code-Server** | Native Service | `443` (HTTPS via Caddy) | `/home/laurent`, `/home/laurent/.local/share/code-server`, `/home/laurent/.config/code-server` | Web-based code editor and remote IDE running natively under the primary user account with full access to home workspaces, integrated terminal (`just`, `git`, `nix`), and persistent extensions. |
| **WAHA** | OCI Container | `443` (HTTPS via Caddy) | `/var/lib/waha` | Self-hosted WhatsApp HTTP API and dashboard for automating WhatsApp messaging workflows with n8n. |
| **SGDF Tools API** (`sgdf-tools`) | Native Service | `443` (HTTPS via Caddy) | `/var/lib/sgdf-tools` | Rust/Axum HTTP REST API (`sgdf-api`), CLI (`sgdf`), and SQLite repository (`sgdf.db`) for SGDF intranet export ingestion, legal representative deduplication, Google Contacts export, and WhatsApp differential audits with n8n and WAHA (`sgdf-tools:sgdf-tools`, `0750` preserved under `/persistent`). |
| **Jellyfin** | Native Service | `443` (HTTPS via Caddy), `8096` (TCP) | `/var/lib/jellyfin`, `/var/cache/jellyfin`, `/data/media` | Media streaming server with Intel QuickSync hardware transcoding (`jellyfin:multimedia`, `0750` preserved under `/persistent`). |
| **qBittorrent** | Native Service | `443` (HTTPS via Caddy), `8080` (WebUI) + Torrent ports | `/data/downloads`, `/var/lib/qBittorrent` | Headless BitTorrent client with automated download directories. |

---

## Reverse Proxy & HTTPS Architecture (Caddy & Cloudflare DNS-01)

Internal web applications are securely exposed on dedicated subdomains of `homelab.vaylet.fr` through **Caddy** (`modules/services/caddy.nix`) compiled with the official `caddy-dns/cloudflare` plugin:

| **Service** | **Subdomain / External URL** | **Upstream Target** | **LAN Direct URL** |
| --- | --- | --- | --- |
| **Home Assistant** | `https://ha.homelab.vaylet.fr` | `127.0.0.1:8123` | N/A (loopback bound) |
| **n8n** | `https://n8n.homelab.vaylet.fr` | `127.0.0.1:5679` | N/A (loopback bound) |
| **Uptime Kuma** | `https://uptime.homelab.vaylet.fr` | `127.0.0.1:3002` | N/A (loopback bound) |
| **OpenCode** | `https://opencode.homelab.vaylet.fr` | `127.0.0.1:4096` | N/A (loopback bound) |
| **Code-Server** | `https://code.homelab.vaylet.fr` | `127.0.0.1:4444` | N/A (loopback bound) |
| **WAHA** | `https://waha.homelab.vaylet.fr` | `127.0.0.1:3001` | N/A (loopback bound) |
| **SGDF Tools API** (`sgdf-api`) | `https://sgdf.homelab.vaylet.fr` | `127.0.0.1:8000` | N/A (loopback bound) |
| **FileBrowser Quantum** | `https://fb.homelab.vaylet.fr` | `127.0.0.1:8081` | N/A (loopback bound) |
| **Portainer CE** | `https://portainer.homelab.vaylet.fr` | `https://127.0.0.1:9443` *(TLS bypass)* | N/A (loopback bound) |
| **Jellyfin** | `https://jellyfin.homelab.vaylet.fr` | `127.0.0.1:8096` | `http://homelab:8096` |
| **qBittorrent** | `https://qbittorrent.homelab.vaylet.fr` | `127.0.0.1:8080` | `http://homelab:8080` |

- **Security & Private Tailscale Overlay**: DNS records for `*.homelab.vaylet.fr` point exclusively to the homelab's private Tailscale CGNAT IP (`100.127.199.88`). No ports are opened or forwarded on the home router (WAN). Only devices authenticated to your private Tailscale network can reach these endpoints.
- **Automated Publicly-Trusted Certificates**: Caddy automatically provisions and renews genuine Let's Encrypt certificates using the ACME DNS-01 challenge via Cloudflare, eliminating browser security alerts and mobile app certificate rejections without exposing port 80 to the internet.
- **State & Secret Preservation**: Certificates, runtime state, and the Cloudflare API secret file in `/var/lib/caddy` are preserved under `/persistent/var/lib/caddy` across ephemeral tmpfs reboots.

---

## Step-by-Step Configuration Recipes

### 1. DNS Setup (Cloudflare)

In Cloudflare DNS for `vaylet.fr`, create a single wildcard **A** record:

- **Name**: `*.homelab` (resolves `*.homelab.vaylet.fr`)
- **IPv4 Address**: `100.127.199.88` (homelab's Tailscale IP)
- **Proxy status**: **DNS Only** (grey cloud — mandatory for non-routable Tailscale CGNAT IPs)

### 2. Cloudflare API Token Provisioning

In Cloudflare, generate an API token with `Zone - DNS - Edit` permissions for the `vaylet.fr` zone. On the `homelab` server, provision the token into the persistent Caddy environment file (never committed to git):

**Bash**:

```bash
sudo mkdir -p /persistent/var/lib/caddy
sudo tee /persistent/var/lib/caddy/cloudflare.env << 'EOF'
CLOUDFLARE_API_TOKEN=<your-cloudflare-api-token>
EOF
sudo chown -R caddy:caddy /persistent/var/lib/caddy
sudo chmod 0600 /persistent/var/lib/caddy/cloudflare.env
```

**Fish**:

```fish
sudo mkdir -p /persistent/var/lib/caddy
printf '%s\n' \
  'CLOUDFLARE_API_TOKEN=<your-cloudflare-api-token>' \
  | sudo tee /persistent/var/lib/caddy/cloudflare.env
sudo chown -R caddy:caddy /persistent/var/lib/caddy
sudo chmod 0600 /persistent/var/lib/caddy/cloudflare.env
```

### 3. Home Assistant Reverse Proxy Authorization (UI Configuration)

Modern Home Assistant releases (>= 2026.10) manage reverse proxy trust directly in the Web UI, ignoring legacy `http:` YAML blocks in `configuration.yaml`.

Because direct LAN access to port `8123` is blocked by the host firewall, forward port `8123` over SSH from your workstation to reach the local loopback listener for initial setup:

**Bash**:

```bash
ssh -L 8123:127.0.0.1:8123 laurent@homelab
```

**Fish**:

```fish
ssh -L 8123:127.0.0.1:8123 laurent@homelab
```

- Open `http://127.0.0.1:8123` in your local browser.
- Navigate to **Settings** > **System** > **Network** (**Paramètres** > **Système** > **Réseau**).
- In the **Reverse Proxy** (**Proxy inverse**) section:
  - Check **Use reverse proxy** (**Utiliser un proxy inverse**).
  - Add Caddy's loopback addresses to **Trusted proxies** (**Proxys de confiance**): `127.0.0.1`, `::1`.
- *(Optional)* In **Home Assistant URL**, set the external URL to `https://ha.homelab.vaylet.fr`.
- Click **Save** (**Enregistrer**) and restart Home Assistant (`scr podman-homeassistant` or via UI).
- Remove any deprecated `http:` block from `/persistent/var/lib/home-assistant/configuration.yaml` to avoid deprecation warnings.

### 4. WAHA Credentials & Initial WhatsApp Session Setup

By default, WAHA generates random credentials on each container start if none are provided. To keep the API key and dashboard/Swagger passwords persistent across restarts, provision `/persistent/var/lib/waha/waha.env` on `homelab`:

*(Tip: Generate a secure 256-bit API key using `tr -dc 'a-f0-9' < /dev/urandom | head -c 64; echo`)*

**Bash**:

```bash
sudo mkdir -p /persistent/var/lib/waha
sudo tee /persistent/var/lib/waha/waha.env << 'EOF'
WAHA_API_KEY=<your-waha-api-key>
WAHA_DASHBOARD_USERNAME=admin
WAHA_DASHBOARD_PASSWORD=<your-dashboard-password>
WHATSAPP_SWAGGER_USERNAME=admin
WHATSAPP_SWAGGER_PASSWORD=<your-swagger-password>
EOF
sudo chmod 0600 /persistent/var/lib/waha/waha.env
sudo systemctl restart podman-waha
```

**Fish**:

```fish
sudo mkdir -p /persistent/var/lib/waha
printf '%s\n' \
  'WAHA_API_KEY=<your-waha-api-key>' \
  'WAHA_DASHBOARD_USERNAME=admin' \
  'WAHA_DASHBOARD_PASSWORD=<your-dashboard-password>' \
  'WHATSAPP_SWAGGER_USERNAME=admin' \
  'WHATSAPP_SWAGGER_PASSWORD=<your-swagger-password>' \
  | sudo tee /persistent/var/lib/waha/waha.env
sudo chmod 0600 /persistent/var/lib/waha/waha.env
sudo systemctl restart podman-waha
```

- Open `https://waha.homelab.vaylet.fr/dashboard` in your browser and sign in with `WAHA_DASHBOARD_USERNAME` / `WAHA_DASHBOARD_PASSWORD`.
- Start the `default` WhatsApp session and pair your phone by scanning the QR code from WhatsApp (**Linked devices** > **Link a device**).
- Once paired, session state is persisted in `/persistent/var/lib/waha/sessions` and automatically reconnected on boot via `WHATSAPP_RESTART_ALL_SESSIONS=True`.
- In **n8n** (`https://n8n.homelab.vaylet.fr`), configure your WAHA HTTP requests with header `X-Api-Key: <your-waha-api-key>`.

### 5. Uptime Kuma Initial Setup & Portainer Container Monitoring

- Open `https://uptime.homelab.vaylet.fr` in your browser and create your administrator account on first launch.
- To monitor OCI containers managed by Portainer (`filebrowser`, `homeassistant`, `n8n`, `n8n-runners`, `portainer`, `waha`):
  - Navigate to **Settings** > **Docker Hosts** (**Paramètres** > **Hôtes Docker**) and click **Setup Docker Host**.
  - Set **Connection Type** to **Socket** and **Docker Daemon** to `/var/run/docker.sock` (or `/var/run/podman/podman.sock`), then click **Test** and **Save**.
  - When creating a new monitor, select **Monitor Type**: **Docker Container** and enter the exact container name as shown in Portainer (e.g. `n8n`, `waha`, `homeassistant`, `filebrowser`, `portainer`).

### 6. Tailscale SSH Access Control Policy (Admin Console)

Managed NixOS hosts (`homelab`, `desktop-pc`) enable Tailscale's built-in SSH server on the `tailscale0` interface via `services.tailscale.extraSetFlags = ["--ssh"]`, leaving OpenSSH active on physical LAN interfaces (`192.168.1.180`) as a fallback.

Across ephemeral `tmpfs` reboots, `/var/lib/tailscale` is preserved under `/persistent/var/lib/tailscale`.

In the [Tailscale Admin Console Access Controls](https://login.tailscale.com/admin/acls), define the `ssh` policy stanza to authorize tailnet members to connect as `laurent` and `root`:

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

Once applied, connect without local SSH keys:

**Bash**:

```bash
export TAILSCALE_HOST=100.127.199.88
ssh "laurent@${TAILSCALE_HOST}"
# Or via MagicDNS / Tailscale CLI:
tailscale ssh laurent@homelab
```

**Fish**:

```fish
set -gx TAILSCALE_HOST 100.127.199.88
ssh "laurent@$TAILSCALE_HOST"
# Or via MagicDNS / Tailscale CLI:
tailscale ssh laurent@homelab
```

### 7. OpenCode Initial Setup & Access

- **Terminal Shell**: Connect to `homelab` via SSH (`ssh homelab`) and launch `opencode` to start an interactive agent session styled with the shared Nord theme.
- **Web Interface**: Open `https://opencode.homelab.vaylet.fr` in your browser.
- **Declarative AI Agent Skills**: Pinned as non-flake inputs in `flake.nix` and assembled into a unified 52-skill bundle in `modules/services/opencode.nix`, 27 skills from Matt Pocock and 25 skills from Addy Osmani are linked declaratively into `~/.config/opencode/skills`.
- **Node.js & Python Tool Runners (`npm`, `npx`, `uv`, `uvx`)**: Both `pkgs.nodejs` and `pkgs.uv` are available in system environment and `opencode-web` service `PATH`.
- **User Execution & Workspace Access**: Runs natively under `laurent:users` with direct access to `/home/laurent/workspace/` and user Git configuration.
- **State Preservation**: `/var/lib/opencode`, `/home/laurent/workspace`, `/home/laurent/.agents`, and session history are preserved under `/persistent`.
- **Server Password Retrieval**: On first launch, a secure random password is generated in `/persistent/var/lib/opencode/opencode.env`:

**Bash**:

```bash
ssh laurent@homelab "sudo cat /var/lib/opencode/opencode.env"
```

**Fish**:

```fish
ssh laurent@homelab "sudo cat /var/lib/opencode/opencode.env"
```

Log in using username `opencode` and the retrieved password.

### 8. SGDF Tools API Setup & n8n Integration

- The native `sgdf-api` service runs on `127.0.0.1:8000` under `sgdf-tools:sgdf-tools` and is exposed via Caddy at `https://sgdf.homelab.vaylet.fr` (health check: `https://sgdf.homelab.vaylet.fr/health`).
- The `sgdf-cli` (`sgdf`) binary is pre-installed on `homelab` with `SGDF_API_URL="http://127.0.0.1:8000"`.
- `/var/lib/sgdf-tools` (storing SQLite database `sgdf.db` and Bearer token file `sgdf-tools.env`) is preserved under `/persistent/var/lib/sgdf-tools` (`0750`).
- **Bearer Token Retrieval**:

**Bash**:

```bash
ssh laurent@homelab "sudo cat /var/lib/sgdf-tools/sgdf-tools.env"
```

**Fish**:

```fish
ssh laurent@homelab "sudo cat /var/lib/sgdf-tools/sgdf-tools.env"
```

- **Intranet Import & n8n Calling**: Import an export (`ExportIndividus.xls`) via `sgdf --api-url https://sgdf.homelab.vaylet.fr --token "<SGDF_AUTH_TOKEN>" import ExportIndividus.xls`. In n8n, use Bearer Auth with this token to query endpoints (e.g. `/api/v1/exports/google-contacts`).
- **Upgrading & Redeploying**:

**Bash**:

```bash
# 1. Update flake input lock:
just up sgdf-tools

# 2. Deploy and switch on homelab:
just switch homelab

# 3. Verify health check:
curl https://sgdf.homelab.vaylet.fr/health

# 4. Commit updated lockfile:
git add flake.lock
git commit -m "chore(flake): update sgdf-tools"
```

**Fish**:

```fish
# 1. Update flake input lock:
just up sgdf-tools

# 2. Deploy and switch on homelab:
just switch homelab

# 3. Verify health check:
curl https://sgdf.homelab.vaylet.fr/health

# 4. Commit updated lockfile:
git add flake.lock
git commit -m "chore(flake): update sgdf-tools"
```

### 9. Code-Server Web Code Editor Setup & Access

- **Web Interface**: Open `https://code.homelab.vaylet.fr` in your browser from any device authenticated to your private Tailscale network.
- **Keyless Access**: Tailscale network isolation replaces application passwords (`auth = "none"`).
- **Extension & Visual Parity**: Pre-packages universal extensions (`GitHub Actions`, `Nord` theme, `Markdownlint`, `Nix IDE`, `Alejandra`, `Even Better TOML`).
- **Declarative Settings & Preservation**: `settings.json` is declaratively symlinked to `/nix/store`, while runtime caches and extensions are preserved under `/persistent/home/laurent`.

**Bash**:

```bash
# Test configuration activation safely:
just test homelab

# Deploy and switch on homelab:
just switch homelab
```

**Fish**:

```fish
# Test configuration activation safely:
just test homelab

# Deploy and switch on homelab:
just switch homelab
```

### 10. Automated Container Image Updates (Podman & Systemd Timer)

- **Daily Automated Inspection**: Homelab runs a systemd timer (`systemd.timers.podman-auto-update`) every 24 hours with catch-up persistence.
- **Registry Digest Tracking**: All declarative OCI containers (`portainer`, `homeassistant`, `filebrowser`, `waha`, `n8n`, `n8n-runners`) include `--label=io.containers.autoupdate=registry`.
- **Timer Status & Monitoring**:

**Bash**:

```bash
ssh laurent@homelab "systemctl list-timers podman-auto-update.timer"
ssh laurent@homelab "journalctl -u podman-auto-update -n 50"
```

**Fish**:

```fish
ssh laurent@homelab "systemctl list-timers podman-auto-update.timer"
ssh laurent@homelab "journalctl -u podman-auto-update -n 50"
```

- **On-Demand Manual Update**:

**Bash**:

```bash
# Remotely over SSH:
just update-containers homelab

# Or directly on homelab:
sudo podman auto-update
```

**Fish**:

```fish
# Remotely over SSH:
just update-containers homelab

# Or directly on homelab:
sudo podman auto-update
```

---

## Shared Multimedia Storage (`/data`)

Downloading, file management, and media streaming services collaborate using a coordinated permission model (`modules/services/media.nix`):

- **Group `multimedia` (GID `995`)**: Shared by `qbittorrent` (UID `991`), `filebrowser` (UID `992`), `jellyfin` (including preserved `/var/lib/jellyfin` and `/var/cache/jellyfin`), and the primary user `laurent`.
- **SetGID Bit (`2775`)**: Automatically propagates group ownership to all new files written in `/data/downloads` and `/data/media`.
- **Systemd Tmpfiles (`z` rules)**: Enforces permissions after preservation mounts without race conditions.

---

[← Back to README](../../README.md)
