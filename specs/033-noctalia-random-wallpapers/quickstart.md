# Quickstart & Validation Guide: Dynamic Random Noctalia Wallpapers on `desktop-pc`

**Feature Branch**: `033-noctalia-random-wallpapers` | **Date**: 2026-10-30 | **Spec**: [spec.md](./spec.md)

## Prerequisites

- Nix with Flakes enabled
- Repository checked out on branch `033-noctalia-random-wallpapers`

---

## 1. Static Validation & Formatting

Run repository pre-commit linters and code formatters:

```sh
just fmt
just lint
```

**Expected Outcome**: Zero formatting diffs and zero errors/warnings from `alejandra`, `statix`, and `deadnix`.

---

## 2. Niri Compositor Configuration Validation

Verify that Niri's configuration syntax and keybindings are strictly valid:

```sh
nix run nixpkgs#niri -- validate -c modules/desktop/dotfiles/niri/config.kdl
```

**Expected Outcome**: Output logs `[INFO] niri: config is valid` with exit code `0`.

---

## 3. Verify Removal of Stale Nix Store References

Verify that no hardcoded `/nix/store/` wallpaper paths remain in the desktop configuration:

```sh
rg '/nix/store.*wallpaper' modules/desktop/
```

**Expected Outcome**: Zero matches returned.

---

## 4. Flake Evaluation & Home Manager Symlink Inspection

Verify that `desktop-pc` evaluates cleanly and that the Home Manager wallpaper symlink correctly points to the `assets/wallpapers` directory:

```sh
nix eval .#nixosConfigurations.desktop-pc.config.home-manager.users.laurent.home.file."Pictures/wallpapers".source
```

**Expected Outcome**: Resolves to the path of `assets/wallpapers` in the repository tree.

Run the repository check suite:

```sh
just check
```

**Expected Outcome**: All sandbox tests and flake checks pass with exit code `0`.

---

## 5. Live Runtime Verification on `desktop-pc`

1. **Populate Wallpapers**: Place one or more image files (`.png`, `.jpg`, `.webp`) into `assets/wallpapers/`.
2. **Deploy Configuration**:

   ```sh
   just switch configuration="desktop-pc"
   ```

3. **Verify Startup Randomization**:
   - Log out and log back in (or restart the desktop session).
   - Confirm Noctalia displays a wallpaper chosen randomly from `~/Pictures/wallpapers`.
   - If the directory has no images, confirm Noctalia renders the Nord `#2e3440` Polar Night background color.
4. **Verify On-Demand Shortcuts**:
   - Press `Mod+Shift+W`: verify Noctalia switches immediately to another random wallpaper.
   - Press `Mod+Ctrl+W`: verify Noctalia toggles the graphical wallpaper thumbnail panel.
