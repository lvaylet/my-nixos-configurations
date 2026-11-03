# Contract: Root README.md Information Architecture

**Feature Branch**: `040-reorganize-readme`

**Created**: 2026-11-03

**Target File**: `README.md`

---

## 1. Document Structure & Maximum Line Budget

The root `README.md` MUST adhere to a strict length limit of **less than 200 lines** (target: ~150–180 lines). It acts as an inviting overview and fast orientation hub.

### Required Section Sequence

1. **Title & Badge**:
   - Repository name: `# my-nixos-configurations`
   - CI status badge linking to GitHub Actions workflow
   - High-level elevator pitch (1–2 sentences)
2. **Managed Hosts Topology**:
   - Markdown table summarizing the 4 closure targets:
     - `desktop-pc`: Primary workstation (NixOS, Niri Wayland, Nvidia)
     - `homelab`: Headless server (NixOS, impermanent tmpfs, Docker/Podman, Caddy)
     - `macbook-air-m4-15`: Portable workstation (macOS, nix-darwin, Home Manager)
     - `iso`: Bootable headless installer image with pre-baked SSH keys
3. **Architecture: The Dendritic Pattern**:
   - Concise 4-bullet summary: Feature-Centric Design, Zero-Boilerplate Auto-Discovery (`import-tree`), Declarative Host Composition, Unified Identity (`vars.nix`).
   - Clean directory layout diagram (`modules/core/`, `modules/desktop/`, `modules/services/`, `modules/hosts/`).
4. **Quickstart & Environment Setup**:
   - Option 1: Cross-Platform via Devbox (`devbox shell`)
   - Option 2: Native Nix Flakes with `direnv` (`direnv allow` / `nix develop`)
5. **Operational Recipes (`justfile`)**:
   - Concise summary table of primary lifecycle recipes: `build`, `test`, `switch`, `boot`, `check`, `fmt`, `lint`.
   - Brief dual-shell examples for local and remote deployments (`just switch homelab`).
6. **Hosted Services Summary**:
   - Compact table listing all homelab services, their domain URL, upstream local port, and brief description.
   - Clear pointer: `*For detailed secret provisioning, initial setup recipes, and media permissions, see the [Homelab Services Guide](docs/services/homelab-services.md).*`
7. **Quality Gates & CI**:
   - Brief summary of repository constitutional quality standards and CI pipeline.
8. **Documentation Directory**:
   - Navigation links to the modular guides in `docs/`:
     - `[macOS Workstation Guide](docs/hosts/macbook.md)`
     - `[Homelab Bootstrap Guide](docs/hosts/homelab.md)`
     - `[Homelab Services Guide](docs/services/homelab-services.md)`
     - `[Shell Aliases & Design Guide](docs/reference/shell-aliases.md)`
9. **References**:
   - Key inspiration links (Vimjoyer impermanence, nixos-anywhere, Dendritic pattern).

---

## 2. Invariants & Prohibitions for `README.md`

- **PROHIBITED**: Embedding raw secret generation snippets (`/dev/urandom`, `cloudflare.env`, `waha.env`, `SGDF_AUTH_TOKEN`).
- **PROHIBITED**: Embedding multi-step bootstrap workflows for individual hosts (e.g. APFS `/etc/synthetic.conf`, `nixos-anywhere` drive partitioning).
- **PROHIBITED**: Embedding 100+ lines of standard alias reference tables (Git aliases, systemctl aliases, Fish helper functions).
- **MANDATORY**: Any shell snippet with syntax differences between Bash and Fish MUST provide explicit Bash and Fish code blocks.
- **MANDATORY**: Total file line count MUST be < 200 lines.
