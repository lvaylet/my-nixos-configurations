{
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no"; # Whether the root user can login using ssh.
      # Require public key authentication for better security.
      PasswordAuthentication = false; # Specifies whether password authentication is allowed.
      KbdInteractiveAuthentication = false; # Specifies whether keyboard-interactive authentication is allowed.
    };
    openFirewall = true;
  };
}
