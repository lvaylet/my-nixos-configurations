_: {
  # Run service as OCI container with `systemd`.
  virtualisation.oci-containers.containers.homeassistant = {
    # https://www.home-assistant.io/installation/generic-x86-64/#install-home-assistant-container
    image = "ghcr.io/home-assistant/home-assistant:2026.5.3"; # or `:stable`
    volumes = [
      "/var/lib/home-assistant:/config" # Make sure to persist this volume.
      "/run/dbus:/run/dbus:ro" # Optional: useful for bluetooth/network discovery.
    ];
    environment = {
      TZ = "Europe/Paris";
    };
    extraOptions = [
      # Use the host network namespace for all sockets with mDNS/UPnP discovery.
      "--network=host"
      # Pass devices into the container, so Home Assistant can discover and make use of them.
      # "--device=/dev/ttyACM0:/dev/ttyACM0"
    ];
  };

  # Wait for `/var/lib/containers` to be mounted.
  systemd.services."podman-homeassistant".after = [
    "local-fs.target"
  ];

  # Open default Home Assistant port in firewall.
  networking.firewall.allowedTCPPorts = [
    8123
  ];
}
