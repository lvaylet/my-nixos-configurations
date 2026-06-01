_: {
  # Run service as OCI container with `systemd`.
  virtualisation.oci-containers.containers.filebrowser = {
    # FileBrowser Quantum - https://github.com/gtsteffaniak/filebrowser
    image = "ghcr.io/gtsteffaniak/filebrowser:latest";
    volumes = [
      "/data:/srv"
      # "/var/lib/filebrowser:/config" # TODO Is that relevant/required?
    ];
    environment = {
      PUID = "992"; # Match `filebrowser` user UID in `media.nix`.
      PGID = "995"; # Match `multimedia` group GID in `media.nix`.
      UMASK = "0002"; # Grant rw-rw-r-- (664) to created assets.
      # FILEBROWSER_CONFIG = "/config/config.yaml"; # TODO Is that relevant/required?
      # FILEBROWSER_DATABASE = "/config/filebrowser.db"; # TODO Is that relevant/required?
    };
    ports = [
      "8081:80" # host:container
    ];
    extraOptions = [
      "--group-add=995" # Ensure access to `multimedia` group.
    ];
    capabilities = {
      CAP_NET_BIND_SERVICE = true; # Required to bind container port 80 < 1024, even on 8081 > 1024.
    };
  };

  # Wait for `/var/lib/containers` to be mounted.
  systemd.services."podman-filebrowser".after = [
    "local-fs.target"
  ];

  # Open default Filebrowser port in firewall.
  networking.firewall.allowedTCPPorts = [
    8081
  ];
}
