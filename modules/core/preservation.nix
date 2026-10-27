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

            {
              directory = "/tmp"; # widely used by build tools and editors, may accidentally fill up `tmpfs` root working on big videos or big projects.
              # Mode 1777 (rwxrwxrwt): Required standard permissions for temporary directories.
              # Grants read/write/execute access to all unprivileged users (777) while the sticky
              # bit (1) prevents users from deleting or renaming files owned by others. Without it,
              # preservation defaults to 0755 (root-only write) and breaks user tools like direnv/nix.
              mode = "1777";
            }
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
              ".local/share/direnv" # Direnv allowed .envrc hashes and state
              ".local/share/fish" # Fish shell history and universal variables
              ".local/share/nvim" # LazyVim plugins, lazy-lock.json, and Tree-sitter parsers
              ".local/state/nvim" # Neovim undo history, ShaDa registers, and session state
              "workspace" # Preserved git workspaces and cloned repositories
              # ".mozilla"
              # ".local/state/wireplumber"
              # "Documents"
            ];
          };
        };
      };
    };
  };
}
