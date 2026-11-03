# Documentation Data Model & Taxonomy: Reorganize README

**Feature Branch**: `040-reorganize-readme`

**Created**: 2026-11-03

**Spec**: [`specs/040-reorganize-readme/spec.md`](./spec.md)

---

## 1. Documentation Information Architecture

```text
my-nixos-configurations/
├── README.md                          # Primary landing hub (< 200 lines)
└── docs/
    ├── hosts/
    │   ├── macbook.md                 # macOS workstation provisioning & operations
    │   └── homelab.md                 # Homelab headless bootstrap (ISO + nixos-anywhere)
    ├── services/
    │   └── homelab-services.md        # Comprehensive service recipes (tokens, proxy, config)
    └── reference/
        └── shell-aliases.md           # Exhaustive alias tables & design system specs
```

---

## 2. Document Entities & Content Attributes

### Entity: `LandingHub` (`README.md`)

- **Role**: Root entry point and orientation hub for newcomers and daily operators.
- **Constraints**:
  - Maximum line count: `< 200 lines`.
  - Must include:
    - Title, badges, repository overview.
    - Host Topology Matrix (`desktop-pc`, `homelab`, `macbook-air-m4-15`, `iso`).
    - Quickstart with Devbox and native Nix Flakes (`direnv allow` / `nix develop`).
    - Architecture summary (Dendritic Pattern).
    - Common `just` commands table (lifecycle, linting, deployment).
    - Hosted Services summary table with URLs and ports.
    - Quality Gates & CI summary.
    - Index of detailed documentation links (`docs/`).
    - References.
- **Invariants**:
  - No deep multi-step installation manuals (redirected to `docs/hosts/`).
  - No secrets snippets or token generation commands (redirected to `docs/services/`).
  - No 100+ line alias tables (redirected to `docs/reference/`).

---

### Entity: `HostRunbook` (`docs/hosts/*.md`)

- **Role**: Complete operational and provisioning manuals for specific machine architectures.
- **Instances**:
  1. `docs/hosts/macbook.md`:
     - Target: `macbook-air-m4-15` (`aarch64-darwin`).
     - Sections:
       - Host overview & shared capabilities with `desktop-pc`.
       - Initial Provisioning (Xcode CLI tools, Determinate Nix Installer, `/etc/synthetic.conf` setup with `apfs.util`, initial `nix-darwin` switch).
       - Routine Maintenance & Daily Operations (`just build`, `just test`, `just switch`, rollback).
       - Client Access to Homelab Services (Tailscale SSH, LAN shortcut, web apps).
  2. `docs/hosts/homelab.md`:
     - Target: `homelab` (`x86_64-linux`).
     - Sections:
       - Host overview & headless impermanent architecture (`tmpfs` root, Btrfs subvolumes, `/persistent`).
       - Initial Headless Bootstrap (`just build-iso`, target boot, `nixos-anywhere` remote deployment).
       - Routine Maintenance & System Switches (local on host or remote over SSH).
- **Invariants**:
  - Contains explicit **Bash** and **Fish** code blocks for all commands with shell-specific syntax.
  - Links back to `../../README.md`.

---

### Entity: `ServiceRunbook` (`docs/services/homelab-services.md`)

- **Role**: Exhaustive first-time setup recipes, authentication bootstrapping, and configuration procedures for hosted applications on `homelab`.
- **Target Audience**: Homelab administrators and automation developers.
- **Sections**:
  1. Overview & Reverse Proxy Architecture (Caddy with Cloudflare DNS-01 ACME).
  2. Subdomains & Upstream Target Map.
  3. Step-by-Step Configuration Recipes:
     - Recipe 1: DNS Wildcard Setup (Cloudflare).
     - Recipe 2: Cloudflare API Token Provisioning (`cloudflare.env` - Bash & Fish).
     - Recipe 3: Home Assistant Reverse Proxy Authorization in Web UI.
     - Recipe 4: WAHA Credentials & WhatsApp QR Pairing (`waha.env` - Bash & Fish).
     - Recipe 5: Uptime Kuma Setup & Portainer Container Monitoring.
     - Recipe 6: Tailscale SSH Access Control Policy (JSON ACL).
     - Recipe 7: OpenCode Setup, Skills Bundle, and Password Retrieval (Bash & Fish).
     - Recipe 8: SGDF Tools API Setup, Token Retrieval, and n8n Integration (Bash & Fish).
     - Recipe 9: Code-Server Web Editor Setup & Access (Bash & Fish).
     - Recipe 10: Automated Container Image Updates (Podman Timer & `just update-containers`).
  4. Shared Multimedia Storage (`/data`) permissions, `multimedia` GID `995`, and SetGID bit.
- **Invariants**:
  - Zero plaintext secrets committed; all secrets use runtime generation commands.
  - Every command with syntax variations includes both Bash and Fish variants.
  - Links back to `../../README.md`.

---

### Entity: `ReferenceGuide` (`docs/reference/shell-aliases.md`)

- **Role**: Comprehensive reference for shell shortcuts, developer tooling, and visual design standards across the environment.
- **Sections**:
  1. Shell Architecture Overview (Fish primary login shell, Bash root/scripts duality).
  2. Service Management (`systemctl`) shortcuts table.
  3. Log Inspection (`journalctl`) shortcuts table.
  4. Git Aliases (Oh-My-Zsh style, 25 shortcuts table).
  5. Desktop Interactive Fish Extensions (`eza`, `bat`, `yazi`, `btop`, `ncdu`).
  6. Unified Nord Visual Theme (palette values `#2E3440`–`#B48EAD` and app mapping).
  7. Dynamic Noctalia Wallpapers (directory, automation, keybindings).
  8. Code Typography: FiraCode Nerd Font (ligatures, fallback, editor & terminal configurations).
  9. Harmonized VS Code & Code Server Configuration (`modules/core/vscode.nix`).
  10. Shared Modal Editor: Neovim & LazyVim (`modules/core/neovim.nix`).
- **Invariants**:
  - Tables format cleanly with aligned pipes and Markdownlint compliance.
  - Links back to `../../README.md`.

---

## 3. Cross-Document Navigation Matrix

| Source File | Destination File | Anchor / Link Label | Purpose |
| --- | --- | --- | --- |
| `README.md` | `docs/hosts/macbook.md` | `[macOS Workstation Guide](docs/hosts/macbook.md)` | Deep provisioning for MacBook Air |
| `README.md` | `docs/hosts/homelab.md` | `[Homelab Bootstrap Guide](docs/hosts/homelab.md)` | Headless installation with `nixos-anywhere` |
| `README.md` | `docs/services/homelab-services.md` | `[Homelab Services Guide](docs/services/homelab-services.md)` | Service setup recipes & token provisioning |
| `README.md` | `docs/reference/shell-aliases.md` | `[Shell Aliases & Design Guide](docs/reference/shell-aliases.md)` | Complete alias cheat sheets & theme specs |
| `docs/hosts/macbook.md` | `README.md` | `[← Back to README](../../README.md)` | Breadcrumb navigation back to root |
| `docs/hosts/homelab.md` | `README.md` | `[← Back to README](../../README.md)` | Breadcrumb navigation back to root |
| `docs/services/homelab-services.md` | `README.md` | `[← Back to README](../../README.md)` | Breadcrumb navigation back to root |
| `docs/reference/shell-aliases.md` | `README.md` | `[← Back to README](../../README.md)` | Breadcrumb navigation back to root |
