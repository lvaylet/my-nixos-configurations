# Technical Research: Update README for Constitution Compliance and Dual-Shell Parity

**Branch**: `015-update-readme-constitution` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

This document consolidates the technical analysis and design decisions for bringing `README.md` into 100% compliance with `.specify/memory/constitution.md` (v2.1.0), specifically addressing Principle VI (*Living Documentation & Dual-Shell Parity*), Principle VII (*Dedicated Branch & Pull Request Workflow*), Structural & Architectural Constraints, and the Quality Gates & Verification Workflow.

---

## 1. Dual-Shell Command Variant Strategy (Bash vs. Fish)

### Decision

Provide explicit **Bash** (` ```bash `) and **Fish** (` ```fish `) code blocks whenever a documented command relies on syntax that differs between the two shells:
- Environment variable exports (`export VAR=val` in Bash vs `set -gx VAR val` in Fish).
- Parameter expansion (`${VAR}` in Bash vs `$VAR` in Fish).
- Multiline file creation / heredocs (`sudo tee ... << 'EOF'` in Bash vs `printf '%s\n' '...' | sudo tee ...` in Fish).

Keep commands whose syntax is 100% identical in both shells (`devbox ...`, `nix ...`, `just ...`, `tr -dc 'a-f0-9' < /dev/urandom | head -c 64; echo`) as single shared blocks (` ```sh `) labeled or contextualized as compatible with both shells.

### Rationale

- **Strict Compliance with Principle VI**: Constitution Principle VI explicitly states: *"All shell commands and operational instructions in `README.md` MUST be written for both **Bash** and **Fish** users, providing two explicit variants (`Bash` and `Fish`) whenever a command or syntax relies on shell-specific features not shared by both shells (such as environment variable exports, parameter expansion, command substitution, or heredocs)."*
- **Real-World Operator Context**: On managed NixOS hosts (`desktop-pc`, `homelab`), `users.users.laurent.shell = pkgs.fish` (`modules/core/base.nix` line 101) makes Fish the default interactive login shell for `laurent`, whereas `root`, the custom installer ISO (`modules/core/iso.nix`), and typical non-NixOS bootstrap machines default to Bash.
- **Zero-Noise Readability**: Avoiding duplication of identical single-line commands (`just fmt`, `just check`, etc.) keeps `README.md` scannable while guaranteeing 100% copy-paste reliability where syntax diverges.

### Alternatives Considered

- **Duplicating every single code block in `README.md` (including `just build-iso`)**: Creates unnecessary visual bloat for commands with zero syntactic difference between Bash and Fish. Rejected.
- **Rewriting all commands into `sh -c '...'` wrappers**: Obscures the actual commands and violates Principle VI's requirement for two explicit variants (`Bash` and `Fish`). Rejected.

---

## 2. Safe Multiline Secret File Creation in Fish (`cloudflare.env` & `waha.env`)

### Decision

For the Cloudflare API token (`/persistent/var/lib/caddy/cloudflare.env`) and WAHA credentials (`/persistent/var/lib/waha/waha.env`) provisioning steps:
- **Bash variant**: Retain `sudo tee /persistent/var/lib/... << 'EOF'` (single-quoted `'EOF'` delimiter prevents `$`, `` ` ``, and `\` expansion).
- **Fish variant**: Use `printf '%s\n' '<KEY>=<VALUE>' ... | sudo tee /persistent/var/lib/... >/dev/null` (or `| sudo tee ...`) with **single-quoted** arguments.

### Rationale

- **Heredoc Incompatibility in Fish**: Fish does not support `<<` heredocs; pasting `sudo tee ... << 'EOF'` into Fish immediately errors with `fish: Unsupported use of '<<'`.
- **Literal Secret Safety**: In Fish, single quotes (`'...'`) treat every character literally (except `'` and `\`), preventing `$` variable expansion if a generated password or token contains `$`. Using `printf '%s\n'` with one single-quoted argument per line cleanly writes a multiline environment file with trailing newlines identical to the Bash heredoc.

### Alternatives Considered

- **`echo -e "LINE1\nLINE2" | sudo tee ...` in Fish**: Double quotes allow `$VAR` interpolation in Fish, risking silent corruption of secrets containing `$`. Rejected.
- **Using `bash -c "cat << 'EOF' ..."` inside Fish**: Mixes nested quoting levels and defeats native Fish idioms. Rejected.

---

## 3. Documenting Host Shell Duality & Alias Architecture (`modules/core/base.nix` & `modules/desktop/shell.nix`)

### Decision

Expand the **Shell Aliases** section of `README.md` into a comprehensive **Shell Environment & Aliases (Bash & Fish Duality)** section that documents:
1. **Account & Environment Duality**:
   - **Fish (`pkgs.fish`)**: Default interactive login shell for primary user `laurent` across all hosts (`modules/core/base.nix`), enhanced with native command-wrapping autocompletions (`complete -c <alias> -w "<command>"`) so flags, systemd unit names, and Git branches autocomplete seamlessly.
   - **Bash (`pkgs.bashInteractive`)**: Default login shell for `root`, the headless installer ISO (`modules/core/iso.nix`), and POSIX scripts/recipes (`justfile`).
2. **System-Wide Aliases (`environment.shellAliases` in `modules/core/base.nix`)**:
   - Automatically injected by NixOS into **both Bash and Fish** across all hosts (`desktop-pc`, `homelab`, `iso`), ensuring `sc*`, `jc*`/`logs*`, and `g*` shortcuts work identically whether logged in as `laurent` (Fish) or `root` (Bash).
   - Complete the Git aliases table with all entries from `modules/core/base.nix`, including previously omitted aliases (`gcan!`, `grba`, `grbc`, `gstd`, `gclean`) and exact flags (`git commit --verbose`, `git log --oneline --decorate`, `git branch --all`, `git branch --delete`, `git stash show --patch`).
3. **Desktop Interactive Fish Extensions (`modules/desktop/shell.nix`)**:
   - Document the Home Manager Fish aliases and helpers active on `desktop-pc`: `eza` directory listings (`ls`, `ll`, `llt`, `la`, `lat`), modern CLI replacements (`cat` -> `bat`, `y` -> `yazi`, `b` -> `btop`, `d` -> `ncdu`), session helpers (`c` -> `clear`, `x` -> `exit`, `r` -> reload Fish config), the `take` function (`mkdir -p` + `cd`), and Starship prompt integration (`~/.config/starship.toml`).

### Rationale

- Directly answers the user's request (`"Met à jour @README.md pour qu'il soit conforme à la constitution, par exemple sur la dualité entre Bash et Fish."`) by explaining both *how* to run commands in Bash vs. Fish and *how* the repository itself configures Bash and Fish across system and user layers.

---

## 4. Architectural & Constitutional Governance Alignment

### Decision

1. **Architecture Tree (`modules/desktop/`)**:
   - Replace `NNN desktop session, WezTerm, Fish shell, fonts, editors, audio, GPU` on line 53 of `README.md` with `Niri Wayland session, Noctalia shell, WezTerm, Fish shell, fonts, editors, audio, GPU` to match Constitution Section *Structural & Architectural Constraints* (#3).
2. **Quality Gates & Verification Workflow Section**:
   - Add a dedicated **Development Workflow & Constitutional Quality Gates** section in `README.md` (adjacent to Continuous Integration / Quickstart) codifying the 7 mandatory gates from `.specify/memory/constitution.md` (v2.1.0):
     1. **Branch Isolation & Pull Request** (Principle VII: dedicated branch + PR targeting `main`, no direct commits to `main`).
     2. **Living Documentation & Dual-Shell Parity** (Principle VI: update `README.md` in the same branch when services/workflows change, with explicit Bash and Fish variants where syntax differs).
     3. **Formatting** (`just fmt` / `nix fmt .` with `alejandra`).
     4. **Linting & Diagnostics** (`just lint` / `just fix` with `deadnix` and `statix check`).
     5. **Flake Integrity & Hermetic Checks** (`just check` / `nix flake check`).
     6. **Safe Activation Testing** (`just test` / `nh os test` before switching).
     7. **Deployment & Switch** (`just switch` / `just boot`).

### Rationale

- Aligns every section of `README.md` with Constitution v2.1.0, removing the stale `NNN` placeholder left over from earlier desktop iterations and making the repository's governance rules visible to all readers.
