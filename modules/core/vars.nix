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
          description = "Primary work SSH public key";
        };
        sshPublicKeysWork = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8QfBocRKJAJRinUJSjiGkjdOnsYIZqqdVsq7ZFeiUg"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+uLk0jzsfBDo7EHJoTkUkoHAAMMx9T1n4Bkd4K5dTg"
          ];
          description = "List of work SSH public keys";
        };
        tailscaleDomain = lib.mkOption {
          type = lib.types.str;
          default = "tailc5cc8b.ts.net";
          description = "Tailscale tailnet base domain name";
        };
        homelabDomain = lib.mkOption {
          type = lib.types.str;
          default = "homelab.vaylet.fr";
          description = "Base domain for homelab services";
        };
      };
    };
    default = {};
    description = "Global identity and shared repository variables";
  };
}
