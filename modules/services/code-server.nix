{
  flake.modules.services.code-server = {
    nixos = {
      config,
      lib,
      outputs,
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
        package = pkgs.vscode-with-extensions.override {
          vscode = pkgs.code-server;
          vscodeExtensions = outputs.lib.vscode.extensions pkgs;
        };
        extraPackages = with pkgs; [
          alejandra
          bash
          coreutils
          direnv
          git
          just
          nh
          nix
          nixd
          nixos-rebuild
          ripgrep
        ];
      };

      systemd.tmpfiles.rules = [
        "d /home/${vars.userName}/.local/share/code-server/User 0755 ${vars.userName} users -"
        "L+ /home/${vars.userName}/.local/share/code-server/User/settings.json - - - - ${(pkgs.formats.json {}).generate "settings.json" outputs.lib.vscode.settings}"
        "d /home/${vars.userName}/.config/code-server 0755 ${vars.userName} users -"
        "L+ /home/${vars.userName}/.config/code-server/settings.json - - - - ${(pkgs.formats.json {}).generate "settings.json" outputs.lib.vscode.settings}"
      ];

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
