{
  flake.modules.core = {
    limine = {
      nixos = {pkgs, ...}: {
        boot.loader = {
          efi.canTouchEfiVariables = true;

          limine = {
            # A modern, advanced, portable, multi-protocol bootloader and boot manager.
            # For additional Limine module configuration options, check:
            # https://search.nixos.org/options?channel=unstable&show=boot.loader.limine
            enable = true;

            maxGenerations = 5; # Maximum number of latest generations in the boot menu.

            # Prepend extra settings to `limine.conf`.
            # The config format can be found here:
            # https://github.com/limine-bootloader/limine/blob/trunk/CONFIG.md
            extraConfig = ''
              remember_last_entry: yes
            '';

            # Append extra entries to the end of `limine.conf`.
            #
            # For Windows 11, follow these instructions to copy the Windows bootloader to Limine's ESP
            # and avoid using `uuid()`: https://github.com/basecamp/omarchy/discussions/1604
            #
            # Reference: https://wiki.archlinux.org/title/Limine#Windows_entry_(UEFI)
            extraEntries = ''
              /Windows 11
                protocol: efi
                path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
            '';

            style.wallpapers = with pkgs.nixos-artwork.wallpapers; [
              # Check available wallpapers here:
              # - https://github.com/NixOS/nixos-artwork/tree/master/wallpapers
              # - https://mynixos.com/packages/nixos-artwork.wallpapers
              # and make sure to append `.gnomeFilePath` below:
              mosaic-blue.gnomeFilePath
              nineish-dark-gray.gnomeFilePath
              simple-blue.gnomeFilePath
              simple-dark-gray-bootloader.gnomeFilePath
              waterfall.gnomeFilePath
            ];
          };
        };
      };
    };

    grub = {
      nixos = {
        # Use the GRUB 2 boot loader.
        boot.loader = {
          efi.canTouchEfiVariables = false;
          grub = {
            enable = true;
            efiSupport = true;
            efiInstallAsRemovable = true;
            # devices = [ ]; # no need to set devices, disko will add all devices that have a EF02 partition to the list already
            # device = "/dev/sda"; # or "nodev" for efi only
          };
          # boot.loader.efi.efiSysMountPoint = "/boot/efi";
        };
      };
    };
  };
}
