# my-nixos-configurations

[![CI](https://github.com/lvaylet/my-nixos-configurations/actions/workflows/ci.yml/badge.svg)](https://github.com/lvaylet/my-nixos-configurations/actions/workflows/ci.yml)

Declarative NixOS multi-host configurations, Home Manager user environments, and portable cross-platform development toolchains.

## Quickstart & Environment Setup

This repository supports development, testing, and deployment from **any Linux machine** (NixOS or non-NixOS) as well as **macOS and Windows (WSL2)** via Devbox.

### Option 1: Cross-Platform via Devbox (Recommended for non-NixOS / macOS / WSL)

If you have [Devbox](https://www.jetify.com/devbox) installed:

```sh
# Start the development shell with all linters, formatters, and task runners:
devbox shell

# Or run tasks directly:
devbox run check
devbox run lint
devbox run fmt
```

### Option 2: Native Nix Flakes (`nix develop`)

On any system with the Nix package manager and Flakes enabled:

```sh
# Enter the nix development shell (automatically sets up pre-commit hooks):
nix develop

# Format and lint:
just fmt
just lint
just check
```

---

## Architecture: The Dendritic Pattern

This repository is structured around the **[Dendritic Pattern](https://github.com/mightyiam/dendritic)** using **`flake-parts`** and **`import-tree`**:

- **Feature-Centric Design**: Every capability is organized as a cohesive feature in domain directories under `modules/` (`core/`, `desktop/`, `services/`, `hosts/`), colocating NixOS system services and Home Manager user environments side-by-side.
- **Zero-Boilerplate Auto-Discovery**: All non-entrypoint files under `modules/` are discovered automatically via `(inputs.import-tree ./modules)` in `flake.nix`, requiring zero manual entries in centralized import arrays.
- **Declarative Host Composition**: Target machines (`modules/hosts/desktop-pc.nix`, `modules/hosts/homelab.nix`, `modules/hosts/iso.nix`) declare their closure purely by listing their hardware specification and an explicit array of enabled features.
- **Unified Identity Context**: Shared user identity, credentials, and parameters are defined as top-level options in `modules/core/vars.nix` (`config.flake.vars`) and accessed without parameter plumbing.

```text
modules/
├── core/                  # Systems, identity options, builder, base system, checks, devShell
├── desktop/               # NNN desktop session, WezTerm, Fish shell, fonts, editors, audio, GPU
├── services/              # Networking, OpenSSH, Tailscale, Podman, Jellyfin, AdGuard Home, etc.
└── hosts/                 # Machine closures (desktop-pc, homelab, iso) and hardware specs
```

---

## Operational Recipes (`justfile`)

All common workflows are defined in the [`justfile`](justfile):

```sh
$ just
Available recipes:
    default                                     # run `just --list`

    [(re)build]
    boot configuration="desktop-pc" target=""   # rebuild and set boot entry (local or remote over SSH)
    build configuration="desktop-pc" target=""  # rebuild system closure (local or remote over SSH)
    build-iso                                   # build custom ISO image with SSH access for remote installations
    switch configuration="desktop-pc" target="" # rebuild and switch (local or remote over SSH)
    test configuration="desktop-pc" target=""   # rebuild and activate temporarily (local or remote over SSH)

    [dev-utils]
    fix                                         # fix warnings reported by linters
    fmt                                         # format code recursively
    lint                                        # run linters

    [flake-management]
    check                                       # check whether the flake evaluates and run its tests
    show                                        # show the flake outputs
    up                                          # update all inputs and `flake.lock` file

    [garbage-collection]
    clean keep="1"                              # clean the current user's profiles
    clean-all keep="1"                          # clean all profiles
    collect-garbage                             # delete all unreachable store objects
    delete-old-generations                      # delete all unreachable store objects and old generations of profiles
```

### Remote Deployments over SSH

To deploy to a remote NixOS host from any Linux machine:

```sh
# Temporarily test a configuration on a remote target:
just test configuration="homelab" target="homelab"

# Permanently deploy and switch a remote target:
just switch configuration="homelab" target="homelab"

# Set next boot profile on a remote target:
just boot configuration="homelab" target="homelab"
```

### Local / Non-NixOS Building

On a non-NixOS Linux workstation, build a target system closure without requiring root privileges:

```sh
just build configuration="homelab"
```

---

## Flake Outputs

```sh
$ just show
git+file:///home/laurent/workspace/github.com/lvaylet/my-nixos-configurations
├───checks
│   ├───aarch64-darwin
│   ├───aarch64-linux
│   ├───x86_64-darwin
│   └───x86_64-linux
│       └───pre-commit-check: derivation 'pre-commit-run'
├───devShells
│   ├───aarch64-darwin
│   ├───aarch64-linux
│   ├───x86_64-darwin
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
├───formatter
│   ├───aarch64-darwin
│   ├───aarch64-linux
│   ├───x86_64-darwin
│   └───x86_64-linux: package 'pre-commit-run'
└───nixosConfigurations
    ├───desktop-pc: NixOS configuration
    ├───homelab: NixOS configuration
    └───iso: NixOS configuration
```

## Continuous Integration

Continuous integration runs on GitHub Actions using a two-stage gated pipeline ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)):

1. **Stage 1 (Quality Gate & Security)**: Runs `nix flake check` to hermetically validate code formatting (`alejandra`), static analysis (`statix`, `deadnix`), flake syntax (`flake-checker`), and secret scanning filters (`trufflehog`, `ripsecrets`, `detect-private-keys`).
2. **Stage 2 (Matrix System Builds)**: Concurrently evaluates and builds top-level derivations for all target configurations (`desktop-pc`, `homelab`, `iso`).
3. **Build Acceleration**: Leverages [Magic Nix Cache](https://github.com/DeterminateSystems/magic-nix-cache-action) and the Determinate Nix Installer for tokenless, zero-configuration GitHub Actions store caching.

---

## Useful Nix Commands

| Command | Purpose |
| --- | --- |
| `nix fmt .` | format all Nix code with Alejandra |
| `nix develop` | activate developer shell with pre-commit hooks and linters |
| `nix flake check` | check whether flake evaluates and all checks pass |
| `nix flake show` | show outputs provided by the flake |
| `nix flake update` | update all pinned inputs in `flake.lock` |
| `nixos-rebuild switch --flake .#<host> --target-host <host> --use-remote-sudo` | manual remote switch command |
