# Feature Specification: Update README for Constitution Compliance and Dual-Shell Parity

**Feature Branch**: `015-update-readme-constitution`

**Created**: 2026-10-15

**Status**: Draft

**Input**: User description: "Met à jour @README.md pour qu'il soit conforme à la constitution, par exemple sur la dualité entre Bash et Fish."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Dual-Shell Parity for Operational & Provisioning Commands (Priority: P1)

As a system operator or contributor working in either a **Bash** environment (such as a recovery shell, `root` SSH session, installer ISO, or non-NixOS bootstrap workstation) or the repository's default interactive **Fish** shell (configured for primary user `laurent`), I want `README.md` to provide explicit **Bash** and **Fish** command variants whenever operational instructions rely on shell-specific syntax (such as environment variable exports, parameter expansion, or multiline file creation via heredocs), so that I can copy and paste any command directly into my active shell without syntax errors.

**Why this priority**: Directly fulfills Principle VI (*Living Documentation & Dual-Shell Parity*) of the Constitution and prevents immediate command failures—most notably Fish rejecting POSIX `<< 'EOF'` heredocs during secret provisioning or differing on `export` and `${VAR}` parameter expansion during homelab installation.

**Independent Test**: Inspect all command blocks in `README.md` and verify that every snippet using shell-specific syntax provides clearly labeled **Bash** and **Fish** variants that execute cleanly in their respective shells.

**Acceptance Scenarios**:

1. **Given** the Homelab Initial Provisioning and Routine Updates instructions in `README.md`, **When** an operator sets the target IP variable and runs `just install-homelab`, `nixos-anywhere`, `ssh`, `just deploy-homelab`, or `just test-homelab`, **Then** `README.md` provides both a **Bash** variant (`export TARGET_IP=<target-ip>` and `${TARGET_IP}`) and a **Fish** variant (`set -gx TARGET_IP <target-ip>` and `$TARGET_IP`).
2. **Given** the service secret provisioning instructions in `README.md` (Cloudflare API token in `/persistent/var/lib/caddy/cloudflare.env` and WAHA credentials in `/persistent/var/lib/waha/waha.env`), **When** an operator connected to `homelab` copies the commands into either a Bash shell or a Fish shell, **Then** `README.md` provides both a **Bash** variant (using `<< 'EOF'` heredoc with `sudo tee`) and a **Fish** variant (using single-quoted `printf '%s\n'` piped to `sudo tee`) that write identical file contents without unintended variable expansion and apply `0600` permissions.
3. **Given** shell commands in `README.md` whose syntax is identical in both Bash and Fish (such as `just ...`, `nix ...`, `devbox ...`, or `tr -dc 'a-f0-9' < /dev/urandom | head -c 64; echo`), **When** an operator reads the documentation, **Then** those shared commands remain concise without redundant duplication.

---

### User Story 2 - Accurate Documentation of Host Shell Duality & Aliases (Priority: P2)

As a system administrator logging into any managed NixOS host (`desktop-pc`, `homelab`, or `iso`), I want `README.md` to clearly explain the dual-shell architecture across user accounts and environments—where Fish is the primary user's (`laurent`) default login shell with native command-wrapping autocompletions and desktop extensions, while Bash serves `root` and recovery/installer environments, with both shells sharing system-wide aliases—so that I know which shell and shortcuts are active in every operational context.

**Why this priority**: Explains the architectural duality between Bash and Fish across the repository's hosts and ensures the Shell Aliases section accurately reflects the live declarations in `modules/core/base.nix` and `modules/desktop/shell.nix`.

**Independent Test**: Read the Shell Aliases and Environment sections of `README.md` and verify that the roles of Fish and Bash across accounts (`laurent` vs `root`), system-wide aliases (`environment.shellAliases`), Fish autocompletions (`complete -c ... -w ...`), and desktop Fish aliases/functions are completely and accurately documented.

**Acceptance Scenarios**:

1. **Given** the Shell Aliases section in `README.md`, **When** a reader checks how aliases and shells are configured across hosts, **Then** the documentation explains that `environment.shellAliases` (`systemctl`, `journalctl`, and `git` shortcuts in `modules/core/base.nix`) are active in **both Bash and Fish** (for both `laurent` and `root`), while Fish additionally provides native command-wrapping autocompletions (`complete -c ... -w ...`).
2. **Given** the Git and shell alias tables in `README.md`, **When** compared against `modules/core/base.nix` and `modules/desktop/shell.nix`, **Then** all declared system-wide Git aliases (including `gcan!`, `grba`, `grbc`, `gstd`, `gclean`) and desktop-specific Fish aliases/functions (`eza` listings `ls`/`ll`/`llt`/`la`/`lat`, `bat`, `yazi`, `btop`, `ncdu`, `take`, and Starship prompt integration) are accurately documented.

---

### User Story 3 - Full Alignment with Constitutional Architecture & Quality Gates (Priority: P2)

As a repository maintainer or contributor, I want `README.md` to accurately reflect the current system architecture (including Niri and Noctalia in `modules/desktop/` rather than outdated placeholder names) and the mandatory constitutional workflow (dedicated branch and Pull Request isolation, living documentation synchronization, shift-left quality gates, and safe activation testing before switching), so that `README.md` is 100% compliant with the project Constitution (v2.1.0).

**Why this priority**: Eliminates architectural drift in `README.md` and surfaces the non-negotiable governance and verification rules from `.specify/memory/constitution.md` directly to contributors and operators.

**Independent Test**: Compare `README.md` section-by-section against `.specify/memory/constitution.md` (v2.1.0) and verify that all module descriptions, architectural constraints, and quality gate steps match without discrepancies.

**Acceptance Scenarios**:

1. **Given** the Architecture section in `README.md`, **When** a reader inspects the `modules/desktop/` directory summary, **Then** it accurately lists the Niri Wayland compositor, Noctalia desktop shell, WezTerm, Fish shell, fonts, editors (nvf/Neovim, VS Code, Zed), audio, and GPU instead of the outdated `NNN desktop session` placeholder.
2. **Given** the development and verification sections in `README.md`, **When** a contributor reviews the workflow for introducing changes, **Then** `README.md` documents the mandatory constitutional quality gates: working in a dedicated branch associated with a Pull Request targeting `main` (no direct commits to `main`), synchronizing `README.md` within the same branch with dual Bash/Fish command parity, running formatting/linting/flake checks (`just fmt`, `just lint`, `just check`), and verifying activation (`just test`) prior to switching (`just switch` or `just boot`).

---

### Edge Cases

- **Multiline Secret Provisioning in Fish**: Standard POSIX heredocs (`<< 'EOF'`) fail immediately in Fish with `Unsupported use of '<<'`. The Fish variant must use single-quoted strings with `printf '%s\n'` piped to `sudo tee` so special characters in tokens or passwords (such as `$` or `!`) are written literally without shell interpolation.
- **Commands Shared Identically Between Bash and Fish**: Simple commands without variable exports, parameter expansion, or heredocs (e.g., `just check`, `nix develop`, `devbox run lint`, `just switch configuration="homelab" target="homelab"`) run identically in both Bash and Fish; keeping them as single shared blocks avoids unnecessary duplication while dual blocks are provided wherever syntax differs.
- **SSH Login Shell Differences (`laurent` vs. `root`)**: Logging into `homelab` as `laurent` opens an interactive **Fish** shell (`users.users.laurent.shell = pkgs.fish`), whereas logging in as `root` or using the installer ISO opens **Bash**; provisioning instructions must make both variants immediately accessible at the point of use.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `README.md` MUST provide explicit **Bash** and **Fish** command variants for every operational instruction that relies on shell-specific syntax not shared by both shells (including environment variable exports, parameter expansion `${VAR}` vs `$VAR`, and multiline file creation / heredocs).
- **FR-002**: In the Homelab Initial Provisioning and Routine Updates section, `README.md` MUST provide both **Bash** (`export TARGET_IP=<target-ip>` and `${TARGET_IP}`) and **Fish** (`set -gx TARGET_IP <target-ip>` and `$TARGET_IP`) variants for defining the target IP address, running `just install-homelab`, invoking `nixos-anywhere`, connecting via `ssh`, and executing `just deploy-homelab` / `just test-homelab`.
- **FR-003**: In the Cloudflare API Token Provisioning (`/persistent/var/lib/caddy/cloudflare.env`) and WAHA Credentials Setup (`/persistent/var/lib/waha/waha.env`) sections, `README.md` MUST provide both a **Bash** variant (using `sudo tee ... << 'EOF'`) and a **Fish** variant (using single-quoted `printf '%s\n' ... | sudo tee ...`) that preserve literal secret values without variable interpolation and enforce `0600` permissions.
- **FR-004**: `README.md` MUST document the Bash/Fish shell duality across hosts: explaining that Fish is the primary user's (`laurent`) default interactive login shell with native command-wrapping autocompletions (`complete -c ... -w ...`), while Bash serves as the default shell for `root`, the custom installer ISO, and non-NixOS bootstrap environments, and that system-wide aliases (`environment.shellAliases` in `modules/core/base.nix`) are available in both Bash and Fish.
- **FR-005**: `README.md` MUST ensure the Git aliases table and shell documentation cover all system-wide aliases declared in `modules/core/base.nix` (adding any missing entries such as `gcan!`, `grba`, `grbc`, `gstd`, `gclean`) and document the desktop-specific interactive Fish aliases, `take` helper function, and Starship prompt integration declared in `modules/desktop/shell.nix`.
- **FR-006**: `README.md` MUST update the `modules/desktop/` summary in the Architecture section to replace the outdated `NNN desktop session` label with the actual desktop components (Niri Wayland compositor, Noctalia shell, WezTerm, Fish shell, fonts, editors, audio, GPU) in accordance with the Constitution's Structural & Architectural Constraints.
- **FR-007**: `README.md` MUST document the repository's constitutional Quality Gates & Verification Workflow (Principles V, VI, VII), explicitly covering:
  1. Dedicated branch isolation and Pull Request requirement targeting `main` (prohibiting direct commits to `main`).
  2. Living documentation synchronization in `README.md` (mandatory service table/endpoint updates and dual Bash/Fish command parity).
  3. Shift-left formatting (`just fmt`), linting (`just lint` / `just fix`), and hermetic sandbox checks (`just check`).
  4. Safe non-switching activation testing (`just test`) prior to permanent profile activation (`just switch` / `just boot`).
- **FR-008**: All updates to `README.md` MUST maintain clean Markdown formatting and pass all repository quality gates (`just fmt`, `just lint`, `just check`) with zero errors or secret detection false positives.

### Key Entities

- **Dual-Shell Command Variant**: A paired set of **Bash** and **Fish** command snippets in `README.md` that accomplish the exact same configuration or deployment step using idiomatic syntax for each shell.
- **Host Shell Architecture**: The two-tier configuration across NixOS hosts combining system-wide aliases and Fish completions (`modules/core/base.nix`) with Home Manager user shell customizations (`modules/desktop/shell.nix`).
- **Constitutional Quality Gates**: The seven-stage governance and verification workflow defined in `.specify/memory/constitution.md` (v2.1.0) governing branch isolation, documentation parity, static analysis, and safe deployment.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of shell command blocks in `README.md` that use shell-specific features (environment variable exports, `${VAR}` parameter expansion, or `<< 'EOF'` heredocs) provide explicit **Bash** and **Fish** variants.
- **SC-002**: 100% of documented **Bash** and **Fish** command snippets in `README.md` are valid in their target shell with 0 syntax incompatibilities (such as `<<` heredocs in Fish).
- **SC-003**: 100% of system-wide aliases in `modules/core/base.nix` and architectural/workflow mandates in `.specify/memory/constitution.md` (v2.1.0) are accurately reflected in `README.md` with 0 outdated module placeholders.
- **SC-004**: 100% pass rate on repository formatting, static analysis, and flake check gates (`just fmt`, `just lint`, `just check`).

## Assumptions

- Commands that are syntactically identical in both Bash and Fish (such as `just fmt`, `just lint`, `just check`, `nix develop`, `devbox shell`, or `just switch configuration="homelab" target="homelab"`) remain as single shared snippets to keep the documentation concise and readable.
- Single-quoted strings with `printf '%s\n'` piped to `sudo tee` are used as the idiomatic Fish equivalent to Bash's single-quoted `<< 'EOF'` heredoc, ensuring that secret values containing `$` or other special characters are never interpolated by the shell.
- `README.md` continues to be written in English, consistent with the existing `README.md` and `.specify/memory/constitution.md`.
