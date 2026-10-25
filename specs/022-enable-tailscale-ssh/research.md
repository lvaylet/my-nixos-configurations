# Technical Research: Dynamic Tailnet SSH Access Without Static Key Distribution

**Feature**: `022-enable-tailscale-ssh`
**Status**: Completed
**Date**: 2026-10-25

---

## 1. Tailscale SSH vs. Alternative Dynamic SSH Authentication Mechanisms

### Context

Whenever a new client machine joins the private Tailscale network (tailnet), accessing `homelab` over SSH previously required generating an SSH keypair on the new client, committing its public key to `modules/core/vars.nix`, and rebuilding `homelab`. We need a zero-key-distribution mechanism that authorizes any authenticated tailnet device while preserving local LAN recovery access.

### Decision

Adopt **Tailscale SSH** by declaring `services.tailscale.extraSetFlags = ["--ssh"];` in `modules/services/tailscale.nix`, paired with a Tailscale ACL `ssh` policy rule in the Tailscale Admin Console.

### Rationale

- **Zero Static Key Distribution**: Tailscale intercepts port `22` exclusively on the `tailscale0` (`100.x.y.z`) interface and authenticates connections using the caller's cryptographic tailnet node identity and user membership.
- **Centralized Policy & Check Mode**: Access to `laurent` and `root` is governed centrally in the Tailscale Admin Console (`"action": "check"`), allowing high-privilege session verification without managing static public keys per client.
- **Non-Breaking Coexistence with OpenSSH**: Because `tailscaled` only intercepts SSH traffic destined for the Tailscale CGNAT IP (`100.x.y.z`), `sshd` (`services.openssh`) continues listening on physical LAN interfaces (`192.168.1.180`) using the static `authorizedKeys` declared in `modules/core/base.nix` and `modules/hosts/homelab.nix`.

### Alternatives Considered

- **OpenSSH `AuthorizedKeysCommand` (e.g., fetching `https://github.com/<user>.keys`)**:
  - *Pros*: Dynamic key discovery without rebuilding `homelab`.
  - *Cons*: Introduces an external runtime dependency on GitHub's availability during login, authorizes any public key published to GitHub regardless of tailnet membership, and still requires generating and uploading SSH keys on every new client device.
- **SSH Certificate Authority (`TrustedUserCAKeys` / Step-CA)**:
  - *Pros*: Standard OpenSSH cryptographic certificate authentication.
  - *Cons*: Significant operational overhead to host, secure, and renew a dedicated CA and short-lived client certificates for a personal homelab.
- **Shared Static Private Key Across Devices**:
  - *Pros*: No rebuild required on `homelab`.
  - *Cons*: Violates security best practices; compromising one client device compromises all devices and prevents per-device revocation.

---

## 2. NixOS Activation Mechanism: `extraSetFlags` vs. `extraUpFlags`

### Context

The NixOS `services.tailscale` module exposes both `services.tailscale.extraUpFlags` and `services.tailscale.extraSetFlags`. We must choose the option that reliably activates Tailscale SSH on already-authenticated hosts as well as after reboots or system switches.

### Decision

Configure `services.tailscale.extraSetFlags = ["--ssh"];` in `modules/services/tailscale.nix` and augment `systemd.services.tailscaled-set` with `wantedBy = ["multi-user.target"]`, `partOf = ["tailscaled.service"]`, and `serviceConfig.RemainAfterExit = true`.

### Rationale

- In `nixpkgs` (`nixos/modules/services/networking/tailscale.nix`), `services.tailscale.extraUpFlags` is **only** passed to `tailscale up` when `services.tailscale.authKeyFile` is non-null (`tailscaled-autoconnect.service`). Because `modules/services/tailscale.nix` does not set `authKeyFile`, `extraUpFlags` would be a no-op.
- Setting `services.tailscale.extraSetFlags = ["--ssh"];` enables `systemd.services.tailscaled-set`, which executes `tailscale set '--ssh'`.
- However, upstream `nixpkgs` only sets `wantedBy = ["tailscaled.service"]` and `Type = "oneshot"` (without `RemainAfterExit = true`) on `tailscaled-set.service`. During `nixos-rebuild switch`, if `tailscaled.service` is already active and its own unit file has not changed, `switch-to-configuration` does not restart `tailscaled.service` and does not start units that are not wanted by `multi-user.target`—leaving `tailscaled-set.service` `inactive (dead)` and `"RunSSH": false` until a reboot or manual restart.
- Adding `wantedBy = ["multi-user.target"]`, `partOf = ["tailscaled.service"]`, and `serviceConfig.RemainAfterExit = true` guarantees that `switch-to-configuration` immediately starts `tailscaled-set.service` on live switches, marks it `active (exited)`, and re-applies flags whenever `tailscaled.service` restarts.

### Alternatives Considered

- **`services.tailscale.extraUpFlags = ["--ssh"];`**:
  - Rejected: Ignored by NixOS unless `services.tailscale.authKeyFile` is also configured.
- **Imperative `sudo tailscale set --ssh`**:
  - Rejected: Violates Constitution Principle I (*Declarative & Hermetic Configuration*), as the setting is not codified in the flake or enforced on newly provisioned hosts.

---

## 3. Coexistence of Tailscale SSH and OpenSSH (`services.ssh`)

### Context

`homelab` and `desktop-pc` both import `services.ssh` (`modules/services/ssh.nix`) and `services.tailscale` (`modules/services/tailscale.nix`). We must ensure enabling `--ssh` in Tailscale does not conflict with `sshd` on port 22 or break `ssh homelab` over the local LAN (`192.168.1.180`).

### Decision

Retain `services.openssh.enable = true` in `modules/services/ssh.nix` and static `openssh.authorizedKeys.keys` in `modules/core/base.nix` and `modules/hosts/homelab.nix` without modification.

### Rationale

- When `tailscale set --ssh` is active, `tailscaled` intercepts TCP port 22 traffic arriving on `tailscale0` (`100.x.y.z` / MagicDNS hostname `homelab`) in netfilter/userspace before it reaches `sshd`, handling authentication via the Tailscale control plane.
- Connections to `192.168.1.180` (including the existing Home Manager `ssh homelab` client alias in `modules/services/ssh.nix`) arrive on the physical Ethernet interface and are handled directly by OpenSSH (`sshd`) using static `ed25519` keys.
- Keeping OpenSSH and static keys intact preserves bare-metal recovery, `nixos-anywhere` provisioning, and LAN access if the internet or Tailscale control plane is unreachable.
