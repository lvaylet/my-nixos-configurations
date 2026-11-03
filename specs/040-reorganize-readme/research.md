# Technical Research: Reorganize README for Progressive Disclosure and Clarity

**Feature Branch**: `040-reorganize-readme`

**Created**: 2026-11-03

**Spec**: [`specs/040-reorganize-readme/spec.md`](./spec.md)

---

## Technical Context & Decisions

### 1. Information Architecture & Modular Directory Layout

- **Problem**: The root `README.md` is currently 612 lines long. It bundles high-level introductory information with deep, one-time bootstrap procedures (APFS `/etc/synthetic.conf`, `nixos-anywhere` disk partitioning, custom ISO building), 10 service-specific secret/setup manuals, and over 100 lines of standard Git and systemctl alias cheat sheets. This creates high cognitive friction for casual readers and everyday operators.
- **Decision**: Adopt a modular "Hub and Spoke" information architecture under a dedicated `docs/` directory:

  ```text
  my-nixos-configurations/
  ├── README.md                          # Concise landing hub (< 200 lines)
  └── docs/
      ├── hosts/
      │   ├── macbook.md                 # Full macOS (M4) provisioning & daily ops
      │   └── homelab.md                 # Headless bare-metal bootstrap (ISO + nixos-anywhere)
      ├── services/
      │   └── homelab-services.md        # Comprehensive setup recipes for all 12 homelab services
      └── reference/
          └── shell-aliases.md           # Exhaustive Git, systemctl, journalctl, and Fish tables
  ```

- **Rationale**:
  - `README.md` acts as a fast orientation hub (< 200 lines): architecture, machine topology, quickstart, and primary `just` operations.
  - One-time installation tasks are separated from daily maintenance workflows.
  - Deep per-service setup recipes (API tokens, QR pairing, proxy headers) reside in a dedicated guide.
  - Alias cheat sheets are preserved in full without clogging the main repository overview.
- **Alternatives Considered**:
  - *Single-file with collapsible `<details>` blocks*: Rejected because a 600+ line single file remains heavy to load, edit, and navigate; search indexing and diff reviews remain cumbersome.
  - *Per-service individual files (`docs/services/caddy.md`, `waha.md`, etc.)*: Premature fragmentation; a single unified `docs/services/homelab-services.md` keeps all service configurations together in one searchable reference while keeping `README.md` lean.

---

### 2. Living Documentation & Constitution Principle VI Alignment

- **Problem**: Principle VI of the repository constitution mandates:
  > "`README.md` MUST always reflect all modifications introduced in the current branch. Whenever a service is added, modified, or removed, `README.md` MUST be updated within the same branch to keep service tables, network/port mappings, reverse proxy endpoints, persistent storage paths, and setup instructions accurate. All shell commands and operational instructions in `README.md` MUST be written for both Bash and Fish users..."
- **Decision**:
  - Keep the **Hosted Services Summary Table** and **Reverse Proxy & URLs Table** directly in `README.md` so the service catalog, endpoints, and storage paths remain visible at a glance in the root document.
  - Add explicit cross-links from `README.md` to `docs/services/homelab-services.md` for the multi-step initial configuration instructions (Cloudflare tokens, WAHA pairing, Home Assistant proxy, etc.).
  - Enforce strict dual-shell (**Bash** and **Fish**) command parity across `README.md` and all documents under `docs/`.
- **Rationale**: Retains the essential inventory in `README.md` to satisfy the letter and spirit of Principle VI, while moving lengthy procedural runbooks into dedicated docs.

---

### 3. Content Boundaries for Root `README.md`

- **Included in `README.md`** (< 200 lines):
  1. Header & CI status badge
  2. One-sentence project elevator pitch
  3. Managed Hosts Topology (concise matrix table: `desktop-pc`, `homelab`, `macbook-air-m4-15`, `iso`)
  4. Architecture Overview (The Dendritic Pattern summary + directory tree)
  5. Quickstart & Dev Environment (Devbox & native Nix Flakes `direnv`)
  6. Common Operational Recipes (`just` command table & remote deployment summary)
  7. Hosted Services Summary (compact service and reverse proxy endpoints table)
  8. Quality Gates & Verification Workflow summary
  9. Documentation Directory Index (direct links to `docs/hosts/`, `docs/services/`, and `docs/reference/`)
  10. References & upstream inspiration
- **Extracted to `docs/hosts/macbook.md`**:
  - First-time provisioning (`xcode-select`, determinate nix-installer, `/etc/synthetic.conf` creation with `apfs.util`, initial `nix-darwin` switch).
  - Routine maintenance & rollback commands.
  - Client access to homelab services (Tailscale SSH, LAN shortcuts, web endpoints).
- **Extracted to `docs/hosts/homelab.md`**:
  - Headless installation workflow (`just build-iso`, target boot, `nixos-anywhere` deployment).
  - Ephemeral root (`tmpfs`) and preservation architecture details (`/persistent`, Btrfs subvolumes).
  - Routine update procedures (local and remote `just test` / `just switch`).
- **Extracted to `docs/services/homelab-services.md`**:
  - Cloudflare DNS wildcard & API token provisioning (`cloudflare.env`).
  - Home Assistant reverse proxy authorization in UI.
  - WAHA credentials generation & WhatsApp QR pairing.
  - Uptime Kuma Docker socket setup.
  - Tailscale SSH ACL policy json.
  - OpenCode initial setup, skills bundle, and password retrieval.
  - SGDF tools API token retrieval & n8n integration.
  - Code-Server setup & access.
  - Automated Podman container updates (timer & `just update-containers`).
  - Shared multimedia storage (`/data`) permissions & SetGID bit.
- **Extracted to `docs/reference/shell-aliases.md`**:
  - Systemctl management aliases (`sc`, `scs`, `scr`, etc.).
  - Journalctl inspection aliases (`jc`, `logs`, `logsf`, etc.).
  - Git shortcuts table (25 Oh-My-Zsh style aliases).
  - Desktop interactive Fish extensions (`eza`, `bat`, `yazi`, `btop`).
  - Nord visual theme color palette & component mapping.
  - Dynamic Noctalia wallpaper automation & keybindings.
  - FiraCode Nerd Font typography configuration.
  - VS Code / Code Server unified settings.
  - Neovim / LazyVim modal editor setup.

---

### 4. Markdown Style & Quality Gate Validation

- **Decision**: Validate all documentation using the existing tooling:
  - Markdown linting: `just lint-md` (`markdownlint-cli2`)
  - Auto-formatting: `just fix-md` (`markdownlint-cli2 --fix`)
  - Flake and pre-commit checks: `just check` (`nix flake check`)
- **Relative Links Invariant**:
  - All links from `README.md` into `docs/` must use standard relative links (e.g. `[macOS Workstation Guide](docs/hosts/macbook.md)`).
  - All links from within `docs/` back to the root must use relative links (e.g. `[← Back to README](../../README.md)`).
