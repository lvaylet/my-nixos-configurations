{
  flake.modules.desktop.session = {
    nixos = {pkgs, ...}: {
      # Enable the Niri scrollable-tiling Wayland compositor.
      # Reference: https://github.com/YaLTeR/niri
      # ---
      programs.niri.enable = true;

      # Configure Greetd display manager with Tuigreet session launcher.
      # Reference: https://github.com/apognu/tuigreet
      # ---
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --theme 'border=cyan;text=white;prompt=cyan;time=cyan;action=blue;button=cyan;container=black;input=white' --cmd niri-session";
            user = "greeter";
          };
        };
      };
    };

    homeManager = {
      inputs,
      lib,
      pkgs,
      ...
    }: let
      screenshotTool = pkgs.writeShellApplication {
        name = "screenshot-tool";
        runtimeInputs = with pkgs; [
          coreutils
          grim
          slurp
          wl-clipboard
          libnotify
          satty
          xdg-utils
          niri
        ];
        text = ''
          MODE="''${1:-region}"
          TARGET_DIR="''${HOME}/Pictures/Screenshots"
          mkdir -p "$TARGET_DIR"

          TIMESTAMP=$(date +"%Y-%m-%d %H-%M-%S")
          FILE="''${TARGET_DIR}/Screenshot from ''${TIMESTAMP}.png"

          case "$MODE" in
            region|area)
              if ! GEOM=$(slurp 2>/dev/null); then
                exit 0
              fi
              grim -g "$GEOM" "$FILE" || exit 1
              ;;
            screen|output)
              grim "$FILE" || exit 1
              ;;
            window)
              niri msg action screenshot-window --path "$FILE" || exit 1
              for _ in $(seq 1 20); do
                [ -s "$FILE" ] && break
                sleep 0.1
              done
              ;;
            *)
              echo "Usage: screenshot-tool {region|screen|window}" >&2
              exit 1
              ;;
          esac

          if [ ! -s "$FILE" ]; then
            exit 1
          fi

          wl-copy --type image/png < "$FILE"

          ACTION=$(notify-send \
            --wait \
            --app-name="Capture d'écran" \
            --urgency=low \
            --icon="$FILE" \
            --action="annotate=Annoter" \
            --action="open=Ouvrir" \
            --action="delete=Supprimer" \
            "Capture d'écran enregistrée" \
            "Enregistrée dans Screenshots et copiée dans le presse-papiers" 2>/dev/null || true)

          case "$ACTION" in
            annotate)
              satty --filename "$FILE" --output-filename "$FILE" --early-exit all --copy-command wl-copy
              ;;
            open)
              xdg-open "$(dirname "$FILE")"
              ;;
            delete)
              rm -f "$FILE"
              ;;
            *)
              ;;
          esac
        '';
      };
    in {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        screenshotTool
      ];

      # Niri scrollable-tiling Wayland window manager user configuration.
      # Reference: https://github.com/YaLTeR/niri
      # ---
      xdg.configFile."niri/config.kdl".source = ./dotfiles/niri/config.kdl;

      # Declarative configuration for Satty screenshot annotation tool.
      # Reference: https://github.com/gabm/satty
      # ---
      xdg.configFile."satty/config.toml".source = ./dotfiles/satty/config.toml;

      # Wallpapers directory versioned in the repository.
      # ---
      home.file."Pictures/wallpapers".source = ../../assets/wallpapers;

      # Noctalia native Wayland desktop shell user configuration.
      # Reference: https://github.com/noctalia-dev/noctalia
      # ---
      programs.noctalia = {
        enable = true;
        package = pkgs.noctalia;
        checkConfig = false;
        settings = ./dotfiles/noctalia.toml;
      };
    };
  };
}
