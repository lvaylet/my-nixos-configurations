# my-nixos-configurations

[![CI](https://github.com/lvaylet/my-nixos-configurations/actions/workflows/ci.yml/badge.svg)](https://github.com/lvaylet/my-nixos-configurations/actions/workflows/ci.yml)

Declarative NixOS multi-host configurations, Home Manager user environments, and portable cross-platform development toolchains.

## Quickstart & Environment Setup

This repository supports development, testing, and deployment from **any Linux machine** (NixOS or non-NixOS) as well as **macOS and Windows (WSL2)** via Devbox.

### Option 1: Cross-Platform via Devbox (Recommended for non-NixOS / macOS / WSL)

If you have [Devbox](https://www.jetify.com/devbox) installed:

```sh
# Start the development shell with all linters, formatters, and task runners:
devbox shell

# Or run tasks directly:
devbox run check
devbox run lint
devbox run fmt
```

### Option 2: Native Nix Flakes (`nix develop`)

On any system with the Nix package manager and Flakes enabled:

```sh
# Enter the nix development shell (automatically sets up pre-commit hooks):
nix develop

# Format and lint:
just fmt
just lint
just check
```

---

## Architecture: The Dendritic Pattern

This repository is structured around the **[Dendritic Pattern](https://github.com/mightyiam/dendritic)** using **`flake-parts`** and **`import-tree`**:

- **Feature-Centric Design**: Every capability is organized as a cohesive feature in domain directories under `modules/` (`core/`, `desktop/`, `services/`, `hosts/`), colocating NixOS system services and Home Manager user environments side-by-side.
- **Zero-Boilerplate Auto-Discovery**: All non-entrypoint files under `modules/` are discovered automatically via `(inputs.import-tree ./modules)` in `flake.nix`, requiring zero manual entries in centralized import arrays.
- **Declarative Host Composition**: Target machines (`modules/hosts/desktop-pc.nix`, `modules/hosts/homelab.nix`, `modules/hosts/iso.nix`) declare their closure purely by listing their hardware specification and an explicit array of enabled features.
- **Unified Identity Context**: Shared user identity, credentials, and parameters are defined as top-level options in `modules/core/vars.nix` (`config.flake.vars`) and accessed without parameter plumbing.

```text
modules/
├── core/                  # Systems, identity options, builder, base system, checks, devShell
├── desktop/               # NNN desktop session, WezTerm, Fish shell, fonts, editors, audio, GPU
├── services/              # Networking, OpenSSH, Tailscale, Podman, Caddy, Jellyfin, n8n, WAHA, etc.
└── hosts/                 # Machine closures (desktop-pc, homelab, iso) and hardware specs
```

---

## Operational Recipes (`justfile`)

All common workflows are defined in the [`justfile`](justfile):

```sh
$ just
Available recipes:
    default                                     # run `just --list`

    [(re)build]
    boot configuration="desktop-pc" target=""   # rebuild and switch after boot (local or remote over SSH)
    build configuration="desktop-pc" target=""  # rebuild system closure (local or remote over SSH)
    build-iso                                   # build custom ISO image with SSH access for remote installations
    deploy-homelab target="homelab"             # deploy configuration update to homelab without repartitioning
    install-homelab target                      # bootstrap and install homelab remotely from scratch using nixos-anywhere
    switch configuration="desktop-pc" target="" # rebuild and switch (local or remote over SSH)
    test configuration="desktop-pc" target=""   # rebuild and activate temporarily (local or remote over SSH)
    test-homelab target="homelab"               # test configuration update on remote homelab without setting boot profile

    [dev-utils]
    fix                                         # fix warnings reported by linters
    fmt                                         # format code recursively
    lint                                        # run linters

    [flake-management]
    check                                       # check whether the flake evaluates and run its tests
    show                                        # show the flake outputs
    up                                          # update all inputs and `flake.lock` file

    [garbage-collection]
    clean keep="1"                              # clean the current user's profiles
    clean-all keep="1"                          # clean all profiles
    collect-garbage                             # delete all unreachable store objects
    delete-old-generations                      # delete all unreachable store objects and old generations of profiles
```

### Remote Deployments over SSH

To deploy to a remote NixOS host from any Linux machine:

```sh
# Temporarily test a configuration on a remote target:
just test configuration="homelab" target="homelab"

# Permanently deploy and switch a remote target:
just switch configuration="homelab" target="homelab"

# Set next boot profile on a remote target:
just boot configuration="homelab" target="homelab"
```

### Initial Provisioning of Homelab (`nixos-anywhere` & Custom ISO)

To perform an automated, headless bootstrap of the impermanent `homelab` server from scratch:

1. **Build the Custom Installer ISO**:
   The custom ISO (`modules/core/iso.nix`) embeds authorized SSH public keys for both `nixos` and `root` users, enabling direct passwordless SSH access:

   ```sh
   just build-iso
   ```

   The bootable ISO image is generated under `result/iso/nixos-*-x86_64-linux.iso`. Flash it to a USB drive (e.g. using `dd`, `rpi-imager`, or Ventoy).

2. **Boot the Target Host**:
   - Insert the USB drive into the homelab hardware (e.g. Beelink S13 mini PC) and boot from it.
   - Note the assigned IPv4 address displayed in the MOTD banner or check it with `ip addr`.

3. **Install Remotely with `nixos-anywhere`**:
   From an authorized workstation, launch the remote deployment:

   ```sh
   export TARGET_IP=<target-ip>

   # Using the dedicated just recipe:
   just install-homelab ${TARGET_IP}

   # Or invoking nixos-anywhere directly:
   nix run github:nix-community/nixos-anywhere -- --flake .#homelab root@${TARGET_IP}
   ```

   `nixos-anywhere` automatically:
   - Partitions and formats the SSD via `disko` (creating the hybrid MBR/ESP layout, swap, and Btrfs subvolumes `/persistent` and `/nix` with ephemeral `tmpfs` root).
   - Mounts the target filesystem hierarchy and sets up preservation links.
   - Installs the complete NixOS system closure with GRUB 2.
   - Reboots into your fresh impermanent system.

4. **Verify and Deploy Subsequent Updates**:
   Once rebooted, connect over SSH as `laurent` or `root`:

   ```sh
   ssh laurent@${TARGET_IP}
   ```

   For routine updates that do not require repartitioning the storage device:

   ```sh
   # Deploy and switch the configuration:
   just deploy-homelab target="${TARGET_IP}"

   # Or test the configuration temporarily without setting a new boot profile:
   just test-homelab target="${TARGET_IP}"
   ```

### Homelab Hosted Services

The `homelab` server hosts containerized and native services organized under `modules/services/` with coordinated access to shared storage (`/data`) and state preservation under `/persistent`:

| **Service** | **Type** | **Network / Ports** | **Storage / Data** | **Description** |
| --- | --- | --- | --- | --- |
| **Caddy** | Native Service | `443` (HTTPS) | `/var/lib/caddy` | Central reverse proxy with Cloudflare DNS-01 ACME plugin and Let's Encrypt TLS. |
| **Filebrowser Quantum** | OCI Container | `443` (HTTPS via Caddy), `8081` (LAN HTTP) | `/data:/srv`, `/var/lib/filebrowser` | Web-based file manager for browsing, uploading, and organizing files. |
| **Home Assistant** | OCI Container | `443` (HTTPS via Caddy), `8123` (LAN HTTP) | `/var/lib/home-assistant:/config` | Home automation platform with local network discovery and Tailscale HTTPS access. |
| **Portainer CE** | OCI Container | `443` (HTTPS via Caddy), `9443` (HTTPS), `8000` (TCP) | `/var/lib/portainer`, Docker socket | Container management Web UI. |
| **n8n** | OCI Container | `443` (HTTPS via Caddy) | `/var/lib/n8n` | Workflow automation platform with visual node-based editor and webhook integration. |
| **WAHA** | OCI Container | `443` (HTTPS via Caddy) | `/var/lib/waha` | Self-hosted WhatsApp HTTP API and dashboard for automating WhatsApp messaging workflows with n8n. |
| **Jellyfin** | Native Service | `443` (HTTPS via Caddy), `8096` (TCP) | `/var/lib/jellyfin`, `/data/media` | Media streaming server with Intel QuickSync hardware transcoding. |
| **qBittorrent** | Native Service | `443` (HTTPS via Caddy), `8080` (WebUI) + Torrent ports | `/data/downloads`, `/var/lib/qBittorrent` | Headless BitTorrent client with automated download directories. |

#### Reverse Proxy & Secure HTTPS Access (Caddy & Cloudflare DNS-01)

Internal web applications are securely exposed on dedicated subdomains of `homelab.vaylet.fr` through **Caddy** (`modules/services/caddy.nix`) compiled with the official `caddy-dns/cloudflare` plugin:

| **Service** | **Subdomain / External URL** | **Upstream Target** | **LAN Direct URL** |
| --- | --- | --- | --- |
| **Home Assistant** | `https://ha.homelab.vaylet.fr` | `127.0.0.1:8123` | `http://homelab:8123` |
| **n8n** | `https://n8n.homelab.vaylet.fr` | `127.0.0.1:5679` | N/A (loopback bound) |
| **WAHA** | `https://waha.homelab.vaylet.fr` | `127.0.0.1:3001` | N/A (loopback bound) |
| **FileBrowser Quantum** | `https://fb.homelab.vaylet.fr` | `127.0.0.1:8081` | `http://homelab:8081` |
| **Portainer CE** | `https://portainer.homelab.vaylet.fr` | `https://127.0.0.1:9443` *(TLS bypass)* | `https://homelab:9443` |
| **Jellyfin** | `https://jellyfin.homelab.vaylet.fr` | `127.0.0.1:8096` | `http://homelab:8096` |
| **qBittorrent** | `https://qbittorrent.homelab.vaylet.fr` | `127.0.0.1:8080` | `http://homelab:8080` |

- **Security & Private Tailscale Overlay**: DNS records for `*.homelab.vaylet.fr` point exclusively to the homelab's private Tailscale CGNAT IP (`100.127.199.88`). No ports are opened or forwarded on the home router (WAN). Only devices authenticated to your private Tailscale network can reach these endpoints.
- **Automated Publicly-Trusted Certificates**: Caddy automatically provisions and renews genuine Let's Encrypt certificates using the ACME DNS-01 challenge via Cloudflare, eliminating browser security alerts and mobile app certificate rejections without exposing port 80 to the internet.
- **State & Secret Preservation**: Certificates, runtime state, and the Cloudflare API secret file in `/var/lib/caddy` are preserved under `/persistent/var/lib/caddy` across ephemeral tmpfs reboots.

##### Configuration Instructions

1. **DNS Setup (Cloudflare)**:
   - In Cloudflare DNS for `vaylet.fr`, create a single wildcard **A** record:
     - **Name**: `*.homelab` (resolves `*.homelab.vaylet.fr`)
     - **IPv4 Address**: `100.127.199.88` (homelab's Tailscale IP)
     - **Proxy status**: **DNS Only** (grey cloud — mandatory for non-routable Tailscale CGNAT IPs)

2. **Cloudflare API Token Provisioning**:
   - In Cloudflare, generate an API token with `Zone - DNS - Edit` permissions for the `vaylet.fr` zone.
   - On the `homelab` server, provision the token into the persistent Caddy environment file (never committed to git):

   ```sh
   sudo mkdir -p /persistent/var/lib/caddy
   sudo tee /persistent/var/lib/caddy/cloudflare.env << 'EOF'
   CLOUDFLARE_API_TOKEN=<your-cloudflare-api-token>
   EOF
   sudo chown -R caddy:caddy /persistent/var/lib/caddy
   sudo chmod 0600 /persistent/var/lib/caddy/cloudflare.env
   ```

3. **Home Assistant Reverse Proxy Authorization (UI Configuration)**:
   - Modern Home Assistant releases (>= 2026.10) manage reverse proxy trust directly in the Web UI, ignoring legacy `http:` YAML blocks in `configuration.yaml`.
   - Access Home Assistant initially from the local LAN at `http://homelab:8123` (or `http://192.168.1.181:8123`).
   - Navigate to **Settings** > **System** > **Network** (**Paramètres** > **Système** > **Réseau**).
   - In the **Reverse Proxy** (**Proxy inverse**) section:
     - Check **Use reverse proxy** (**Utiliser un proxy inverse**).
     - Add Caddy's loopback addresses to **Trusted proxies** (**Proxys de confiance**):
       - `127.0.0.1`
       - `::1`
   - *(Optional)* In **Home Assistant URL**, set the external URL to `https://ha.homelab.vaylet.fr`.
   - Click **Save** (**Enregistrer**) and restart Home Assistant (`scr podman-homeassistant` or via UI).
   - Remove any deprecated `http:` block from `/persistent/var/lib/home-assistant/configuration.yaml` to avoid deprecation warnings.

4. **WAHA Credentials & Initial WhatsApp Session Setup**:
   - By default, WAHA generates random credentials on each container start if none are provided. To keep the API key and dashboard/Swagger passwords persistent across restarts (without committing secrets to Git), provision `/persistent/var/lib/waha/waha.env` on the `homelab` server:
   - *(Tip)* Generate a secure 256-bit (64-character hex) API key without external dependencies using `/dev/urandom`:

   ```sh
   tr -dc 'a-f0-9' < /dev/urandom | head -c 64; echo
   ```

   ```sh
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

   - Open `https://waha.homelab.vaylet.fr/dashboard` in your browser and sign in with `WAHA_DASHBOARD_USERNAME` / `WAHA_DASHBOARD_PASSWORD`.
   - Start the `default` WhatsApp session and pair your phone by scanning the QR code (or entering a phone pairing code) from the WhatsApp mobile app (**Linked devices** > **Link a device**).
   - Once paired, the session state is persisted in `/var/lib/waha/sessions` (`/persistent/var/lib/waha/sessions`) and automatically reconnected on boot via `WHATSAPP_RESTART_ALL_SESSIONS=True`.
   - In **n8n** (`https://n8n.homelab.vaylet.fr`), configure your WAHA HTTP requests or community node to use `http://127.0.0.1:3001` (or `https://waha.homelab.vaylet.fr`) with header `X-Api-Key: <your-waha-api-key>`.

5. **Deploy & Activate**:

   ```sh
   just switch configuration="homelab" target="homelab"
   ```

#### Shared Multimedia Storage (`/data`)

Downloading, file management, and media streaming services collaborate using a coordinated permission model (`modules/services/media.nix`):

- **Group `multimedia` (GID `995`)**: Shared by `qbittorrent` (UID `991`), `filebrowser` (UID `992`), `jellyfin`, and the primary user `laurent`.
- **SetGID Bit (`2775`)**: Automatically propagates group ownership to all new files written in `/data/downloads` and `/data/media`.
- **Systemd Tmpfiles (`z` rules)**: Enforces permissions after preservation mounts without race conditions.

### Local / Non-NixOS Building

On a non-NixOS Linux workstation, build a target system closure without requiring root privileges:

```sh
just build configuration="homelab"
```

---

## Flake Outputs

```sh
$ just show
git+file:///home/laurent/workspace/github.com/lvaylet/my-nixos-configurations
├───checks
│   ├───aarch64-darwin
│   ├───aarch64-linux
│   ├───x86_64-darwin
│   └───x86_64-linux
│       └───pre-commit-check: derivation 'pre-commit-run'
├───devShells
│   ├───aarch64-darwin
│   ├───aarch64-linux
│   ├───x86_64-darwin
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
├───formatter
│   ├───aarch64-darwin
│   ├───aarch64-linux
│   ├───x86_64-darwin
│   └───x86_64-linux: package 'pre-commit-run'
└───nixosConfigurations
    ├───desktop-pc: NixOS configuration
    ├───homelab: NixOS configuration
    └───iso: NixOS configuration
```

## Continuous Integration

Continuous integration runs on GitHub Actions using a two-stage gated pipeline ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)):

1. **Stage 1 (Quality Gate & Security)**: Runs `nix flake check` to hermetically validate code formatting (`alejandra`), static analysis (`statix`, `deadnix`), flake syntax (`flake-checker`), and secret scanning filters (`trufflehog`, `ripsecrets`, `detect-private-keys`).
2. **Stage 2 (Matrix System Builds)**: Concurrently evaluates and builds top-level derivations for all target configurations (`desktop-pc`, `homelab`, `iso`).
3. **Build Acceleration**: Leverages [Magic Nix Cache](https://github.com/DeterminateSystems/magic-nix-cache-action) and the Determinate Nix Installer for tokenless, zero-configuration GitHub Actions store caching.

---

## Shell Aliases (Systemd & Logs)

A set of system-wide aliases and native autocompletions (`modules/core/base.nix`) is pre-configured across all hosts using the Fish shell to streamline service control and troubleshooting:

### Service Management (`systemctl`)

| Alias | Command | Purpose / Example |
| --- | --- | --- |
| `sc` | `systemctl` | Base systemctl command (e.g. `sc list-units`) |
| `scs` / `sc-status` | `systemctl status` | Check service status (e.g. `scs jellyfin`) |
| `scr` / `sc-restart` | `systemctl restart` | Restart a service (e.g. `scr podman-homeassistant`) |
| `scl` / `sc-reload` | `systemctl reload` | Reload configuration without restart (e.g. `scl nginx`) |
| `sc-start` | `systemctl start` | Start a stopped service (e.g. `sc-start qbittorrent`) |
| `sc-stop` | `systemctl stop` | Stop a running service (e.g. `sc-stop podman-filebrowser`) |
| `sc-failed` | `systemctl --failed` | List all currently failed systemd units |

### Log Inspection (`journalctl`)

| Alias | Command | Purpose / Example |
| --- | --- | --- |
| `jc` | `journalctl` | Open systemd journal viewer |
| `logs` / `jcu` | `journalctl -u` | View logs for a specific unit (e.g. `logs jellyfin` or `jcu podman-portainer`) |
| `logsf` / `jcuf` | `journalctl -f -u` | Follow logs in real time for a unit (e.g. `logsf jellyfin`) |
| `jcf` | `journalctl -f` | Follow all system logs in real time |
| `jcb` | `journalctl -b` | View logs from the current boot only |
| `jce` | `journalctl -e` | Open journal and jump directly to the end |

### Git Aliases (Oh-My-Zsh Style)

Common Oh-My-Zsh style Git shortcuts with native Fish autocompletion for branches, files, and options:

| Alias | Command | Purpose / Action |
| --- | --- | --- |
| `g` | `git` | Base git command |
| `gst` | `git status` | Show working tree status |
| `ga` / `gaa` | `git add` / `git add --all` | Stage changes (file autocompletion enabled) |
| `gco` / `gcb` | `git checkout` / `git checkout -b` | Checkout branch/commit (branch autocompletion enabled) |
| `gsw` / `gswc` | `git switch` / `git switch -c` | Switch branch (branch autocompletion enabled) |
| `gc` / `gcm` | `git commit -v` / `git commit -m` | Create commit |
| `gca` / `gcam` | `git commit -v -a` / `git commit -a -m` | Stage all and commit |
| `gc!` / `gca!` | `git commit -v --amend` / `... -a --amend` | Amend commit |
| `gd` / `gds` | `git diff` / `git diff --staged` | Show changes |
| `gl` / `gp` / `gpf` | `git pull` / `git push` / `git push --force-with-lease` | Sync with remote repository |
| `gb` / `gba` / `gbd` | `git branch` / `-a` / `-d` | List or delete branches |
| `glo` / `glg` / `glp` | `git log --oneline` / `--stat` / `--patch` | View commit logs |
| `grb` / `grbi` | `git rebase` / `git rebase -i` | Rebase operations |
| `gm` / `gmc` / `gma` | `git merge` / `--continue` / `--abort` | Merge operations |
| `gsta` / `gstp` / `gsts` | `git stash apply` / `pop` / `show -p` | Stash management |
| `grh` / `grhh` | `git reset` / `git reset --hard` | Reset working tree |

---

## Useful Nix Commands

| Command | Purpose |
| --- | --- |
| `nix fmt .` | format all Nix code with Alejandra |
| `nix develop` | activate developer shell with pre-commit hooks and linters |
| `nix flake check` | check whether flake evaluates and all checks pass |
| `nix flake show` | show outputs provided by the flake |
| `nix flake update` | update all pinned inputs in `flake.lock` |
| `nixos-rebuild switch --flake .#<host> --target-host <host> --use-remote-sudo` | manual remote switch command |

---

## References

- [Explode Root On Every Boot | Simplest Impermanent NixOS Setup 2026 | Vimjoyer](https://www.vimjoyer.com/vid89-impermanent)
- [NixOS as a server, part 1: Impermanence](https://guekka.github.io/nixos-server-1/)
- [Quickstart Guide: nixos-anywhere](https://nix-community.github.io/nixos-anywhere/quickstart.html)
- [NixOS Homelab avec Impermanence Automatisée | Gemini](https://gemini.google.com/share/076bac87f8e1)
- [Disko: Declarative Disk Partitioning for NixOS](https://github.com/nix-community/disko)
- [Preservation: Declarative State Preservation](https://github.com/nix-community/preservation)
- [Dendritic Pattern](https://github.com/mightyiam/dendritic)
