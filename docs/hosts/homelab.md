# Homelab Server Provisioning & Architecture (`homelab`)

[← Back to README](../../README.md)

The `homelab` server is a headless, impermanent NixOS machine hosting self-hosted services, workflow automations, and media storage on an Alder Lake-N mini PC (e.g. Beelink S13).

- **Ephemeral Root (`tmpfs`)**: The root filesystem (`/`) is mounted as a temporary RAM disk wiped on every reboot. Only directories explicitly declared in `modules/core/preservation.nix` survive reboots under `/persistent`.
- **Btrfs Subvolumes**: Backed by `disko` with dedicated subvolumes for persistent state (`/persistent`) and the Nix store (`/nix`).
- **Coordinated Storage (`/data`)**: Shared storage pool for media streaming, torrent downloads, and automated workflows.

---

## Initial Provisioning (`nixos-anywhere` & Custom ISO)

To perform an automated, headless bootstrap of the impermanent `homelab` server from scratch:

### 1. Build the Custom Installer ISO

The custom ISO (`modules/core/iso.nix`) embeds authorized SSH public keys for both `nixos` and `root` users, enabling direct passwordless SSH access:

```sh
just build-iso
```

The bootable ISO image is generated under `result/iso/nixos-*-x86_64-linux.iso`. Flash it to a USB drive (e.g. using `dd`, `rpi-imager`, or Ventoy).

### 2. Boot the Target Host

- Insert the USB drive into the homelab hardware and boot from it.
- Note the assigned IPv4 address displayed in the MOTD banner or check it with `ip addr`.

### 3. Install Remotely with `nixos-anywhere`

From an authorized workstation, launch the remote deployment:

**Bash**:

```bash
export TARGET_IP=<target-ip>

# Using the unified just recipe (defaults to configuration="homelab"):
just install "${TARGET_IP}"

# Or invoking nixos-anywhere directly:
nix run github:nix-community/nixos-anywhere -- --flake .#homelab "root@${TARGET_IP}"
```

**Fish**:

```fish
set -gx TARGET_IP <target-ip>

# Using the unified just recipe (defaults to configuration="homelab"):
just install "$TARGET_IP"

# Or invoking nixos-anywhere directly:
nix run github:nix-community/nixos-anywhere -- --flake .#homelab "root@$TARGET_IP"
```

`nixos-anywhere` automatically:

- Partitions and formats the SSD via `disko` (creating the hybrid MBR/ESP layout, swap, and Btrfs subvolumes `/persistent` and `/nix` with ephemeral `tmpfs` root).
- Mounts the target filesystem hierarchy and sets up preservation links.
- Installs the complete NixOS system closure with GRUB 2.
- Reboots into your fresh impermanent system.

---

## Post-Installation Verification & Routine Maintenance

Once rebooted, connect over SSH as `laurent` (default interactive shell: **Fish**) or `root` (default shell: **Bash**):

**Bash**:

```bash
ssh "laurent@${TARGET_IP}"
```

**Fish**:

```fish
ssh "laurent@$TARGET_IP"
```

For routine updates that do not require repartitioning the storage device, you can deploy either **locally from `homelab` itself** (in an SSH session or via OpenCode, where `just` automatically detects the `homelab` hostname) or **remotely from another workstation**:

**Bash**:

```bash
# Directly on homelab (auto-detects local hostname 'homelab'):
just test
just switch

# Or remotely from another workstation (using SSH alias 'homelab' or custom TARGET_IP):
just switch homelab
just switch configuration="homelab" target="${TARGET_IP}"

# Or test the configuration remotely without setting a new boot profile:
just test homelab
just test configuration="homelab" target="${TARGET_IP}"
```

**Fish**:

```fish
# Directly on homelab (auto-detects local hostname 'homelab'):
just test
just switch

# Or remotely from another workstation (using SSH alias 'homelab' or custom TARGET_IP):
just switch homelab
just switch configuration="homelab" target="$TARGET_IP"

# Or test the configuration remotely without setting a new boot profile:
just test homelab
just test configuration="homelab" target="$TARGET_IP"
```

---

[← Back to README](../../README.md)
