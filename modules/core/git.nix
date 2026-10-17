{
  flake.modules.core.git = {
    homeManager = {vars, ...}: {
      programs.git = {
        enable = true;
        settings = {
          user = {
            name = vars.userName;
            email = vars.userEmail;
          };
          init.defaultBranch = "main";

          # Popular Git Config Options - https://jvns.ca/blog/2024/02/16/popular-git-config-options/
          color.ui = "auto";
          commit.verbose = true;
          diff = {
            algorithm = "histogram";
            colorMoved = "default";
            mnemonicPrefix = true;
            renames = true;
          };
          fetch.prune = true;
          help.autocorrect = 10;
          merge = {
            conflictstyle = "zdiff3";
            tool = "meld";
          };
          pull = {
            ff = "only";
            rebase = true;
          };
          push.autoSetupRemote = true;
          rebase = {
            autosquash = true;
            autostash = true;
          };
          rerere.enable = true;
        };
      };

      programs.lazygit = {
        enable = true;
        settings = {
          gui = {
            theme = {
              activeBorderColor = [
                "#88c0d0"
                "bold"
              ];
              inactiveBorderColor = [
                "#4c566a"
              ];
              optionsTextColor = [
                "#81a1c1"
              ];
              selectedLineBgColor = [
                "#3b4252"
              ];
              cherryPickedCommitBgColor = [
                "#434c5e"
              ];
              cherryPickedCommitFgColor = [
                "#88c0d0"
              ];
              unstagedChangesColor = [
                "#bf616a"
              ];
              defaultFgColor = [
                "#d8dee9"
              ];
              searchingActiveBorderColor = [
                "#ebcb8b"
              ];
            };
          };
        };
      };
    };
  };
}
