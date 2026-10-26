{
  flake.modules.services.opencode = {
    nixos = {
      config,
      inputs,
      lib,
      pkgs,
      vars,
      ...
    }: let
      opencodePackage = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
      opencodeConfigFile = pkgs.writeText "opencode.json" (builtins.toJSON {
        theme = "nord";
      });
    in {
      # Shell package availability for homelab and NixOS hosts
      environment.systemPackages = [
        opencodePackage
      ];

      # Declarative user configuration symlink for interactive shell sessions
      systemd.tmpfiles.rules = [
        "d /home/${vars.userName}/.config 0755 ${vars.userName} users -"
        "d /home/${vars.userName}/.config/opencode 0755 ${vars.userName} users -"
        "L+ /home/${vars.userName}/.config/opencode/opencode.json - - - - ${opencodeConfigFile}"
      ];

      # Headless background server daemon on homelab running under primary user
      systemd.services.opencode-web = lib.mkIf config.services.caddy.enable {
        description = "OpenCode v2 Web Service";
        wantedBy = ["multi-user.target"];
        after = [
          "network.target"
          "local-fs.target"
        ];
        environment = {
          HOME = "/home/${vars.userName}";
        };
        path =
          [
            "/run/wrappers"
            "/run/current-system/sw"
          ]
          ++ (with pkgs; [
            bash
            coreutils
            direnv
            gh
            git
            just
            nh
            nix
            nixos-rebuild
            openssh
            ripgrep
          ]);
        serviceConfig = {
          ExecStart = "${opencodePackage}/bin/opencode serve --hostname 127.0.0.1 --port 4096";
          WorkingDirectory = "/home/${vars.userName}";
          User = vars.userName;
          Group = "users";
          Restart = "always";
          RestartSec = 5;
          EnvironmentFile = "-/var/lib/opencode/opencode.env";
          StateDirectory = "opencode";
          StateDirectoryMode = "0750";
          PrivateTmp = true;
        };
        preStart = ''
          ${pkgs.coreutils}/bin/install -d -m 0750 -o ${vars.userName} -g users /var/lib/opencode
          if [ ! -s /var/lib/opencode/opencode.env ]; then
            umask 0077
            printf 'OPENCODE_SERVER_PASSWORD=%s\n' "$(${pkgs.coreutils}/bin/head -c 32 /dev/urandom | ${pkgs.coreutils}/bin/od -An -tx1 | ${pkgs.coreutils}/bin/tr -d ' \n')" > /var/lib/opencode/opencode.env
          fi
          ${pkgs.coreutils}/bin/chmod 0600 /var/lib/opencode/opencode.env
          ${pkgs.coreutils}/bin/chown ${vars.userName}:users /var/lib/opencode/opencode.env
        '';
      };

      # Centralized Caddy reverse proxy on opencode.<homelabDomain>
      services.caddy = lib.mkIf config.services.caddy.enable {
        virtualHosts."opencode.${vars.homelabDomain}" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:4096
          '';
        };
      };

      # Open HTTPS port in firewall
      networking.firewall.allowedTCPPorts = lib.mkIf config.services.caddy.enable [
        443
      ];

      # State preservation across ephemeral tmpfs reboots on homelab
      preservation.preserveAt."/persistent" = lib.mkIf config.services.caddy.enable {
        directories = [
          {
            directory = "/var/lib/opencode";
            user = vars.userName;
            group = "users";
            mode = "0750";
          }
        ];
        users.${vars.userName}.directories = [
          ".local/share/opencode"
          ".local/state/opencode"
        ];
      };
    };

    homeManager = {
      inputs,
      pkgs,
      ...
    }: let
      opencodePackage = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
    in {
      programs.opencode = {
        enable = true;
        package = opencodePackage;
        tui = {
          theme = "nord";
        };
      };
    };

    darwin = {
      inputs,
      pkgs,
      ...
    }: let
      opencodePackage = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
    in {
      environment.systemPackages = [
        opencodePackage
      ];
    };
  };
}
