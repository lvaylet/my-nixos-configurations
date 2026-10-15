{
  flake.modules.core.preservation = {
    nixos = {vars, ...}: {
      boot.tmp.cleanOnBoot = true;

      preservation = {
        enable = true;

        # Use subvolume defined in `disko.nix`.
        preserveAt."/persistent" = {
          directories = [
            "/etc/nixos"
            "/var/lib/systemd/timers"
            {
              directory = "/var/lib/nixos";
              inInitrd = true;
            }
            "/var/log"
            "/var/lib/bluetooth"
            "/etc/NetworkManager/system-connections"

            "/tmp" # widely used by build tools and editors, may accidentally fill up `tmpfs` root working on big videos or big projects.
          ];

          files = [
            {
              file = "/etc/machine-id";
              inInitrd = true;
            }
            # Persist SSH host keys with correct permissions.
            # Private keys must be 0600, public keys 0644.
            {
              file = "/etc/ssh/ssh_host_ed25519_key";
              mode = "0600";
              configureParent = true;
            }
            {
              file = "/etc/ssh/ssh_host_rsa_key";
              mode = "0600";
              configureParent = true;
            }
            {
              file = "/etc/ssh/ssh_host_ed25519_key.pub";
              mode = "0644";
              configureParent = true;
            }
            {
              file = "/etc/ssh/ssh_host_rsa_key.pub";
              mode = "0644";
              configureParent = true;
            }
          ];

          # Preserve user files.
          users.${vars.userName} = {
            directories = [
              ".ssh"
              ".config/gh" # GitHub CLI authentication and configuration
              ".local/share/fish" # Fish shell history and universal variables
              # ".mozilla"
              # ".local/state/wireplumber"
              # ".local/state/neovim"
              # "Documents"
            ];
          };
        };
      };
    };
  };
}
