# my-nixos-configurations

## Usage

```sh
$ just
just --list
Available recipes:
    boot configuration="desktop-pc"   # rebuild and switch after boot
    build configuration="desktop-pc"  # rebuild
    clean keep="1"                    # clean the current user's profiles
    clean-all keep="1"                # clean all profiles
    collect-garbage                   # delete all unreachable store objects
    default                           # run `just --list`
    delete-old-generations            # delete all unreachable store objects and old generations of profiles
    fix                               # fix warnings reported by linters
    fmt                               # format code recursively
    lint                              # run linters
    switch configuration="desktop-pc" # rebuild and switch
    test configuration="desktop-pc"   # rebuild and activate but not switch
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
