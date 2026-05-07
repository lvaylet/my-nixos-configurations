# Module declaring systems supported by your flake, and importing
# a `home-manager` `flake-parts` module.
#
# Read more at: https://flake.parts/options/home-manager.html
{inputs, ...}: {
  imports = [
    # Add home-manager options to flake-parts
    inputs.home-manager.flakeModules.home-manager
  ];

  config.systems = [
    "x86_64-linux"
  ];
}
