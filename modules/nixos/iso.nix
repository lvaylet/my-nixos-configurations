{config, ...}: {
  imports = [
    ./_packages.nix
    ./options.nix
  ];

  users.users.nixos = {
    # Indicates whether this is an account for a "real" user. This automatically sets:
    # - `group` to `users`
    # - `createHome` to `true`
    # - `home` to `/home/${username}`
    # - `useDefaultShell` to `true`
    # - `isSystemUser` to `false`
    # Exactly one of `isNormalUser` and `isSystemUser` must be `true`.
    isNormalUser = true;
    # The user's auxiliary groups.
    extraGroups = [
      "wheel"
    ];
    # A list of verbatim OpenSSH public keys that should be added to the user's authorized keys.
    # The keys are added to a file that the SSH daemon reads in addition to the the user's
    # `authorized_keys` file. You can combine the `keys` and `keyFiles` options.
    # Warning: If you are using `NixOps` then don't use this option since it will replace the key
    # required for deployment via ssh.
    openssh.authorizedKeys.keys =
      config.vars.sshPublicKeysPersonal
      ++ config.vars.sshPublicKeysWork;
  };

  # Message of the day shown to users when they log in.
  # TODO Adjust message for remote installation. Display IP and/or SSH command, for example?
  users.motd = ''
    Welcome to my custom NixOS ISO installer!

    To connect over SSH and/or performa a remote installation, check the local IPv4 address with:

    ip -4 -j addr show | jq -r '.[] | select(.operstate == "UP") | .addr_info[0].local'

  '';

  # Let users of the wheel group run commands as super user (via sudo) without providing a password.
  security.sudo.wheelNeedsPassword = false;

  # Enable Flakes and modern Nix.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Enable remote SSH access.
  services.openssh = {
    enable = true;
  };

  # `boot.zfs.forceImportRoot` is using the default value of `true` in 26.05. It is highly
  # recommended to set it to `false`, the new default from 26.11 on, to reduce the risk of data
  # loss. Alternatively, you can silence this warning by explicitly setting it to `true`.
  boot.zfs.forceImportRoot = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
