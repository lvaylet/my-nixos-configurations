# Research: Automated Container Image Updates via Podman and Systemd Timer

**Feature**: `037-podman-auto-update`
**Date**: 2026-11-01

## 1. Automated Container Update Mechanism: Podman Auto-Update vs. Alternatives

### Decision

Use Podman's built-in native `podman auto-update` capability by applying the container label `--label=io.containers.autoupdate=registry` to all declarative OCI containers.

### Rationale

- **Native Integration with Systemd**: When containers are managed by systemd (as configured by NixOS's `virtualisation.oci-containers` backend), `podman auto-update` does not simply restart processes in an untracked manner; it communicates directly with systemd (`systemctl restart podman-<container>.service`). This ensures that pre-start hooks, environment setups, and systemd dependency chains remain fully intact.
- **Digest-Based Registry Polling**: The `registry` mode compares the local image's manifest digest with the remote registry's manifest digest. It only downloads layers and restarts services if the digest actually changed, avoiding unnecessary restarts and bandwidth consumption.
- **Rollback Capability**: Podman records image history and can rollback failed updates automatically if the updated container fails its health checks (if configured).
- **Comprehensive Coverage**: It works uniformly for Portainer CE (`portainer-ce:lts`) as well as all service containers (`homeassistant`, `filebrowser`, `n8n`, `n8n-runners`, `waha`).

### Alternatives Considered

- **Watchtower**:
  - *Pros*: Popular in Docker ecosystem, containerized.
  - *Cons*: Third-party daemon requiring root socket access; lacks deep integration with systemd-managed Podman services; adds unnecessary memory and container overhead when Podman already has this functionality built-in.
- **Manual Image Tag Bumping in Nix / Flake Pins**:
  - *Pros*: Completely declarative git tracking of digests.
  - *Cons*: Requires frequent manual commit toil for minor patches and upstream container releases; does not meet the user's explicit requirement for automated daily updates.
- **`--pull=always` on container execution**:
  - *Pros*: Pulls latest image on startup.
  - *Cons*: Only triggers when the service starts or restarts; does not automatically trigger updates on running containers without external restart mechanisms; slows down normal service startup times.

---

## 2. Scheduling: Daily Systemd Timer in NixOS

### Decision

Declare a native NixOS `systemd.timers.podman-auto-update` and `systemd.services.podman-auto-update` in `modules/services/podman.nix` with `OnCalendar = "daily"`, `Persistent = true`, and `RandomizedDelaySec = "900"`.

### Rationale

- **Deterministic Scheduling**: Systemd timers are the standard scheduling mechanism in NixOS, integrating with journal logging (`journalctl -u podman-auto-update`).
- **Catch-Up Execution (`Persistent = true`)**: If `homelab` is powered down or in maintenance during the scheduled time, systemd executes the update job shortly after the next boot.
- **Jitter Protection (`RandomizedDelaySec = "900"`)**: Spreads execution within a 15-minute window to avoid thundering-herd API spikes against public registries.
- **Automatic Image Pruning**: Adding `ExecStartPost = "${config.virtualisation.podman.package}/bin/podman image prune -f"` cleans up dangling layers left behind after an image replacement, preventing storage accumulation on `/persistent/var/lib/containers`.

### Alternatives Considered

- **Cron Job**:
  - *Pros*: Simple syntax.
  - *Cons*: Outdated in NixOS; lacks systemd dependency awareness, cgroup management, and persistent missed-job catching.
- **Upstream Unit Enablement without Explicit Service Configuration**:
  - *Pros*: The upstream podman package ships `podman-auto-update.timer`.
  - *Cons*: In NixOS, activating `systemd.timers.podman-auto-update.wantedBy = [ "timers.target" ]` without declaring `timerConfig` and `serviceConfig` inside NixOS results in unconfigured units. Explicit declaration in `modules/services/podman.nix` guarantees hermetic paths (`${config.virtualisation.podman.package}/bin/podman`) and full reproducibility.

---

## 3. Scope of Containers to Auto-Update

### Decision

Apply `--label=io.containers.autoupdate=registry` across all declarative OCI container modules:

1. `modules/services/portainer.nix` (`portainer` -> `docker.io/portainer/portainer-ce:lts`)
2. `modules/services/home-automation.nix` (`homeassistant` -> `ghcr.io/home-assistant/home-assistant:2026.10`)
3. `modules/services/filebrowser.nix` (`filebrowser` -> `ghcr.io/gtsteffaniak/filebrowser:2-stable`)
4. `modules/services/waha.nix` (`waha` -> `docker.io/devlikeapro/waha:latest`)
5. `modules/services/n8n.nix` (`n8n` -> `docker.io/n8nio/n8n:latest` and `n8n-runners` -> `docker.io/n8nio/runners:latest`)

### Rationale

- Each container is declared in its own dendritic service module under `modules/services/`.
- Adding the label to `extraOptions` within each module maintains strict dendritic modularity: each service declares its own container options without coupling or cross-module leakage.

### Alternatives Considered

- **Centralizing label injection in `podman.nix`**:
  - *Pros*: Single point of configuration.
  - *Cons*: Violates the dendritic principle by having `podman.nix` mutate options of services declared in separate domain modules; less visible when inspecting individual service files.

---

## 4. Operational Recipe: `just update-containers`

### Decision

Add a recipe `update-containers target="homelab"` under group `[group('container-management')]` in `justfile`.

### Rationale

- Allows operators to trigger `podman auto-update` on demand without waiting for the daily timer.
- Supports both local execution on `homelab` (using `sudo podman auto-update`) and remote execution from a workstation (using `ssh -t "${TARGET}" "sudo podman auto-update"`).
- Aligns with the recipe ergonomics standardized in `specs/028-harmonize-justfile-recipes`.

### Alternatives Considered

- **Embedding directly into `just up`**:
  - *Pros*: Single command.
  - *Cons*: `just up` is for flake management (`nix flake update` on dev workstation). Coupling local lockfile updates with live remote container upgrades breaks single-responsibility and causes unintended production restarts when simply wanting to update flake inputs. Having a dedicated recipe `just update-containers` provides explicit, safe control.
