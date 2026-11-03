# my-nixos-configurations

[![CI](https://github.com/lvaylet/my-nixos-configurations/actions/workflows/ci.yml/badge.svg)](https://github.com/lvaylet/my-nixos-configurations/actions/workflows/ci.yml)

Declarative NixOS multi-host configurations, Home Manager user environments, and portable cross-platform development toolchains.

---

## Managed Hosts Topology

| Host | Architecture | OS / Stack | Role & Key Capabilities | Guide |
| --- | --- | --- | --- | --- |
| **`desktop-pc`** | `x86_64-linux` | NixOS / Home Manager | Primary workstation: Niri Wayland compositor, Noctalia shell, WezTerm, Nvidia GPU, Nord theme | [`modules/hosts/desktop-pc.nix`](modules/hosts/desktop-pc.nix) |
| **`homelab`** | `x86_64-linux` | NixOS (Impermanent `tmpfs`) | Headless server: Caddy reverse proxy, Cloudflare DNS-01, Tailscale SSH, Podman, n8n, Jellyfin, Home Assistant | [Homelab Guide](docs/hosts/homelab.md) |
| **`macbook-air-m4-15`** | `aarch64-darwin` | macOS / `nix-darwin` | Portable workstation: Fish, Neovim/LazyVim, WezTerm, Ghostty, OpenCode, VS Code, Tailscale | [macOS Guide](docs/hosts/macbook.md) |
| **`iso`** | `x86_64-linux` | NixOS Installer | Bootable headless installation image with pre-baked SSH keys for automated `nixos-anywhere` deployment | [`modules/core/iso.nix`](modules/core/iso.nix) |

---

## Architecture: The Dendritic Pattern

This repository is structured around the **[Dendritic Pattern](https://github.com/mightyiam/dendritic)** using **`flake-parts`** and **`import-tree`**:

- **Feature-Centric Design**: Every capability is organized as a cohesive feature in domain directories under `modules/` (`core/`, `desktop/`, `services/`, `hosts/`), colocating NixOS system services and Home Manager user environments side-by-side.
- **Zero-Boilerplate Auto-Discovery**: All non-entrypoint files under `modules/` are discovered automatically via `(inputs.import-tree ./modules)` in `flake.nix`, requiring zero manual entries in centralized import arrays.
- **Declarative Host Composition**: Target machines declare their closure purely by listing hardware specifications and an explicit array of enabled features without inline service definitions.
- **Unified Identity Context**: Shared user identity, credentials, and parameters are defined as top-level options in `modules/core/vars.nix` (`config.flake.vars`) and accessed without parameter plumbing.

```text
modules/
├── core/       # Base foundation, identity vars, builders (mkHost, mkDarwinHost), Neovim, devShell, checks
├── desktop/    # Niri Wayland session, Noctalia shell, WezTerm, Fish shell, fonts, editors, audio, GPU
├── services/   # Networking, OpenSSH, Tailscale, Podman, Caddy, Jellyfin, n8n, OpenCode, Uptime Kuma, WAHA
└── hosts/      # Machine closures (desktop-pc, homelab, iso, macbook-air-m4-15) and hardware specs
```

---

## Quickstart & Environment Setup

This repository supports development, testing, and deployment from any Linux machine, macOS, or Windows (WSL2):

### Option 1: Cross-Platform via Devbox (Recommended for non-NixOS / macOS / WSL)

```sh
# Start development shell with all linters, formatters, and task runners:
devbox shell
```

### Option 2: Native Nix Flakes (`direnv` & `nix develop`)

On managed hosts, `direnv` and developer tools (`just`, `nh`, `alejandra`, `deadnix`, `statix`, `markdownlint-cli2`) are pre-installed:

```sh
# Authorize automatic flake devShell activation:
direnv allow

# Or enter development shell manually:
nix develop
```

---

## Operational Recipes (`justfile`)

All operational workflows are defined in the [`justfile`](justfile) using unified lifecycle verbs across all hosts (`desktop-pc`, `homelab`, `macbook-air-m4-15`). When omitted, target configurations default to the local machine:

| Command | Action | Scope / Target |
| --- | --- | --- |
| `just build [<host>]` | Compile configuration closure without activating | Local or remote host |
| `just test [<host>]` | Compile and activate in live session without saving boot profile | Local or remote host |
| `just switch [<host>]` | Compile, activate live, and commit a new profile generation | Local or remote host |
| `just boot [<host>]` | Build and set profile as the default for the next boot | NixOS host |
| `just check` | Evaluate flake syntax, configurations, and run hermetic sandbox checks | All configurations |
| `just fmt` / `just fix-md` | Format `.nix` files with Alejandra / Auto-fix Markdown files | Repository files |
| `just lint` / `just lint-md` | Run static analysis (`deadnix`, `statix`) / Lint Markdown | Repository files |
| `just clean` / `just clean-all` | Run profile garbage collection | User / System |

### Remote Deployments over SSH

Deploy or test configurations on remote targets (e.g. `homelab`) from any workstation:

**Bash**:

```bash
# Test configuration remotely without saving profile:
just test homelab

# Permanently deploy and switch remote target:
just switch homelab
```

**Fish**:

```fish
# Test configuration remotely without saving profile:
just test homelab

# Permanently deploy and switch remote target:
just switch homelab
```

---

## Homelab Hosted Services Summary

Internal web applications run on `homelab` and are securely exposed over the private Tailscale overlay (`*.homelab.vaylet.fr` pointing to `100.127.199.88`) with automated Let's Encrypt certificates provisioned via Cloudflare DNS-01:

| Service | Subdomain / URL | Local Upstream | Type & Purpose |
| --- | --- | --- | --- |
| **Home Assistant** | `https://ha.homelab.vaylet.fr` | `127.0.0.1:8123` | OCI Container — Home automation platform |
| **n8n** | `https://n8n.homelab.vaylet.fr` | `127.0.0.1:5679` | OCI Containers — Visual workflow automation with isolated Python/JS runners |
| **Uptime Kuma** | `https://uptime.homelab.vaylet.fr` | `127.0.0.1:3002` | Native Service — Monitoring service availability and container metrics |
| **OpenCode** | `https://opencode.homelab.vaylet.fr` | `127.0.0.1:4096` | Native Service — AI coding agent web daemon with declarative skills |
| **Code-Server** | `https://code.homelab.vaylet.fr` | `127.0.0.1:4444` | Native Service — Web-based VS Code IDE with persistent workspaces |
| **WAHA** | `https://waha.homelab.vaylet.fr` | `127.0.0.1:3001` | OCI Container — WhatsApp HTTP API for n8n automations |
| **SGDF Tools API** | `https://sgdf.homelab.vaylet.fr` | `127.0.0.1:8000` | Native Service — SGDF intranet export ingestion & Google Contacts / WhatsApp audits |
| **FileBrowser Quantum** | `https://fb.homelab.vaylet.fr` | `127.0.0.1:8081` | OCI Container — Web-based file manager for `/data` |
| **Portainer CE** | `https://portainer.homelab.vaylet.fr` | `https://127.0.0.1:9443` | OCI Container — Container management Web UI |
| **Jellyfin** | `https://jellyfin.homelab.vaylet.fr` | `127.0.0.1:8096` | Native Service — Media streaming with Intel QuickSync transcoding |
| **qBittorrent** | `https://qbittorrent.homelab.vaylet.fr` | `127.0.0.1:8080` | Native Service — Headless BitTorrent client for `/data/downloads` |

*For complete setup instructions (Cloudflare API tokens, WhatsApp pairing, Home Assistant proxy authorization, and `/data` permissions), see the [Homelab Services Guide](docs/services/homelab-services.md).*

---

## Quality Gates & Verification Workflow

All contributions adhere to the repository quality gates ([`.specify/memory/constitution.md`](.specify/memory/constitution.md)):

1. **Dedicated Branch & PR Isolation**: Direct commits to `main` are prohibited. All work occurs in dedicated branches.
2. **Living Documentation & Dual-Shell Parity**: `README.md` and `docs/` reflect all changes with explicit **Bash** and **Fish** command blocks.
3. **Automated Quality Checks**: Changes must pass formatting (`just fmt`, `just fix-md`), linting (`just lint`, `just lint-md`), and hermetic pre-commit checks (`just check` / `nix flake check`) before deployment.

---

## Documentation Directory

| Guide | Description |
| --- | --- |
| 📖 **[macOS Workstation Guide](docs/hosts/macbook.md)** | Apple M4 initial bootstrap (`/etc/synthetic.conf`, `nix-darwin`), daily ops, and Tailscale access |
| 🖥️ **[Homelab Bootstrap Guide](docs/hosts/homelab.md)** | Headless bare-metal installation (`nixos-anywhere` + custom ISO), tmpfs impermanence, and updates |
| ⚙️ **[Homelab Services Guide](docs/services/homelab-services.md)** | Step-by-step setup recipes for all 12 services, Cloudflare DNS-01, API tokens, and storage permissions |
| ⌨️ **[Shell Aliases & Design Guide](docs/reference/shell-aliases.md)** | Comprehensive cheat sheets for Git, systemctl, journalctl, Fish helpers, and Nord visual theme |

---

## References

- [Explode Root On Every Boot \| Simplest Impermanent NixOS Setup 2026 \| Vimjoyer](https://www.vimjoyer.com/vid89-impermanent)
- [NixOS as a server, part 1: Impermanence](https://guekka.github.io/nixos-server-1/)
- [Quickstart Guide: nixos-anywhere](https://nix-community.github.io/nixos-anywhere/quickstart.html)
- [Disko: Declarative Disk Partitioning for NixOS](https://github.com/nix-community/disko)
- [Preservation: Declarative State Preservation](https://github.com/nix-community/preservation)
- [Dendritic Pattern](https://github.com/mightyiam/dendritic)
