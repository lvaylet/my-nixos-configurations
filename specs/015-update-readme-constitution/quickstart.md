# Quickstart Validation Guide: Update README for Constitution Compliance and Dual-Shell Parity

**Branch**: `015-update-readme-constitution` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This guide provides runnable validation scenarios (with both **Bash** and **Fish** commands where applicable) to verify that `README.md` satisfies all requirements in [spec.md](spec.md) and [contracts/readme-compliance-contract.md](contracts/readme-compliance-contract.md).

---

## Prerequisites

1. Working copy of `my-nixos-configurations` on branch `015-update-readme-constitution`.
2. Nix with Flakes enabled (`nix-command flakes`) and `just` installed.

---

## Scenario 1: Verify Dual-Shell Code Blocks & Absence of Outdated Placeholders

Confirm that `README.md` includes explicit `bash` and `fish` code blocks for shell-specific commands, documents the Niri/Noctalia desktop stack, and includes all missing Git aliases and Constitutional Quality Gates.

**Bash / Fish**:

```sh
# 1. Confirm no outdated 'NNN desktop session' placeholder remains:
! rg -n 'NNN desktop session' README.md

# 2. Confirm explicit bash and fish code fences exist in README.md:
rg -n '^```(bash|fish)$' README.md

# 3. Confirm Niri, Noctalia, Fish set -gx, printf tee, and Quality Gates are documented:
rg -n 'Niri|Noctalia|set -gx TARGET_IP|printf .%s\\n.|gcan!|gclean|Quality Gates' README.md
```

**Expected Outcome**:

- Zero matches for `NNN desktop session`.
- Explicit ```` ```bash ```` and ```` ```fish ```` blocks appear for Homelab provisioning/updates, Cloudflare API token setup, and WAHA credential setup.
- Matches confirm presence of Niri/Noctalia, `set -gx TARGET_IP`, `printf '%s\n'`, complete Git aliases, and Quality Gates.

---

## Scenario 2: Validate Syntax of Documented Bash and Fish Commands

Verify that the Bash and Fish command patterns documented in `README.md` parse cleanly with `bash -n` and `fish --no-execute` (`fish -n`).

**Bash**:

```bash
bash -n << 'EOF'
export TARGET_IP=192.168.1.181
just install-homelab "${TARGET_IP}"
nix run github:nix-community/nixos-anywhere -- --flake .#homelab "root@${TARGET_IP}"
ssh "laurent@${TARGET_IP}"
just deploy-homelab target="${TARGET_IP}"
just test-homelab target="${TARGET_IP}"
sudo mkdir -p /persistent/var/lib/caddy
sudo tee /persistent/var/lib/caddy/cloudflare.env << 'INNER_EOF'
CLOUDFLARE_API_TOKEN=<your-cloudflare-api-token>
INNER_EOF
sudo chown -R caddy:caddy /persistent/var/lib/caddy
sudo chmod 0600 /persistent/var/lib/caddy/cloudflare.env
EOF
```

**Fish**:

```fish
fish --no-execute -c '
set -gx TARGET_IP 192.168.1.181
just install-homelab "$TARGET_IP"
nix run github:nix-community/nixos-anywhere -- --flake .#homelab "root@$TARGET_IP"
ssh "laurent@$TARGET_IP"
just deploy-homelab target="$TARGET_IP"
just test-homelab target="$TARGET_IP"
sudo mkdir -p /persistent/var/lib/caddy
printf "%s\n" "CLOUDFLARE_API_TOKEN=<your-cloudflare-api-token>" | sudo tee /persistent/var/lib/caddy/cloudflare.env
sudo chown -R caddy:caddy /persistent/var/lib/caddy
sudo chmod 0600 /persistent/var/lib/caddy/cloudflare.env
'
```

**Expected Outcome**:

- Both `bash -n` and `fish --no-execute` exit with code `0` and zero syntax errors.

---

## Scenario 3: Verify Repository Formatting, Linting & Hermetic Flake Checks

Ensure all repository files pass formatting, static analysis, and pre-commit secret/hygiene hooks.

**Bash / Fish**:

```sh
just fmt
just lint
just check
```

**Expected Outcome**:

- `just fmt`, `just lint`, and `just check` complete with exit code `0` (including `ripsecrets`, `trufflehog`, `detect-private-keys`, `trailing-whitespace`, and `end-of-file-fixer`).
