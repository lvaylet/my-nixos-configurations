# my-nixos-configurations

## Usage

```sh
$ just
just --list
Available recipes:
    default                           # run `just --list`

    [(re)build]
    boot configuration="desktop-pc"   # rebuild and switch after boot
    build configuration="desktop-pc"  # rebuild
    build-iso                         # build custom ISO image with SSH access for remote installations
    switch configuration="desktop-pc" # rebuild and switch
    test configuration="desktop-pc"   # rebuild and activate but not switch

    [dev-utils]
    fix                               # fix warnings reported by linters
    fmt                               # format code recursively
    lint                              # run linters

    [flake-management]
    check                             # check whether the flake evaluates and run its tests
    show                              # show the flake outputs
    up                                # update all inputs and `flake.lock` file

    [garbage-collection]
    clean keep="1"                    # clean the current user's profiles
    clean-all keep="1"                # clean all profiles
    collect-garbage                   # delete all unreachable store objects
    delete-old-generations            # delete all unreachable store objects and old generations of profiles
```

## Flake Outputs

```sh
$ just show
git+file:///home/laurent/workspace/github.com/lvaylet/my-nixos-configurations
├───checks
│   └───x86_64-linux
│       └───pre-commit-check: derivation 'pre-commit-run'
├───devShells
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
├───formatter
│   └───x86_64-linux: package 'pre-commit-run'
└───nixosConfigurations
    ├───desktop-pc: NixOS configuration
    └───iso: NixOS configuration
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
