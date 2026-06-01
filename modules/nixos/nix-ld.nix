{
  # Run unpatched dynamic binaries on NixOS with `nix-ld`.
  #
  # Where is this useful?
  #
  # While many proprietary packages in nixpkgs have already been patched with
  # patching, there are cases where patching is not possible:
  # - Use binary executable downloaded with third-party package managers (e.g.
  #   vscode, npm or pip) without having to patch them on every update.
  # - Run games or proprietary software that attempts to verify its integrity.
  # - Run programs that are too large for the nix store (e.g. FPGA IDEs).
  #
  # References:
  # - https://github.com/nix-community/nix-ld
  # - https://nixos.wiki/wiki/Visual_Studio_Code#Remote_SSH
  # - https://nix-community.github.io/NixOS-WSL/how-to/vscode.html
  programs.nix-ld.enable = true;
}
