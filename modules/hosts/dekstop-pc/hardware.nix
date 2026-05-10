_: {
  flake.nixosModules.desktopPcHardware = {
    config,
    lib,
    modulesPath,
    ...
  }: {
    # Contents of `hardware-configuration.nix`:
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot = {
      initrd = {
        availableKernelModules = [
          "xhci_pci"
          "ahci"
          "nvme"
          "usbhid"
          "usb_storage"
          "sd_mod"
        ];
        kernelModules = [];
      };
      kernelModules = ["kvm-amd"];
      extraModulePackages = [];
    };

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/6e08bbca-255c-465b-bada-c2a2ff9983a3";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/8D65-002E";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    swapDevices = [];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
