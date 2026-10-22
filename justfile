# run `just --list`
default:
  just --list

###################################
# (Re)build
###################################

# rebuild
[group('(re)build')]
build configuration="desktop-pc" target="":
  #!/usr/bin/env bash
  set -euo pipefail
  if [ -z "{{target}}" ]; then
    if command -v nh >/dev/null 2>&1 && [ -e /etc/NIXOS ]; then
      nh os build .#{{configuration}}
    else
      nix build .#nixosConfigurations.{{configuration}}.config.system.build.toplevel
    fi
  else
    nixos-rebuild build --flake .#{{configuration}} --target-host {{target}}
  fi

# rebuild and switch
[group('(re)build')]
switch configuration="desktop-pc" target="":
  #!/usr/bin/env bash
  set -euo pipefail
  if [ -z "{{target}}" ]; then
    if [ ! -e /etc/NIXOS ]; then
      echo "Error: Local system is not NixOS. To deploy to a remote NixOS host, specify the target parameter, e.g.: just switch {{configuration}} <target-host>" >&2
      exit 1
    fi
    nh os switch .#{{configuration}}
  else
    nixos-rebuild switch --flake .#{{configuration}} --target-host {{target}} --use-remote-sudo
  fi

# rebuild and switch after boot
[group('(re)build')]
boot configuration="desktop-pc" target="":
  #!/usr/bin/env bash
  set -euo pipefail
  if [ -z "{{target}}" ]; then
    if [ ! -e /etc/NIXOS ]; then
      echo "Error: Local system is not NixOS. To set boot entry on a remote NixOS host, specify the target parameter, e.g.: just boot {{configuration}} <target-host>" >&2
      exit 1
    fi
    nh os boot .#{{configuration}}
  else
    nixos-rebuild boot --flake .#{{configuration}} --target-host {{target}} --use-remote-sudo
  fi

# rebuild and activate but not switch
[group('(re)build')]
test configuration="desktop-pc" target="":
  #!/usr/bin/env bash
  set -euo pipefail
  if [ -z "{{target}}" ]; then
    if [ ! -e /etc/NIXOS ]; then
      echo "Error: Local system is not NixOS. To test on a remote NixOS host, specify the target parameter, e.g.: just test {{configuration}} <target-host>" >&2
      exit 1
    fi
    nh os test .#{{configuration}}
  else
    nixos-rebuild test --flake .#{{configuration}} --target-host {{target}} --use-remote-sudo
  fi

# build custom ISO image with SSH access for remote installations
[group('(re)build')]
build-iso:
  nix build .#nixosConfigurations.iso.config.system.build.isoImage

# rebuild macOS host configuration closure without activating
[group('(re)build')]
build-darwin configuration="macbook-air-m4-15":
  nix build .#darwinConfigurations.{{configuration}}.system

# test and activate macOS host configuration without setting a new generation profile
[group('(re)build')]
test-darwin configuration="macbook-air-m4-15":
  #!/usr/bin/env bash
  set -euo pipefail
  echo "==> Building and testing Darwin configuration {{configuration}}..."
  systemConfig=$(nix build --no-link --print-out-paths .#darwinConfigurations.{{configuration}}.system)
  sudo "${systemConfig}/activate"

# rebuild and switch macOS host (Darwin) creating a new generation profile
[group('(re)build')]
switch-darwin configuration="macbook-air-m4-15":
  nix run nix-darwin -- switch --flake .#{{configuration}}

# bootstrap and install homelab remotely from scratch using nixos-anywhere
[group('(re)build')]
install-homelab target:
  #!/usr/bin/env bash
  set -euo pipefail
  TARGET_HOST="{{target}}"
  if [[ "${TARGET_HOST}" != *"@"* ]]; then
    TARGET_HOST="root@${TARGET_HOST}"
  fi
  echo "==> Deploying homelab to ${TARGET_HOST} with nixos-anywhere..."
  nix run github:nix-community/nixos-anywhere -- --flake .#homelab "${TARGET_HOST}"

# deploy configuration update to homelab without repartitioning
[group('(re)build')]
deploy-homelab target="homelab":
  #!/usr/bin/env bash
  set -euo pipefail
  TARGET_HOST="{{target}}"
  if [[ "${TARGET_HOST}" != *"@"* ]]; then
    TARGET_HOST="root@${TARGET_HOST}"
  fi
  echo "==> Switching configuration on homelab (${TARGET_HOST})..."
  if command -v nh >/dev/null 2>&1; then
    nh os switch . -H homelab --target-host "${TARGET_HOST}"
  else
    nixos-rebuild switch --flake .#homelab --target-host "${TARGET_HOST}"
  fi

# test configuration update on remote homelab without setting boot profile
[group('(re)build')]
test-homelab target="homelab":
  #!/usr/bin/env bash
  set -euo pipefail
  TARGET_HOST="{{target}}"
  if [[ "${TARGET_HOST}" != *"@"* ]]; then
    TARGET_HOST="root@${TARGET_HOST}"
  fi
  echo "==> Testing configuration on homelab (${TARGET_HOST})..."
  if command -v nh >/dev/null 2>&1; then
    nh os test . -H homelab --target-host "${TARGET_HOST}"
  else
    nixos-rebuild test --flake .#homelab --target-host "${TARGET_HOST}"
  fi

###################################
# Dev Utils
###################################

# format code recursively
[group('dev-utils')]
fmt:
  nix fmt .

# run linters
[group('dev-utils')]
lint:
  deadnix
  statix check

# fix warnings reported by linters
[group('dev-utils')]
fix:
  deadnix --edit
  statix fix

###################################
# Flake Management
###################################

# update all inputs and `flake.lock` file
[group('flake-management')]
up:
  nix flake update

# show the flake outputs
[group('flake-management')]
show:
  nix flake show

# check whether the flake evaluates and run its tests
[group('flake-management')]
check:
  nix flake check

###################################
# Garbage Collection
###################################

# delete all unreachable store objects
[group('garbage-collection')]
collect-garbage:
  nix-collect-garbage

# delete all unreachable store objects and old generations of profiles
[group('garbage-collection')]
delete-old-generations:
  nix-collect-garbage --delete-old

# clean the current user's profiles
[group('garbage-collection')]
clean keep="1":
  #!/usr/bin/env bash
  set -euo pipefail
  if command -v nh >/dev/null 2>&1 && [ -e /etc/NIXOS ]; then
    nh clean user --keep {{keep}} # keep at least this number of generations
  else
    nix-collect-garbage --delete-older-than {{keep}}d 2>/dev/null || nix-collect-garbage
  fi

# clean all profiles
[group('garbage-collection')]
clean-all keep="1":
  #!/usr/bin/env bash
  set -euo pipefail
  if command -v nh >/dev/null 2>&1 && [ -e /etc/NIXOS ]; then
    nh clean all --keep {{keep}} # keep at least this number of generations
  else
    nix-collect-garbage --delete-old
  fi
