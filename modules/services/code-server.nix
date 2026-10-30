{
  flake.modules.services.code-server = {
    nixos = {
      config,
      lib,
      pkgs,
      vars,
      ...
    }: {
      services.code-server = {
        enable = true;
        user = vars.userName;
        group = "users";
        auth = "none";
        host = "127.0.0.1";
        port = 4444;
        disableTelemetry = true;
        disableUpdateCheck = true;
        extraArguments = [
          "/home/${vars.userName}"
        ];
        extraPackages = with pkgs; [
          bash
          coreutils
          direnv
          git
          just
          nh
          nix
          nixos-rebuild
          ripgrep
        ];
      };

      services.caddy = lib.mkIf config.services.caddy.enable {
        virtualHosts."code.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:4444
          '';
        };
      };

      systemd.services.code-server = {
        after = [
          "network.target"
          "local-fs.target"
        ];
        serviceConfig = {
          RestartSec = 5;
        };
      };

      preservation.preserveAt."/persistent".users.${vars.userName}.directories = lib.mkIf config.services.caddy.enable [
        ".local/share/code-server"
        ".config/code-server"
      ];
    };
  };
}
