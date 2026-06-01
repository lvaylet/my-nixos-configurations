_: {
  # Run service as OCI container with `systemd`.
  virtualisation.oci-containers.containers.portainer = {
    # Portainer CE with Podman on Linux - https://docs.portainer.io/start/install-ce/server/podman/linux
    image = "docker.io/portainer/portainer-ce:lts";
    volumes = [
      "/var/run/podman/podman.sock:/var/run/docker.sock" # Link to socket
      "/var/lib/portainer:/data" # Persistent volume
    ];
    ports = [
      "8000:8000" # Optional port for Edge Agents
      "9443:9443" # Web interface over HTTPS
    ];
    extraOptions = [
      "--privileged" # Recommended so Portainer can run low-level operations on container engine.
    ];
  };

  # Wait for `/var/lib/containers` to be mounted.
  systemd.services."podman-portainer".after = [
    "local-fs.target"
  ];

  # Open default Portainer ports in firewall.
  networking.firewall.allowedTCPPorts = [
    8000
    9443
  ];
}
