# run `just --list`
default:
  just --list

# rebuild
build configuration="desktop-pc":
  nh os build .#{{configuration}}

# rebuild and switch
switch configuration="desktop-pc":
  nh os switch .#{{configuration}}

# rebuild and switch after boot
boot configuration="desktop-pc":
  nh os boot .#{{configuration}}

# rebuild and activate but not switch
test configuration="desktop-pc":
  nh os test .#{{configuration}}

# format code recursively
fmt:
  nix fmt

# run linters
lint:
  deadnix
  statix check

# fix warnings reported by linters
fix:
  deadnix --edit
  statix fix

# update all inputs and `flake.lock` file
up:
  nix flake update

# show the flake outputs
show:
  nix flake show

# check whether the flake evaluates and run its tests
check:
  nix flake check

# build ISO image
# build-iso:
#     nix build .#nixosConfigurations.iso1chng.config.system.build.isoImage

# delete all unreachable store objects
collect-garbage:
  nix-collect-garbage

# delete all unreachable store objects and old generations of profiles
delete-old-generations:
  nix-collect-garbage --delete-old

# clean the current user's profiles
clean keep="1":
  nh clean user --keep {{keep}} # keep at least this number of generations

# clean all profiles
clean-all keep="1":
  nh clean all --keep {{keep}} # keep at least this number of generations
