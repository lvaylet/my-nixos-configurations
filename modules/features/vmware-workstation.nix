_: {
  flake.nixosModules.vmwareWorkstation = {
    # Enable VMware Workstation.
    virtualisationvmware.host.enable = true;
    services.xserver.videoDrivers = [
      "vmware" # Enable VMware video driver for better performance.
    ];
  };
}
