{lib, ...}: {
  options.vars = {
    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Laurent VAYLET";
      description = "Full name of the primary user";
    };
    userName = lib.mkOption {
      type = lib.types.str;
      default = "laurent";
      description = "Username of the primary user";
    };
    userEmail = lib.mkOption {
      type = lib.types.str;
      default = "laurent.vaylet@gmail.com";
      description = "Email of the primary user";
    };
    sshPublicKeysPersonal = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyeLKUxxWIpgR796rBG8KaTDjHyGnK3Y6Xxzq71Hedr"
      ];
      description = "List of personal SSH public keys";
    };
    sshPublicKeysWork = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8QfBocRKJAJRinUJSjiGkjdOnsYIZqqdVsq7ZFeiUg"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+uLk0jzsfBDo7EHJoTkUkoHAAMMx9T1n4Bkd4K5dTg"
      ];
      description = "List of work SSH public keys";
    };
  };
}
