# run `just --list`
default:
  just --list

###################################
# (Re)build
###################################

# rebuild
[group('(re)build')]
build configuration="desktop-pc":
  nh os build .#{{configuration}}

# rebuild and switch
[group('(re)build')]
switch configuration="desktop-pc":
  nh os switch .#{{configuration}}

# rebuild and switch after boot
[group('(re)build')]
boot configuration="desktop-pc":
  nh os boot .#{{configuration}}

# rebuild and activate but not switch
[group('(re)build')]
test configuration="desktop-pc":
  nh os test .#{{configuration}}

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
  nh clean user --keep {{keep}} # keep at least this number of generations

# clean all profiles
[group('garbage-collection')]
clean-all keep="1":
  nh clean all --keep {{keep}} # keep at least this number of generations
