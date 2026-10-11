# Interface Contract: Disko Partitioning & State Preservation

**Branch**: `006-integrate-homelab-config` | **Date**: 2026-10-10 | **Spec**: [spec.md](../spec.md)

This contract defines the structural schema and invariants for declaring disk partitioning with `disko` and state preservation with `preservation`.

---

## 1. Disko Storage Schema

Partitioning specifications for the homelab host MUST conform to the hybrid layout:

```nix
{
  fileSystems."/nix".neededForBoot = true;

  disko.devices = {
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [ "size=25%" "mode=755" ];
    };

    disk.main = {
      device = <string: disk path by id>;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          MBR = {
            type = "EF02";
            size = "1M";
            priority = 1;
          };
          ESP = {
            type = "EF00";
            size = "1G";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          swap = {
            size = "4G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/persistent" = {
                  mountOptions = [ "subvol=persistent" "noatime" "compress=zstd" "ssd" "discard=async" ];
                  mountpoint = "/persistent";
                };
                "/nix" = {
                  mountOptions = [ "subvol=nix" "noatime" "compress=zstd" "ssd" "discard=async" ];
                  mountpoint = "/nix";
                };
              };
            };
          };
        };
      };
    };
  };
}
```

---

## 2. Preservation Declaration Schema

Preservation declarations MUST be declared under `preservation.preserveAt."/persistent"`:

```nix
{
  preservation.preserveAt."/persistent" = {
    # System directories
    directories = [
      "/path/to/dir"
      {
        directory = "/path/to/dir";
        inInitrd = true;     # If needed during early boot
        user = "username";    # Optional ownership
        group = "groupname";  # Optional group
        mode = "0750";        # Optional permissions
      }
    ];

    # System files
    files = [
      "/path/to/file"
      {
        file = "/path/to/file";
        mode = "0600";
        configureParent = true; # Ensures parent directory exists with safe permissions
      }
    ];

    # User-level state
    users.<username> = {
      directories = [ "relative/to/home" ];
      files = [ "relative/to/home/file" ];
    };
  };
}
```

---

## 3. Dendritic Colocation Invariant

Any feature module under `modules/services/` that manages stateful data MUST colocate its preservation declarations directly within the module file using `lib.mkIf <condition>`:

```nix
preservation.preserveAt."/persistent".directories = lib.mkIf <is-enabled> [
  # paths to persist
];
```
Feature modules MUST NOT hardcode persistent mappings if the service itself is disabled on the target machine.
