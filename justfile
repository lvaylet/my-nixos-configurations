default: format lint build

# Rebuild
build configuration="desktop-pc":
  nh os build .#{{configuration}}

# Rebuild and switch
switch configuration="desktop-pc":
  nh os switch .#{{configuration}}

# Rebuild and switch after boot
boot configuration="desktop-pc":
  nh os boot .#{{configuration}}

# Rebuild and activate but not switch
test configuration="desktop-pc":
  nh os test .#{{configuration}}

format:
  nix fmt

lint:
  deadnix
  statix check

# Fix warnings reported by `deadnix` and `statix`
fix:
  deadnix --edit
  statix fix

collect-garbage:
  nix-collect-garbage

delete-old-generations:
  nix-collect-garbage --delete-old

clean keep="1":
  nh clean user --keep {{keep}}

clean-all keep="1":
  nh clean all --keep {{keep}}
