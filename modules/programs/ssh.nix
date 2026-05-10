_: {
  flake.homeModules.ssh = _: {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "rpi3" = {
          hostname = "192.168.1.68";
          user = "pi";
          identityFile = "~/.ssh/id_ed25519";
          checkHostIP = false;
        };
        "homelab-vm" = {
          hostname = "192.168.1.194";
          user = "core";
          identityFile = "~/.ssh/id_ed25519";
          checkHostIP = false;
        };
      };
    };
  };
}
