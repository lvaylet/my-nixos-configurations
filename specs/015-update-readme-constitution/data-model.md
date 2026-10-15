# Data Model: Update README for Constitution Compliance and Dual-Shell Parity

**Branch**: `015-update-readme-constitution` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This document formalizes the documentation structure, dual-shell command transformations, alias inventories, and constitutional alignment rules for `README.md`.

---

## 1. Dual-Shell Command Transformation Matrix

Every command block in `README.md` is classified as either **Shared (`sh`)** (identical syntax in Bash and Fish) or **Dual-Variant (`bash` + `fish`)** (uses shell-specific syntax):

| Section in `README.md` | Shell-Specific Construct | Bash Variant (`bash`) | Fish Variant (`fish`) |
| --- | --- | --- | --- |
| **Homelab Step 3: Install Remotely with `nixos-anywhere`** | Environment variable export (`export` vs `set -gx`) and parameter expansion (`${TARGET_IP}` vs `$TARGET_IP`) | `export TARGET_IP=<target-ip>`<br>`just install-homelab "${TARGET_IP}"`<br>`nix run github:nix-community/nixos-anywhere -- --flake .#homelab "root@${TARGET_IP}"` | `set -gx TARGET_IP <target-ip>`<br>`just install-homelab "$TARGET_IP"`<br>`nix run github:nix-community/nixos-anywhere -- --flake .#homelab "root@$TARGET_IP"` |
| **Homelab Step 4: Verify SSH Connection** | Parameter expansion (`${TARGET_IP}` vs `$TARGET_IP`) | `ssh "laurent@${TARGET_IP}"` | `ssh "laurent@$TARGET_IP"` |
| **Homelab Step 4: Deploy & Test Routine Updates** | Parameter expansion (`${TARGET_IP}` vs `$TARGET_IP`) | `just deploy-homelab target="${TARGET_IP}"`<br>`just test-homelab target="${TARGET_IP}"` | `just deploy-homelab target="$TARGET_IP"`<br>`just test-homelab target="$TARGET_IP"` |
| **Caddy Step 2: Cloudflare API Token Provisioning** | Multiline file creation (`<< 'EOF'` heredoc vs `printf '%s\n'`) | `sudo tee /persistent/var/lib/caddy/cloudflare.env << 'EOF'`<br>`CLOUDFLARE_API_TOKEN=<your-cloudflare-api-token>`<br>`EOF` | `printf '%s\n' 'CLOUDFLARE_API_TOKEN=<your-cloudflare-api-token>' \| sudo tee /persistent/var/lib/caddy/cloudflare.env` |
| **WAHA Step 4: WAHA Credentials Setup** | Multiline file creation (`<< 'EOF'` heredoc vs `printf '%s\n'`) | `sudo tee /persistent/var/lib/waha/waha.env << 'EOF'`<br>`WAHA_API_KEY=<your-waha-api-key>`<br>`...`<br>`EOF` | `printf '%s\n' 'WAHA_API_KEY=<your-waha-api-key>' 'WAHA_DASHBOARD_USERNAME=admin' 'WAHA_DASHBOARD_PASSWORD=<your-dashboard-password>' 'WHATSAPP_SWAGGER_USERNAME=admin' 'WHATSAPP_SWAGGER_PASSWORD=<your-swagger-password>' \| sudo tee /persistent/var/lib/waha/waha.env` |

---

## 2. Host Shell Architecture & Alias Model

### Entity 1: Two-Tier Shell Duality

| Shell / Layer | Source Module | Target Accounts & Hosts | Capabilities |
| --- | --- | --- | --- |
| **System-Wide Aliases (`environment.shellAliases`)** | `modules/core/base.nix` | `laurent` (Fish) and `root` (Bash) across `desktop-pc`, `homelab`, `iso` | `systemctl` (`sc*`), `journalctl` (`jc*`, `logs*`), and Oh-My-Zsh style `git` (`g*`) aliases active in both Bash and Fish |
| **System-Wide Fish Completions (`programs.fish`)** | `modules/core/base.nix` | `laurent` (default shell `pkgs.fish`) across all hosts | Native `complete -c <alias> -w "<target>"` command wrapping for `systemctl`, `journalctl`, and `git` aliases |
| **Desktop Interactive Fish (`programs.fish` & `programs.starship`)** | `modules/desktop/shell.nix` | `laurent` on `desktop-pc` (Home Manager) | `eza` (`ls`, `ll`, `llt`, `la`, `lat`), `bat` (`cat`), `yazi` (`y`), `btop` (`b`), `ncdu` (`d`), `clear` (`c`), `exit` (`x`), reload (`r`), `take` function, and Starship prompt |

### Entity 2: Complete System-Wide Git Aliases (`modules/core/base.nix`)

| Alias | Command | Purpose / Action |
| --- | --- | --- |
| `g` | `git` | Base git command |
| `gst` | `git status` | Show working tree status |
| `ga` / `gaa` | `git add` / `git add --all` | Stage changes (file autocompletion enabled in Fish) |
| `gco` / `gcb` | `git checkout` / `git checkout -b` | Checkout branch/commit (branch autocompletion enabled in Fish) |
| `gsw` / `gswc` | `git switch` / `git switch -c` | Switch branch (branch autocompletion enabled in Fish) |
| `gc` / `gcm` | `git commit --verbose` / `git commit --message` | Create commit |
| `gca` / `gcam` | `git commit --verbose --all` / `git commit --all --message` | Stage all and commit |
| `gc!` / `gca!` / `gcan!` | `git commit --verbose --amend` / `... --all --amend` / `... --all --no-edit --amend` | Amend previous commit (with or without editing message) |
| `gd` / `gds` | `git diff` / `git diff --staged` | Show unstaged or staged changes |
| `gl` / `gp` / `gpf` | `git pull` / `git push` / `git push --force-with-lease` | Sync with remote repository |
| `gb` / `gba` / `gbd` | `git branch` / `git branch --all` / `git branch --delete` | List or delete branches |
| `glo` / `glg` / `glp` | `git log --oneline --decorate` / `git log --stat` / `git log --patch` | View commit logs |
| `grb` / `grbi` / `grbc` / `grba` | `git rebase` / `--interactive` / `--continue` / `--abort` | Rebase operations |
| `gm` / `gmc` / `gma` | `git merge` / `--continue` / `--abort` | Merge operations |
| `gsta` / `gstp` / `gsts` / `gstd` | `git stash apply` / `pop` / `show --patch` / `drop` | Stash management |
| `grh` / `grhh` | `git reset` / `git reset --hard` | Reset working tree |
| `gclean` | `git clean --interactive -d` | Interactively clean untracked files and directories |

---

## 3. Invariants & Validation Rules

1. **Zero Fish Heredoc Invariant**: No code block labeled for Fish (or shared `sh` block intended for copy-pasting in Fish) may contain `<<` heredoc syntax.
2. **Literal Secret Preservation Invariant**: All secret provisioning snippets (`cloudflare.env`, `waha.env`) MUST quote values with single quotes (`'...'` in Fish, `<< 'EOF'` in Bash) and set `0600` file permissions.
3. **Constitutional Parity Invariant**: All 7 Quality Gates from `.specify/memory/constitution.md` (v2.1.0) and accurate domain descriptions (`modules/core/`, `modules/desktop/`, `modules/services/`, `modules/hosts/`) MUST be present in `README.md`.
