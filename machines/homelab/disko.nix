{
  # Don't boot before `/nix` is mounted.
  fileSystems."/nix".neededForBoot = true;

  # Set up an ephemeral root.
  disko.devices.nodev = {
    "/" = {
      fsType = "tmpfs"; # All the contents of our root directory will be stored in RAM and thus wiped out on every reboot.
      mountOptions = [
        "size=25%" # Define the maximum amount of RAM our root directory will be allowed to take.
        "mode=755" # Make it so only `root` can write there.
      ];
    };
  };

  # Set up persistence of files and directories on main device.
  # Use hybrid layout to maximize compatibility with both BIOS and UEFI machines.
  # Reference: https://github.com/nix-community/disko/blob/master/example/hybrid.nix
  disko.devices.disk.main = {
    # CHANGE THIS TO YOUR DEVICE, as reported by `lsblk`.
    # Usually `/dev/sda` or `/dev/nvme0n1`.
    # Use unambiguous ID, e.g. `/dev/disk/by-id/<ID>`, with multiple disks are present.
    device = "/dev/disk/by-id/nvme-PNY_CS2130_500GB_SSD_PNY16200007380108D83";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        MBR = {
          type = "EF02"; # For GRUB (GRand Unified Bootloader) MBR.
          size = "1M";
          priority = 1; # Must be the first partition.
        };
        ESP = {
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "umask=0077"
            ];
          };
        };
        swap = {
          size = "4G"; # Rule of thumb: match your RAM here.
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [
              "-f"
            ];
            subvolumes = {
              "/persistent" = {
                # Files and directories to persist
                mountOptions = [
                  "subvol=persistent"
                  "noatime" # Prevents Linux from rewriting to the SSD every time a file is simply *read*.
                  "compress=zstd" # Drastically reduces the size of written data (extending the SSD's lifespan) and speeds up read/write operations because the N150 processor compresses data faster than the SSD can write it.
                  "ssd"
                  "discard=async" # On modern SSDs, this enables asynchronous TRIM discard operations in the background rather than synchronously blocking IO, leading to better responsiveness and prolonged drive longevity.
                ];
                mountpoint = "/persistent";
              };

              "/nix" = {
                # Nix Store
                mountOptions = [
                  "subvol=nix"
                  "noatime" # Prevents Linux from rewriting to the SSD every time a file is simply *read*.
                  "compress=zstd" # Drastically reduces the size of written data (extending the SSD's lifespan) and speeds up read/write operations because the N150 processor compresses data faster than the SSD can write it.
                  "ssd"
                  "discard=async" # On modern SSDs, this enables asynchronous TRIM discard operations in the background rather than synchronously blocking IO, leading to better responsiveness and prolonged drive longevity.
                ];
                mountpoint = "/nix";
              };
            };
          };
        };
      };
    };
  };
}
