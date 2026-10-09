{
  flake.modules.services.virtualization = {
    nixos = {
      # Enable VMware Workstation.
      virtualisation.vmware.host.enable = true;
      services.xserver.videoDrivers = [
        "vmware" # Enable VMware video driver for better performance.
      ];
    };
  };
}
