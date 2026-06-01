{
  pkgs,
  config,
  ...
}: {
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    group = "multimedia"; # Directly bind Jellyfin to the group for seamless read/write access.
  };

  users.users.${config.vars.userName}.extraGroups = [
    "video"
    "render"
  ];

  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];

  # Hardware acceleration (modern syntax for nixos-unstable)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime # OpenCL tone mapping
      vpl-gpu-rt # QSV implementation
    ];
  };
}
