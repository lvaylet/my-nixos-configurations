# run `just --list`
default:
  just --list

###################################
# (Re)build
###################################

# rebuild system closure without activating (NixOS or Darwin)
[group('(re)build')]
build configuration="" target="":
  #!/usr/bin/env bash
  set -euo pipefail
  CONFIG="{{configuration}}"
  TARGET="{{target}}"
  if [ -z "${CONFIG}" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
      CONFIG="macbook-air-m4-15"
    else
      HOST="$(hostname -s 2>/dev/null || uname -n)"
      if [ "${HOST}" = "homelab" ] || [ "${HOST}" = "desktop-pc" ]; then
        CONFIG="${HOST}"
      else
        CONFIG="desktop-pc"
      fi
    fi
  fi
  if [ "${CONFIG}" = "macbook-air-m4-15" ]; then
    echo "==> Building Darwin configuration ${CONFIG}..."
    nix build ".#darwinConfigurations.${CONFIG}.system"
  else
    if [ -z "${TARGET}" ]; then
      if command -v nh >/dev/null 2>&1 && [ -e /etc/NIXOS ]; then
        nh os build ".#${CONFIG}"
      else
        nix build ".#nixosConfigurations.${CONFIG}.config.system.build.toplevel"
      fi
    else
      echo "==> Building NixOS configuration ${CONFIG} on ${TARGET}..."
      if command -v nh >/dev/null 2>&1; then
        nh os build ".#${CONFIG}" --target-host "${TARGET}"
      else
        nixos-rebuild build --flake ".#${CONFIG}" --target-host "${TARGET}"
      fi
    fi
  fi

# rebuild and switch live profile (NixOS or Darwin, local or remote over SSH)
[group('(re)build')]
switch configuration="" target="":
  #!/usr/bin/env bash
  set -euo pipefail
  CONFIG="{{configuration}}"
  TARGET="{{target}}"
  if [ -z "${CONFIG}" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
      CONFIG="macbook-air-m4-15"
    else
      HOST="$(hostname -s 2>/dev/null || uname -n)"
      if [ "${HOST}" = "homelab" ] || [ "${HOST}" = "desktop-pc" ]; then
        CONFIG="${HOST}"
      else
        CONFIG="desktop-pc"
      fi
    fi
  fi
  if [ "${CONFIG}" = "macbook-air-m4-15" ]; then
    if [ "$(uname -s)" != "Darwin" ]; then
      echo "Error: Darwin configuration '${CONFIG}' can only be switched on macOS." >&2
      exit 1
    fi
    echo "==> Switching Darwin configuration ${CONFIG}..."
    sudo nix run nix-darwin -- switch --flake ".#${CONFIG}"
  else
    HOST="$(hostname -s 2>/dev/null || uname -n)"
    if [ -z "${TARGET}" ] && { [ ! -e /etc/NIXOS ] || [ "${HOST}" != "${CONFIG}" ]; }; then
      TARGET="${CONFIG}"
    fi
    if [ -z "${TARGET}" ]; then
      echo "==> Switching NixOS configuration ${CONFIG} locally..."
      if command -v nh >/dev/null 2>&1; then
        nh os switch ".#${CONFIG}"
      else
        sudo nixos-rebuild switch --flake ".#${CONFIG}"
      fi
    else
      echo "==> Switching NixOS configuration ${CONFIG} on ${TARGET}..."
      if command -v nh >/dev/null 2>&1; then
        nh os switch ".#${CONFIG}" --elevation-strategy passwordless --target-host "${TARGET}"
      else
        nixos-rebuild switch --flake ".#${CONFIG}" --target-host "${TARGET}" --use-remote-sudo
      fi
    fi
  fi

# rebuild and set boot default (NixOS local or remote over SSH)
[group('(re)build')]
boot configuration="" target="":
  #!/usr/bin/env bash
  set -euo pipefail
  CONFIG="{{configuration}}"
  TARGET="{{target}}"
  if [ -z "${CONFIG}" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
      echo "Error: 'just boot' is only supported for NixOS configurations. Specify a NixOS target, e.g.: just boot homelab" >&2
      exit 1
    fi
    HOST="$(hostname -s 2>/dev/null || uname -n)"
    if [ "${HOST}" = "homelab" ] || [ "${HOST}" = "desktop-pc" ]; then
      CONFIG="${HOST}"
    else
      CONFIG="desktop-pc"
    fi
  fi
  if [ "${CONFIG}" = "macbook-air-m4-15" ]; then
    echo "Error: 'just boot' is only supported for NixOS configurations, not Darwin ('${CONFIG}')." >&2
    exit 1
  fi
  HOST="$(hostname -s 2>/dev/null || uname -n)"
  if [ -z "${TARGET}" ] && { [ ! -e /etc/NIXOS ] || [ "${HOST}" != "${CONFIG}" ]; }; then
    TARGET="${CONFIG}"
  fi
  if [ -z "${TARGET}" ]; then
    echo "==> Setting boot NixOS configuration ${CONFIG} locally..."
    if command -v nh >/dev/null 2>&1; then
      nh os boot ".#${CONFIG}"
    else
      sudo nixos-rebuild boot --flake ".#${CONFIG}"
    fi
  else
    echo "==> Setting boot NixOS configuration ${CONFIG} on ${TARGET}..."
    if command -v nh >/dev/null 2>&1; then
      nh os boot ".#${CONFIG}" --elevation-strategy passwordless --target-host "${TARGET}"
    else
      nixos-rebuild boot --flake ".#${CONFIG}" --target-host "${TARGET}" --use-remote-sudo
    fi
  fi

# rebuild and test live without saving generation (NixOS or Darwin, local or remote over SSH)
[group('(re)build')]
test configuration="" target="":
  #!/usr/bin/env bash
  set -euo pipefail
  CONFIG="{{configuration}}"
  TARGET="{{target}}"
  if [ -z "${CONFIG}" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
      CONFIG="macbook-air-m4-15"
    else
      HOST="$(hostname -s 2>/dev/null || uname -n)"
      if [ "${HOST}" = "homelab" ] || [ "${HOST}" = "desktop-pc" ]; then
        CONFIG="${HOST}"
      else
        CONFIG="desktop-pc"
      fi
    fi
  fi
  if [ "${CONFIG}" = "macbook-air-m4-15" ]; then
    if [ "$(uname -s)" != "Darwin" ]; then
      echo "Error: Darwin configuration '${CONFIG}' can only be tested on macOS." >&2
      exit 1
    fi
    echo "==> Building and testing Darwin configuration ${CONFIG}..."
    systemConfig=$(nix build --no-link --print-out-paths ".#darwinConfigurations.${CONFIG}.system")
    sudo "${systemConfig}/activate"
  else
    HOST="$(hostname -s 2>/dev/null || uname -n)"
    if [ -z "${TARGET}" ] && { [ ! -e /etc/NIXOS ] || [ "${HOST}" != "${CONFIG}" ]; }; then
      TARGET="${CONFIG}"
    fi
    if [ -z "${TARGET}" ]; then
      echo "==> Testing NixOS configuration ${CONFIG} locally..."
      if command -v nh >/dev/null 2>&1; then
        nh os test ".#${CONFIG}"
      else
        sudo nixos-rebuild test --flake ".#${CONFIG}"
      fi
    else
      echo "==> Testing NixOS configuration ${CONFIG} on ${TARGET}..."
      if command -v nh >/dev/null 2>&1; then
        nh os test ".#${CONFIG}" --elevation-strategy passwordless --target-host "${TARGET}"
      else
        nixos-rebuild test --flake ".#${CONFIG}" --target-host "${TARGET}" --use-remote-sudo
      fi
    fi
  fi

# bootstrap and install NixOS host remotely from scratch using nixos-anywhere
[group('(re)build')]
install target configuration="homelab":
  #!/usr/bin/env bash
  set -euo pipefail
  CONFIG="{{configuration}}"
  if [ "${CONFIG}" = "macbook-air-m4-15" ]; then
    echo "Error: 'just install' with nixos-anywhere is only supported for NixOS configurations, not Darwin ('${CONFIG}')." >&2
    exit 1
  fi
  TARGET_HOST="{{target}}"
  if [[ "${TARGET_HOST}" != *"@"* ]]; then
    TARGET_HOST="root@${TARGET_HOST}"
  fi
  echo "==> Installing ${CONFIG} to ${TARGET_HOST} with nixos-anywhere..."
  nix run github:nix-community/nixos-anywhere -- --flake ".#${CONFIG}" "${TARGET_HOST}"

# build custom ISO image with SSH access for remote installations
[group('(re)build')]
build-iso:
  nix build .#nixosConfigurations.iso.config.system.build.isoImage

###################################
# Dev Utils
###################################

# format code recursively
[group('dev-utils')]
fmt:
  nix fmt .

# lint Markdown files with markdownlint-cli2 (excluding .agents)
[group('dev-utils')]
lint-md:
  markdownlint-cli2

# fix Markdown files with markdownlint-cli2 (excluding .agents)
[group('dev-utils')]
fix-md:
  markdownlint-cli2 --fix

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
  markdownlint-cli2 --fix

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
    sudo nix-collect-garbage --delete-old
  fi
