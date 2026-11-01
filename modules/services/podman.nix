{
  flake.modules.services.podman = {
    nixos = {
      config,
      lib,
      ...
    }: {
      # Centralized Podman and OCI container configuration.
      virtualisation = {
        podman = {
          enable = true;
          autoPrune.enable = true;
          dockerCompat = true; # Enable compatibility with Docker commands.
          defaultNetwork.settings.dns_enabled = true; # So containers can communicate with each other based on their names.
        };

        oci-containers = {
          backend = "podman";
        };
      };

      # Automatically update container images daily via Podman's native auto-update mechanism.
      systemd.timers.podman-auto-update = lib.mkIf config.virtualisation.podman.enable {
        description = "Podman auto-update timer";
        documentation = [
          "man:podman-auto-update(1)"
        ];
        wantedBy = [
          "timers.target"
        ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          RandomizedDelaySec = "900";
        };
      };

      systemd.services.podman-auto-update = lib.mkIf config.virtualisation.podman.enable {
        description = "Podman auto-update service";
        documentation = [
          "man:podman-auto-update(1)"
        ];
        wants = [
          "network-online.target"
        ];
        after = [
          "network-online.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${config.virtualisation.podman.package}/bin/podman auto-update";
          ExecStartPost = "${config.virtualisation.podman.package}/bin/podman image prune -f";
        };
      };

      # Conditional preservation mapping (integrated as sub-attribute of config, keeping it top-level clean)
      preservation.preserveAt."/persistent".directories = lib.mkIf config.virtualisation.podman.enable [
        {
          directory = "/var/tmp"; # Podman's default for temporary storage location of downloaded container images.
          # Mode 1777 (rwxrwxrwt): Standard world-writable temporary directory with the sticky bit (1)
          # so both rootful/rootless services and unprivileged users can create temporary files while
          # only file owners (or root) can delete or rename their own entries (overrides preservation's 0755 default).
          mode = "1777";
        }
        "/var/lib/containers" # Podman's default for images and containers in rootful mode.
      ];
    };
  };
}
