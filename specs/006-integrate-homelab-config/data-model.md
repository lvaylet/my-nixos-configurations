# Data Model: Homelab Configuration Integration

**Branch**: `006-integrate-homelab-config` | **Date**: 2026-10-10 | **Spec**: [spec.md](spec.md)

This document formalizes the entities, data structures, attribute specifications, relationships, and validation constraints required for the homelab configuration integration.

---

## 1. Entities & Data Schemas

### Entity 1: Homelab Host Composition (`modules/hosts/homelab.nix`)
Represents the target host declaration that assembles hardware and enabled capabilities.

| Field | Type | Description | Constraints |
|---|---|---|---|
| `system` | String | Target CPU architecture and platform | Must be `"x86_64-linux"` |
| `hardware` | Path | Hardware and partitioning configuration | Path to `./_hardware/homelab.nix` |
| `features` | List of Modules | Dendritic modules enabled on this machine | Selected from `config.flake.modules` |
| `extraModules` | List of Modules | Host-specific overrides | Hostname, GRUB override, root SSH keys |

#### Relationships
- **References**: `modules/hosts/_hardware/homelab.nix` for physical hardware and Disko layout.
- **Composes**: Feature modules from `modules/core/` and `modules/services/`.

---

### Entity 2: Hardware & Storage Profile (`modules/hosts/_hardware/homelab.nix`)
Encapsulates hardware detection, Alder Lake-N tuning, and declarative Disko partitioning.

| Category | Option / Attribute | Value / Schema | Purpose |
|---|---|---|---|
| **Kernel & Boot** | `boot.initrd.availableKernelModules` | `["xhci_pci", "nvme", "usb_storage", "sd_mod"]` | Storage controller drivers |
| | `boot.kernelModules` | `["kvm-intel"]` | Hardware virtualization |
| | `boot.kernel.sysctl."vm.swappiness"` | `100` | Aggressive swap to ZRAM |
| **CPU & Power** | `hardware.cpu.intel.updateMicrocode` | `true` | Microcode stability patch |
| | `powerManagement.cpuFreqGovernor` | `"schedutil"` | Efficiency / responsiveness |
| **Memory** | `zramSwap.enable` | `true` | In-RAM compressed swap |
| | `zramSwap.algorithm` | `"zstd"` | Compression algorithm |
| | `zramSwap.memoryPercent` | `50` | Max 50% physical RAM (8 GB) |
| **Graphics** | `hardware.graphics.enable` | `true` | Intel UHD Graphics |
| | `hardware.graphics.extraPackages` | `[ intel-media-driver, intel-compute-runtime ]` | QuickSync transcoding |
| **Maintenance** | `services.fstrim.enable` | `true` (interval `"weekly"`) | NVMe block wear management |
| **Disko: Ephemeral** | `disko.devices.nodev."/".fsType` | `"tmpfs"` | RAM-backed root |
| | `disko.devices.nodev."/".mountOptions` | `["size=25%", "mode=755"]` | Max 4 GB RAM, root only |
| **Disko: Physical** | `disko.devices.disk.main.device` | `/dev/disk/by-id/nvme-PNY_CS2130_...` | Physical SSD identifier |
| | `MBR` partition | Type `EF02`, size `1M`, priority 1 | GRUB hybrid MBR |
| | `ESP` partition | Type `EF00`, size `1G`, format `vfat`, mount `/boot` | UEFI System Partition |
| | `swap` partition | Size `4G`, `resumeDevice = true` | Dedicated disk swap |
| | `root` partition | Type `btrfs`, subvolumes `/persistent` and `/nix` | `noatime, compress=zstd, ssd, discard=async` |

---

### Entity 3: State Preservation Manifest
Defines persistent paths retained across reboots via `preservation`.

| Scope | Path | Type | Owner:Group | Mode | inInitrd |
|---|---|---|---|---|---|
| **System Identity** | `/etc/machine-id` | File | `root:root` | Default | `true` |
| | `/etc/ssh/ssh_host_ed25519_key` | File | `root:root` | `0600` | `false` |
| | `/etc/ssh/ssh_host_rsa_key` | File | `root:root` | `0600` | `false` |
| | `/etc/ssh/ssh_host_ed25519_key.pub`| File | `root:root` | `0644` | `false` |
| | `/etc/ssh/ssh_host_rsa_key.pub` | File | `root:root` | `0644` | `false` |
| **System State** | `/etc/nixos` | Directory | `root:root` | Default | `false` |
| | `/var/lib/nixos` | Directory | `root:root` | Default | `true` |
| | `/var/lib/systemd/timers` | Directory | `root:root` | Default | `false` |
| | `/var/log` | Directory | `root:root` | Default | `false` |
| | `/var/lib/bluetooth` | Directory | `root:root` | Default | `false` |
| | `/etc/NetworkManager/system-connections` | Directory | `root:root` | Default | `false` |
| | `/tmp` | Directory | `root:root` | Default | `false` |
| **User State** | `/home/<user>/.ssh` | Directory | `<user>:users` | Default | `false` |
| | `/home/<user>/.bash_history`| File | `<user>:users` | Default | `false` |
| **Containers** | `/var/tmp` | Directory | `root:root` | Default | `false` |
| | `/var/lib/containers` | Directory | `root:root` | Default | `false` |
| **Filebrowser** | `/var/lib/filebrowser` | Directory | `filebrowser:filebrowser` | `0700` | `false` |
| | `/var/cache/filebrowser` | Directory | `filebrowser:filebrowser` | `0700` | `false` |
| **Home Assistant** | `/var/lib/home-assistant` | Directory | `root:root` | `0750` | `false` |
| **Portainer** | `/var/lib/portainer` | Directory | `root:root` | `0755` | `false` |
| **Jellyfin** | `/var/lib/jellyfin` | Directory | `jellyfin:jellyfin` | `0750` | `false` |
| | `/var/cache/jellyfin` | Directory | `jellyfin:jellyfin` | `0750` | `false` |
| **qBittorrent** | `/var/lib/qBittorrent` | Directory | `qbittorrent:qbittorrent` | `0750` | `false` |
| **Shared Data** | `/data/downloads` | Directory | `qbittorrent:multimedia` | `2775` | `false` |
| | `/data/media` | Directory | `filebrowser:multimedia` | `2775` | `false` |

---

### Entity 4: Multimedia Access Domain
Coordinated security and permission model for multimedia applications.

```text
               +----------------------------------+
               |     multimedia Group (GID 995)   |
               +-----------------+----------------+
                                 |
         +-----------------------+-----------------------+
         |                       |                       |
+--------v-------+      +--------v-------+      +--------v-------+
|  qbittorrent   |      |  filebrowser   |      |    jellyfin    |
| (UID 991, 664) |      | (UID 992, 664) |      | (system user)  |
+--------+-------+      +--------+-------+      +--------+-------+
         |                       |                       |
         v                       v                       v
 /data/downloads (2775)     /data/media (2775)       Read / Stream
 (qbittorrent:multimedia) (filebrowser:multimedia)      All Media
```

#### Invariants & Constraints
- GID for `multimedia` MUST be fixed at `995`.
- UID for `qbittorrent` MUST be fixed at `991`.
- UID for `filebrowser` MUST be fixed at `992`.
- `systemd.tmpfiles.rules` MUST use `z` type rules to prevent race conditions during preservation mount setup.

---

### Entity 5: Application Services Specification

| Service | Architecture | Image / Package | Network / Ports | Volumes | Capabilities |
|---|---|---|---|---|---|
| **Podman** | Engine | System package | N/A | `/var/lib/containers`, `/var/tmp` | Rootful, DNS enabled, dockerCompat |
| **Filebrowser** | Container | `ghcr.io/gtsteffaniak/filebrowser:latest` | `8081:80` (TCP) | `/data:/srv` | `CAP_NET_BIND_SERVICE`, PUID 992, PGID 995 |
| **Home Assistant** | Container | `ghcr.io/home-assistant/home-assistant:2026.5.3` | Host networking (`8123` TCP) | `/var/lib/home-assistant:/config`, `/run/dbus:/run/dbus:ro` | `--network=host` |
| **Portainer** | Container | `docker.io/portainer/portainer-ce:lts` | `8000:8000`, `9443:9443` (TCP) | `/var/run/podman/podman.sock:/var/run/docker.sock`, `/var/lib/portainer:/data` | `--privileged` |
| **Jellyfin** | Native | `pkgs.jellyfin` | `8096` (TCP), `openFirewall = true` | `/var/lib/jellyfin`, `/var/cache/jellyfin` | Member of `multimedia` group |
| **qBittorrent** | Native | `pkgs.qbittorrent-nox` | WebUI + torrent ports open | `/var/lib/qBittorrent`, `/data/downloads` | Supplementary group `multimedia`, `UMask = 0002` |
| **nix-ld** | Native | `programs.nix-ld` | N/A | N/A | Dynamic binary ELF loader |

---

### Entity 6: Global Identity Options (`modules/core/vars.nix`)

| Option Name | Type | Value | Purpose |
|---|---|---|---|
| `fullName` | String | `"Laurent VAYLET"` | Human-readable user name |
| `userName` | String | `"laurent"` | Primary POSIX account name |
| `userEmail` | String | `"laurent.vaylet@gmail.com"` | Primary Git and user email |
| `sshPublicKeyPersonal` | String | `"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyeLKUxxWIpgR796rBG8KaTDjHyGnK3Y6Xxzq71Hedr"` | Personal workstation key |
| `sshPublicKeysWork` | List of Strings | `["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8QfBocRKJAJRinUJSjiGkjdOnsYIZqqdVsq7ZFeiUg", "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+uLk0jzsfBDo7EHJoTkUkoHAAMMx9T1n4Bkd4K5dTg"]` | Both work workstation keys |
