{
  flake.modules.services.bluetooth = {
    nixos = _: {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Experimental = true;
          };
          Policy = {
            AutoEnable = true;
          };
        };
      };

      services.blueman.enable = true;
    };
  };
}
