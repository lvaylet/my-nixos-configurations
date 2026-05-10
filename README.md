# my-nixos-configurations

## Usage

```sh
just build # rebuild
just test # rebuild and activate but not switch
just boot # rebuild and switch after boot
just switch # rebuild and switch

just format
just lint
```

## Useful Nix Commands

| Command | Purpose | Looks for |
| --- | --- | --- |
| `nix run` | run a Nix application | `outputs.packages."SYSTEM".default` |
| `nix build` | build a derivation or fetch a store path | `outputs.packages."SYSTEM".default` |
| `nix develop` | activate a dev shell | `outputs.devShells."SYSTEM".default` |
| `nixos-rebuild` | build a nixos system | `outputs.nixosConfigurations."HOSTNAME"` |
| `home-manager` | build a home configuration | `outputs.homeConfigurations."USERNAME"` |
| `nix flake show` | show the outputs provided by a flake | `outputs` |
| `nix flake check` | check whether the flake evaluates and run its tests | |
| `nix flake metadata` | show flake metadata | |
| `nix flake update` | update flake lock file | |
