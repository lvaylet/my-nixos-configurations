{
  flake.modules.services.media = {
    nixos = _: {
      # Storage directory (example)
      systemd.tmpfiles.rules = [
        "d /var/lib/media 0775 admin users -"
      ];
    };
  };
}
