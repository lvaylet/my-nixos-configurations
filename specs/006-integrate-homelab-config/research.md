# Technical Research: Homelab Configuration Integration

**Branch**: `006-integrate-homelab-config` | **Date**: 2026-10-10 | **Spec**: [spec.md](spec.md)

This document consolidates architectural decisions, rationale, best practices, and alternatives considered for integrating the impermanent homelab configuration into the dendritic NixOS codebase.

---

## 1. Upstream Flake Inputs & Module Wiring

### Decision
Add `disko` (`github:nix-community/disko`) and `preservation` (`github:nix-community/preservation`) to `flake.nix` inputs with `nixpkgs.follows = "nixpkgs"`. Wire their NixOS modules into the dendritic host evaluation pipeline via `modules/core/lib.nix` (`mkHost`) or host-level extra modules so any host can enable them declaratively.

```nix
# flake.nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  # ... existing inputs ...
  disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  preservation = {
    url = "github:nix-community/preservation";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

### Rationale
- **Hermetic Dependency Management**: Flake inputs guarantee exact cryptographic pinning in `flake.lock`.
- **Ecosystem Standard**: `disko` and `preservation` are the community standard pairing for declarative disk partitioning and impermanent NixOS installations.
- **Seamless Dendritic Integration**: Passing `disko.nixosModules.disko` and `preservation.nixosModules.default` into `mkHost` ensures all downstream dendritic modules can access and declare `disko.*` and `preservation.*` options without boilerplate imports in feature files.

### Alternatives Considered
- **Direct import of remote tarballs**: Unpinned, breaks offline evaluation, and violates Constitution Principle I.
- **Inlining modules only into `homelab.nix` extraModules**: Works, but adding support to `mkHost` standardizes disko and preservation across the repository if other machines adopt impermanence in the future.

---

## 2. Ephemeral Root & Colocated Preservation Pattern

### Decision
Adopt the ephemeral tmpfs root architecture with Btrfs subvolumes (`/persistent` and `/nix`), dividing preservation declarations into two layers:
1. **Core System & Host Preservation**: Persistent system paths (`/etc/nixos`, `/var/lib/nixos`, machine-id, SSH host keys, network connections, logs, user home `.ssh`, `.bash_history`) declared in a dedicated dendritic module `modules/core/preservation.nix`.
2. **Feature-Colocated Preservation**: Each service module in `modules/services/` conditionally declares its own persistence mappings (`preservation.preserveAt."/persistent".directories = lib.mkIf <enabled> [ ... ]`).

```nix
# Example colocated pattern in modules/services/jellyfin.nix
preservation.preserveAt."/persistent".directories = lib.mkIf config.services.jellyfin.enable [
  {
    directory = "/var/lib/jellyfin";
    user = "jellyfin";
    group = "jellyfin";
    mode = "0750";
  }
  {
    directory = "/var/cache/jellyfin";
    user = "jellyfin";
    group = "jellyfin";
    mode = "0750";
  }
];
```

### Rationale
- **Feature-Centric Cohesion**: Adheres strictly to Constitution Principle II (Dendritic Pattern). When a service is enabled on a machine, its persistence requirements are activated automatically. When disabled, no unneeded persistence rules remain active.
- **Zero Configuration Drift**: Every reboot clears `/` in RAM; only state explicitly acknowledged and declared in `/persistent` survives.
- **Comment Retention**: Retains all explanatory notes and rationale from the source repository's `preservation.nix` and service files.

### Alternatives Considered
- **Monolithic `preservation.nix`**: Centralizing all service persistence in one file re-introduces directory silos and couples unrelated services. Rejected in favor of dendritic colocation.
- **Imperative Persistent Symlinking**: Violates declarative principles and easily drifts out of sync.

---

## 3. Hardware Profile & Disko Partitioning Placement

### Decision
Colocate the hardware scan and performance tuning with the declarative Disko layout in `modules/hosts/_hardware/homelab.nix` (or an accompanying `_hardware/disko-homelab.nix` imported by the hardware profile). This keeps all machine-specific physical hardware concerns (disk IDs, kernel modules, ZRAM, microcode, Intel iGPU packages, SSD TRIM) private to the `homelab` target and excluded from top-level dendritic auto-discovery.

### Rationale
- **Physical Hardware Coupling**: Partition layouts and drive identifiers (`/dev/disk/by-id/nvme-PNY_CS2130_500GB_SSD_PNY16200007380108D83`) are physical properties of specific machines, not generic re-usable services.
- **Dendritic Hygiene**: The `_hardware/` directory is explicitly ignored by `import-tree ./modules`, preventing hardware definitions from polluting the global `flake.modules` option namespace.
- **Full Comment Preservation**: Preserves the extensive hardware documentation comments from the source repository regarding Intel N150 microcode, ZRAM vs TMPFS trade-offs, swappiness, and Btrfs mount options.

### Alternatives Considered
- **Exposing Disko as a generic feature module under `modules/services/`**: Rejected because partition sizes and disk by-id paths are host-specific and cannot be safely shared across targets like `desktop-pc`.

---

## 4. In-Place Modernization of Application Service Modules

### Decision
Update existing modules in `modules/services/` in-place to match the source repository implementations:
1. `modules/services/filebrowser.nix`: Transition from native NixOS service to Filebrowser Quantum OCI container on port 8081 with `/data:/srv` volume mount and colocated preservation.
2. `modules/services/home-automation.nix`: Transition to Home Assistant OCI container (`ghcr.io/home-assistant/home-assistant:2026.5.3`) with host networking and colocated preservation; remove unused native Mosquitto and Zigbee2MQTT components.
3. `modules/services/jellyfin.nix`: Retain native Jellyfin service, bind to `multimedia` group, open firewall ports, and add colocated preservation rules.
4. `modules/services/qbittorrent.nix`: Retain native qBittorrent service, configure shared downloads path (`/data/downloads`), systemd supplementary group `multimedia`, `UMask = "0002"`, and colocated preservation.
5. `modules/services/media.nix`: Replace stub with full multimedia shared access model (group 995, users, SetGID `2775`, systemd tmpfiles `z` rules, and preservation).
6. `modules/services/portainer.nix`: Create new module providing Portainer CE OCI container on ports 8000/9443 with Docker socket mount and colocated preservation.
7. `modules/services/nix-ld.nix`: Create new module enabling `programs.nix-ld` with documentation comments for unpatched binary and VS Code Remote SSH compatibility.

### Rationale
- **No Fragmentation**: `homelab` is the sole consumer of these application services in the repository. In-place replacement avoids dead code or confusion between "legacy" and "new" services.
- **Docker/Podman Compatibility**: Running complex, fast-moving upstream web applications (Home Assistant, Filebrowser Quantum, Portainer) in lightweight OCI containers supervised by systemd avoids Nixpkgs packaging lag and Python dependency friction.
- **Source of Truth Fidelity**: Reflects 100% of functional capabilities from the reference repository.

### Alternatives Considered
- **Keeping Native Home Assistant & Filebrowser**: Rejected per clarification session; source repository uses containers to avoid packaging issues and leverage upstream plugins.

---

## 5. Multimedia Permission Architecture & Systemd Tmpfiles `z` Rules

### Decision
Implement the shared multimedia permission architecture from `modules/multimedia.nix`:
- Group `multimedia` with fixed GID `995`.
- System users `qbittorrent` (UID `991`) and `filebrowser` (UID `992`).
- SetGID mode `2775` on `/data/downloads` and `/data/media` ensuring all newly created files inherit the `multimedia` group.
- Systemd tmpfiles mop-up rules using type `z` instead of `d`:
  ```nix
  systemd.tmpfiles.rules = [
    "z /data           0775 root        multimedia -"
    "z /data/downloads 2775 qbittorrent multimedia -"
    "z /data/media     2775 filebrowser multimedia -"
  ];
  ```

### Rationale
- **Impermanence Mount Race Prevention**: Type `d` rules attempt to create directories before or during the preservation bind-mount phase, leading to mount collisions or shadowed mounts. Type `z` rules wait until the path exists after preservation links it, then enforce ownership and permissions cleanly.
- **Seamless Multi-Service Collaboration**: qBittorrent writes downloaded media, Filebrowser organizes files, and Jellyfin streams content—all sharing group `multimedia` (664/775 access).

### Alternatives Considered
- **Running all services as root**: Extreme security hazard, rejected.
- **ACLs (Access Control Lists)**: More complex to declare and maintain across ephemeral reboots than POSIX SetGID and systemd tmpfiles.

---

## 6. Bootloader Coexistence & Identity Harmonization

### Decision
1. **Bootloader**: `modules/core/base.nix` enables Limine bootloader by default. In `homelab.nix`, override bootloader settings using `lib.mkForce` to disable Limine and enable GRUB 2 (`boot.loader.grub.enable = true`, `efiSupport = true`, `efiInstallAsRemovable = true`) matching the Disko hybrid MBR/GPT partition requirements.
2. **Root SSH Access**: Configure `services.openssh.settings.PermitRootLogin = "prohibit-password"` on `homelab` and authorize both personal and work keys for `root`.
3. **Work SSH Keys**: Update `modules/core/vars.nix` to define both work SSH keys (`sshPublicKeyWork` and `sshPublicKeyWork2`, or a list `sshPublicKeysWork`), ensuring full parity with the source repository.

### Rationale
- **Hybrid Boot Support**: Disko's MBR partition (EF02) requires GRUB 2 to support hybrid BIOS/UEFI booting reliably on mini PC hardware.
- **Remote Operations**: Prohibiting passwords while permitting SSH keys for `root` enables headless deployment and administrative recovery without exposing the server to brute-force attacks.

### Alternatives Considered
- **Changing bootloader globally in `base.nix` to GRUB**: Would alter `desktop-pc` behavior unnecessarily. Overriding per-host maintains target isolation.
