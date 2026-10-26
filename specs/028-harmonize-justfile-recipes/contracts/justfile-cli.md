# CLI Interface Contract: `justfile` Recipes

**Feature**: `028-harmonize-justfile-recipes`
**Date**: 2026-10-26

## Expected `just --list` Output

```text
Available recipes:
    default                            # run `just --list`

    [(re)build]
    boot configuration="" target=""    # rebuild and set boot default (NixOS local or remote over SSH)
    build configuration="" target=""   # rebuild system closure without activating (NixOS or Darwin)
    build-iso                          # build custom ISO image with SSH access for remote installations
    install target configuration="homelab" # bootstrap and install NixOS host remotely from scratch using nixos-anywhere
    switch configuration="" target=""  # rebuild and switch live profile (NixOS or Darwin, local or remote over SSH)
    test configuration="" target=""    # rebuild and test live without saving generation (NixOS or Darwin, local or remote over SSH)

    [dev-utils]
    fix                                # fix warnings reported by linters
    fmt                                # format code recursively
    lint                               # run linters

    [flake-management]
    check                              # check whether the flake evaluates and run its tests
    show                               # show the flake outputs
    up                                 # update all inputs and `flake.lock` file

    [garbage-collection]
    clean keep="1"                     # clean the current user's profiles
    clean-all keep="1"                 # clean all profiles
    collect-garbage                    # delete all unreachable store objects
    delete-old-generations             # delete all unreachable store objects and old generations of profiles
```

## Recipe Behavioral Contracts

### 1. `just build [configuration=""] [target=""]`

- **Purpose**: Compile the system closure without activating it.
- **Resolution**:
  - `CONFIG`: If `configuration` is empty, `"macbook-air-m4-15"` on Darwin, else local `hostname -s` if `"homelab"` or `"desktop-pc"`, else `"desktop-pc"`.
- **Execution**:
  - If `CONFIG == "macbook-air-m4-15"`:
    - `nix build .#darwinConfigurations.${CONFIG}.system`
  - Else (NixOS configuration):
    - If `target` is empty:
      - If `command -v nh` and `[ -e /etc/NIXOS ]`: `nh os build .#${CONFIG}`
      - Else: `nix build .#nixosConfigurations.${CONFIG}.config.system.build.toplevel`
    - Else (`target` is non-empty):
      - If `command -v nh`: `nh os build .#${CONFIG} --target-host "${target}"`
      - Else: `nixos-rebuild build --flake .#${CONFIG} --target-host "${target}"`

### 2. `just test [configuration=""] [target=""]`

- **Purpose**: Build and activate the configuration in the live session without creating a permanent boot entry or profile generation.
- **Resolution**:
  - `CONFIG`: Same auto-detection as `build`.
  - `TARGET`: For NixOS configurations, if `target` is empty and (`! -e /etc/NIXOS` or `hostname -s != ${CONFIG}`), `TARGET="${CONFIG}"`.
- **Execution**:
  - If `CONFIG == "macbook-air-m4-15"`:
    - Must run on Darwin (`uname -s == "Darwin"`), else exit 1 with error.
    - `systemConfig=$(nix build --no-link --print-out-paths .#darwinConfigurations.${CONFIG}.system)`
    - `sudo "${systemConfig}/activate"`
  - Else (NixOS configuration):
    - If `TARGET` is empty (local NixOS host matching `CONFIG`):
      - If `command -v nh`: `nh os test .#${CONFIG}`
      - Else: `sudo nixos-rebuild test --flake .#${CONFIG}`
    - Else (remote NixOS target):
      - If `command -v nh`: `nh os test .#${CONFIG} --elevation-strategy passwordless --target-host "${TARGET}"`
      - Else: `nixos-rebuild test --flake .#${CONFIG} --target-host "${TARGET}" --use-remote-sudo`

### 3. `just switch [configuration=""] [target=""]`

- **Purpose**: Build, activate, and permanently record a new system generation.
- **Resolution**: Same `CONFIG` and `TARGET` resolution as `test`.
- **Execution**:
  - If `CONFIG == "macbook-air-m4-15"`:
    - Must run on Darwin (`uname -s == "Darwin"`), else exit 1 with error.
    - `sudo nix run nix-darwin -- switch --flake .#${CONFIG}`
  - Else (NixOS configuration):
    - If `TARGET` is empty (local NixOS host matching `CONFIG`):
      - If `command -v nh`: `nh os switch .#${CONFIG}`
      - Else: `sudo nixos-rebuild switch --flake .#${CONFIG}`
    - Else (remote NixOS target):
      - If `command -v nh`: `nh os switch .#${CONFIG} --elevation-strategy passwordless --target-host "${TARGET}"`
      - Else: `nixos-rebuild switch --flake .#${CONFIG} --target-host "${TARGET}" --use-remote-sudo`

### 4. `just boot [configuration=""] [target=""]`

- **Purpose**: Build and register the configuration as the boot default without activating immediately.
- **Resolution**: Same `CONFIG` and `TARGET` resolution as `test`.
- **Execution**:
  - If `CONFIG == "macbook-air-m4-15"`:
    - Exit 1 with error (`boot` is only supported on NixOS hosts).
  - Else (NixOS configuration):
    - If `TARGET` is empty (local NixOS host matching `CONFIG`):
      - If `command -v nh`: `nh os boot .#${CONFIG}`
      - Else: `sudo nixos-rebuild boot --flake .#${CONFIG}`
    - Else (remote NixOS target):
      - If `command -v nh`: `nh os boot .#${CONFIG} --elevation-strategy passwordless --target-host "${TARGET}"`
      - Else: `nixos-rebuild boot --flake .#${CONFIG} --target-host "${TARGET}" --use-remote-sudo`

### 5. `just install <target> [configuration="homelab"]`

- **Purpose**: Bootstrap and partition a NixOS machine from scratch over SSH using `nixos-anywhere`.
- **Execution**:
  - If `configuration == "macbook-air-m4-15"`, exit 1 with error.
  - If `target` does not contain `@`, prepend `root@` (`TARGET_HOST="root@${target}"`).
  - `nix run github:nix-community/nixos-anywhere -- --flake .#${configuration} "${TARGET_HOST}"`
