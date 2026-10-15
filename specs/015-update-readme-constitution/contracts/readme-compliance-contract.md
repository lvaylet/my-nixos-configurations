# README Constitution Compliance & Dual-Shell Parity Contract

**Feature**: `015-update-readme-constitution`
**Target File**: `README.md`
**Reference Standard**: `.specify/memory/constitution.md` (v2.1.0)

## 1. Structural & Content Contract

`README.md` MUST satisfy the following structural and content requirements:

1. **Architecture Section (`## Architecture: The Dendritic Pattern`)**:
   - The `modules/desktop/` directory entry MUST list `Niri Wayland session, Noctalia shell, WezTerm, Fish shell, fonts, editors, audio, GPU` (replacing the legacy `NNN desktop session` placeholder).
   - All four domain directories (`core/`, `desktop/`, `services/`, `hosts/`) MUST match the Constitution's *Structural & Architectural Constraints*.

2. **Homelab Provisioning & Deployment Dual-Shell Blocks (`### Initial Provisioning of Homelab`)**:
   - Step 3 (*Install Remotely with `nixos-anywhere`*): MUST provide explicit **Bash** (`export TARGET_IP=<target-ip>`, `${TARGET_IP}`) and **Fish** (`set -gx TARGET_IP <target-ip>`, `$TARGET_IP`) code blocks.
   - Step 4 (*Verify and Deploy Subsequent Updates*): MUST provide explicit **Bash** and **Fish** code blocks for `ssh` and `just deploy-homelab` / `just test-homelab` using `${TARGET_IP}` (Bash) and `$TARGET_IP` (Fish).

3. **Service Secret Provisioning Dual-Shell Blocks (`##### Configuration Instructions`)**:
   - Item 2 (*Cloudflare API Token Provisioning*): MUST provide explicit **Bash** (`sudo tee /persistent/var/lib/caddy/cloudflare.env << 'EOF'`) and **Fish** (`printf '%s\n' 'CLOUDFLARE_API_TOKEN=<your-cloudflare-api-token>' | sudo tee /persistent/var/lib/caddy/cloudflare.env`) code blocks, both enforcing `chown -R caddy:caddy` and `chmod 0600`.
   - Item 4 (*WAHA Credentials & Initial WhatsApp Session Setup*): MUST provide explicit **Bash** (`sudo tee /persistent/var/lib/waha/waha.env << 'EOF'`) and **Fish** (`printf '%s\n' ... | sudo tee /persistent/var/lib/waha/waha.env`) code blocks with single-quoted lines, both enforcing `chmod 0600` and restarting `podman-waha`.

4. **Development Workflow & Constitutional Quality Gates (`## Quality Gates & Verification Workflow`)**:
   - MUST document the 7 constitutional gates from `.specify/memory/constitution.md`:
     1. Branch Isolation & Pull Request (`main` branch protection, dedicated branch + PR).
     2. Living Documentation & Dual-Shell Parity (`README.md` updated in same branch, Bash & Fish variants).
     3. Formatting (`just fmt` / `nix fmt .`).
     4. Linting & Diagnostics (`just lint` / `just fix`).
     5. Flake Integrity & Checks (`just check` / `nix flake check`).
     6. Safe Activation Testing (`just test`).
     7. Deployment & Switch (`just switch` / `just boot`).

5. **Shell Environment & Aliases Section (`## Shell Environment & Aliases (Bash & Fish Duality)`)**:
   - MUST explain the duality between **Fish** (primary user `laurent`'s default login shell with native `complete -w` autocompletions) and **Bash** (`root` login shell, installer ISO, and non-NixOS bootstrap environments), noting that `environment.shellAliases` (`modules/core/base.nix`) applies to both shells across all hosts.
   - MUST list all `systemctl` (`sc*`), `journalctl` (`jc*`, `logs*`), and `git` (`g*`, including `gcan!`, `grba`, `grbc`, `gstd`, `gclean`) system-wide aliases.
   - MUST document the desktop-specific interactive Fish aliases, `take` function, and Starship prompt integration from `modules/desktop/shell.nix`.

---

## 2. Verification Contract

- Every **Fish** snippet in `README.md` MUST pass syntax checking via `fish --no-execute` (`fish -n`).
- Every **Bash** snippet in `README.md` MUST pass syntax checking via `bash -n`.
- Repository checks (`just fmt`, `just lint`, `just check`) MUST exit with status `0`.
