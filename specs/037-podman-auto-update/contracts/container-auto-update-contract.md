# Contract: Container Auto-Update and Timer Configuration

**Feature**: `037-podman-auto-update`
**Date**: 2026-11-01

## 1. Systemd Configuration Contract (`modules/services/podman.nix`)

The `modules/services/podman.nix` module MUST evaluate to produce the following systemd units when `config.virtualisation.podman.enable` is `true`:

### `systemd.timers.podman-auto-update`

```nix
systemd.timers.podman-auto-update = {
  description = "Podman auto-update timer";
  documentation = [ "man:podman-auto-update(1)" ];
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
    RandomizedDelaySec = "900";
  };
};
```

**Evaluation Invariant**:

- `nixosConfigurations.homelab.config.systemd.timers.podman-auto-update.timerConfig.OnCalendar` == `"daily"`
- `nixosConfigurations.homelab.config.systemd.timers.podman-auto-update.timerConfig.Persistent` == `true`
- `nixosConfigurations.homelab.config.systemd.timers.podman-auto-update.wantedBy` contains `"timers.target"`

### `systemd.services.podman-auto-update`

```nix
systemd.services.podman-auto-update = {
  description = "Podman auto-update service";
  documentation = [ "man:podman-auto-update(1)" ];
  wants = [ "network-online.target" ];
  after = [ "network-online.target" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${config.virtualisation.podman.package}/bin/podman auto-update";
    ExecStartPost = "${config.virtualisation.podman.package}/bin/podman image prune -f";
  };
};
```

**Evaluation Invariant**:

- `nixosConfigurations.homelab.config.systemd.services.podman-auto-update.serviceConfig.Type` == `"oneshot"`
- `nixosConfigurations.homelab.config.systemd.services.podman-auto-update.serviceConfig.ExecStart` contains `"podman auto-update"`

---

## 2. Container Labels Invariant Contract

For every OCI container declared in the repository, the list of strings in `extraOptions` MUST contain `"--label=io.containers.autoupdate=registry"`:

| Container | Module Path | Option Path | Expected Label Presence |
|---|---|---|---|
| `portainer` | `modules/services/portainer.nix` | `virtualisation.oci-containers.containers.portainer.extraOptions` | Contains `"--label=io.containers.autoupdate=registry"` |
| `homeassistant` | `modules/services/home-automation.nix` | `virtualisation.oci-containers.containers.homeassistant.extraOptions` | Contains `"--label=io.containers.autoupdate=registry"` |
| `filebrowser` | `modules/services/filebrowser.nix` | `virtualisation.oci-containers.containers.filebrowser.extraOptions` | Contains `"--label=io.containers.autoupdate=registry"` |
| `waha` | `modules/services/waha.nix` | `virtualisation.oci-containers.containers.waha.extraOptions` | Contains `"--label=io.containers.autoupdate=registry"` |
| `n8n` | `modules/services/n8n.nix` | `virtualisation.oci-containers.containers.n8n.extraOptions` | Contains `"--label=io.containers.autoupdate=registry"` |
| `n8n-runners` | `modules/services/n8n.nix` | `virtualisation.oci-containers.containers.n8n-runners.extraOptions` | Contains `"--label=io.containers.autoupdate=registry"` |

---

## 3. Justfile CLI Contract (`justfile`)

The `justfile` MUST declare the following recipe under `[group('container-management')]`:

```justfile
# update container images via Podman auto-update (local or remote over SSH)
[group('container-management')]
update-containers target="homelab":
  #!/usr/bin/env bash
  set -euo pipefail
  TARGET="{{target}}"
  CURRENT_HOST="$(hostname -s 2>/dev/null || uname -n)"
  if [ "${TARGET}" = "${CURRENT_HOST}" ] || [ "${TARGET}" = "localhost" ]; then
    echo "==> Running podman auto-update locally..."
    sudo podman auto-update
  else
    echo "==> Running podman auto-update on ${TARGET} over SSH..."
    ssh -t "${TARGET}" "sudo podman auto-update"
  fi
```

**CLI Invariant**:

- Running `just --list` displays `update-containers target="homelab"` under `[container-management]`.
- Running `just update-containers` invokes `podman auto-update` locally if on `homelab`, or over SSH if executed remotely.
