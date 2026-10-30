# Quickstart Validation Guide: Remote Web Code Editor on Homelab

**Feature**: `035-web-code-editor`
**Status**: Ready for Validation

This guide provides end-to-end scenarios to validate the implementation of `code-server` on `homelab`.

---

## Prerequisites

- Local git branch: `035-web-code-editor`
- Active Tailscale connection to the tailnet containing `homelab` (`100.127.199.88`)
- Working tree passes formatting and linting (`just fmt`, `just lint`)

---

## Scenario 1: Flake Evaluation & Sandbox Quality Gates

Validate that the new module and updated host configuration evaluate cleanly without warnings or errors.

### Execution

#### Bash

```bash
# Run code formatting check
just fmt

# Run static analysis and linting
just lint

# Run full flake hermetic sandbox check
just check
```

#### Fish

```fish
# Run code formatting check
just fmt

# Run static analysis and linting
just lint

# Run full flake hermetic sandbox check
just check
```

### Expected Outcome

- `just fmt` succeeds with no unformatted `.nix` files.
- `just lint` (`deadnix` and `statix`) succeeds with 0 errors and 0 warnings.
- `just check` passes all derivation evaluations and pre-commit checks with exit code 0.

---

## Scenario 2: Homelab Activation Test (`nh os test`)

Test activation on `homelab` without permanently setting a new bootloader entry.

### Execution

#### Bash

```bash
# Safely test activation on homelab
just test homelab
```

#### Fish

```fish
# Safely test activation on homelab
just test homelab
```

### Expected Outcome

- NixOS builds the top-level derivation for `homelab`.
- Systemd activates `code-server.service`.
- Caddy reloads its configuration to include `code.homelab.vaylet.fr`.

---

## Scenario 3: Verify Service Status and Process Binding

Connect to `homelab` (or inspect via remote command) to verify the service is running and listening strictly on localhost.

### Execution

#### Bash

```bash
# Check systemd status
ssh homelab "systemctl status code-server.service"

# Verify loopback binding on port 4444
ssh homelab "ss -tulpn | grep 4444"
```

#### Fish

```fish
# Check systemd status
ssh homelab "systemctl status code-server.service"

# Verify loopback binding on port 4444
ssh homelab "ss -tulpn | grep 4444"
```

### Expected Outcome

- `code-server.service` is `active (running)`.
- Process is owned by user `laurent` and group `users`.
- Socket is bound strictly to `127.0.0.1:4444`.

---

## Scenario 4: HTTPS Access via Web Browser

Test end-to-end access from a client device connected to Tailscale.

### Execution

1. Open a modern web browser on a Tailscale-connected device.
2. Navigate to `https://code.homelab.vaylet.fr`.

### Expected Outcome

- Web page connects securely over HTTPS with a valid Cloudflare-issued certificate.
- VS Code Web interface opens immediately without secondary password prompt.
- File explorer shows `/home/laurent` as the default workspace root.
- Integrated terminal can be opened (`Ctrl+\``) and tools like`git`,`just`, and`nix` are available.

---

## Scenario 5: Persistence Across Ephemeral Reboots

Verify that extensions and user configuration survive a system reboot.

### Execution

#### Bash

```bash
# Check preservation bindmounts on homelab
ssh homelab "findmnt /home/laurent/.local/share/code-server"
ssh homelab "findmnt /home/laurent/.config/code-server"
```

#### Fish

```fish
# Check preservation bindmounts on homelab
ssh homelab "findmnt /home/laurent/.local/share/code-server"
ssh homelab "findmnt /home/laurent/.config/code-server"
```

### Expected Outcome

- Bind mounts point to `/persistent/home/laurent/.local/share/code-server` and `/persistent/home/laurent/.config/code-server`.
- Files written in those directories survive host reboots.
