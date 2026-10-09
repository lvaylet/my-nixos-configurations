# Interface Contract: Flake Outputs

**Branch**: `005-migrate-dendritic-pattern` | **Date**: 2026-10-09 | **Spec**: [spec.md](../spec.md)

This contract defines the public outputs exposed by `flake.nix` and `flake-parts` for external tooling (`nix`, `nh`, `just`, GitHub Actions).

---

## 1. Schema & Outputs Structure

```nix
{
  # NixOS machine closures & installer media
  nixosConfigurations = {
    desktop-pc = <derivation: nixosSystem>;
    homelab = <derivation: nixosSystem>;
    iso = <derivation: nixosSystem>;
  };

  # Multi-system hermetic pre-commit checks
  checks.${system} = {
    pre-commit-check = <derivation: git-hooks>;
  };

  # Flake formatter invoked by `nix fmt`
  formatter.${system} = <derivation: pre-commit-run wrapper>;

  # Development shells invoked by `nix develop`
  devShells.${system} = {
    default = <derivation: mkShell with just, nh, pre-commit>;
  };

  # Exposed reusable library functions & modules
  lib = {
    mkHost = <function>;
  };

  # Reusable lower-level module definitions
  modules = {
    # Categorized features
  };
}
```

---

## 2. Supported Systems

The multi-system outputs (`checks`, `formatter`, `devShells`) MUST evaluate for all target systems:
- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

---

## 3. Backward Compatibility Requirements

1. **`justfile` Commands**:
   - `just build configuration="desktop-pc"` -> builds `.nixosConfigurations.desktop-pc.config.system.build.toplevel`
   - `just build configuration="homelab"` -> builds `.nixosConfigurations.homelab.config.system.build.toplevel`
   - `just build-iso` -> builds `.nixosConfigurations.iso.config.system.build.isoImage`
   - `just check` -> runs `nix flake check`
   - `just fmt` -> runs `nix fmt .`
   - `just lint` -> runs `deadnix` and `statix check`
2. **CI Pipeline Compatibility**:
   - GitHub Actions workflow (`.github/workflows/ci.yml`) executes `nix flake check`. It MUST pass without configuration changes.
