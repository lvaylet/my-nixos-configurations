{lib, ...}: {
  options.flake.vars = lib.mkOption {
    type = lib.types.submodule {
      options = {
        fullName = lib.mkOption {
          type = lib.types.str;
          default = "Laurent VAYLET";
          description = "Full name of primary user";
        };
        userName = lib.mkOption {
          type = lib.types.str;
          default = "laurent";
          description = "Primary user account name";
        };
        user = lib.mkOption {
          type = lib.types.str;
          default = "laurent";
          description = "Alias for userName";
        };
        userEmail = lib.mkOption {
          type = lib.types.str;
          default = "laurent.vaylet@gmail.com";
          description = "Primary email address";
        };
        email = lib.mkOption {
          type = lib.types.str;
          default = "laurent.vaylet@gmail.com";
          description = "Alias for userEmail";
        };
        sshPublicKeyPersonal = lib.mkOption {
          type = lib.types.str;
          default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyeLKUxxWIpgR796rBG8KaTDjHyGnK3Y6Xxzq71Hedr";
          description = "Personal SSH public key";
        };
        sshPublicKeyWork = lib.mkOption {
          type = lib.types.str;
          default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8QfBocRKJAJRinUJSjiGkjdOnsYIZqqdVsq7ZFeiUg";
          description = "Work SSH public key";
        };
      };
    };
    default = {};
    description = "Global identity and shared repository variables";
  };
}
