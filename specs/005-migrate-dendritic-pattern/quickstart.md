# Quickstart & Validation Guide: Dendritic Pattern Migration

**Branch**: `005-migrate-dendritic-pattern` | **Date**: 2026-10-09 | **Spec**: [spec.md](spec.md)

This guide documents the procedures for testing, evaluating, and verifying the dendritic migration end-to-end across all target machines and multi-system outputs.

---

## 1. Prerequisites

- Nix with flakes enabled (or `devbox`)
- Git repository working tree clean and up to date

---

## 2. Validation Scenarios

### Scenario 1: Flake Syntax, Module Discovery & Static Analysis
Verify that `import-tree` successfully crawls the `modules/` tree, all modules are well-formed `flake-parts` modules, and all static linters pass.

```sh
# 1. Format all Nix files
just fmt

# 2. Run static analysis (dead code detection and linting)
just lint

# 3. Run hermetic sandbox checks (flake-checker, alejandra, statix, secrets, git-hooks)
just check
```

**Expected Outcome**:
- `just fmt` applies `alejandra` formatting across all `.nix` files with 0 syntax errors.
- `just lint` (`statix` and `deadnix`) reports 0 warnings and 0 errors.
- `just check` (`nix flake check`) passes with exit code 0.

---

### Scenario 2: Target Closure Evaluation & Dry-Run Build
Verify that all host configurations (`desktop-pc`, `homelab`, `iso`) evaluate cleanly and can build system closures.

```sh
# 1. Build desktop-pc system closure
just build configuration="desktop-pc"

# 2. Build homelab server closure
just build configuration="homelab"

# 3. Build bootable installer ISO
just build-iso
```

**Expected Outcome**:
- Each command completes successfully with exit code 0.
- Resulting Nix store paths are valid NixOS top-level system closures and ISO images.

---

### Scenario 3: Non-Destructive Live Test Activation (Workstation)
Verify that the `desktop-pc` configuration activates safely in test mode without modifying the bootloader.

```sh
# Temporarily activate desktop configuration
just test configuration="desktop-pc"
```

**Expected Outcome**:
- System services activate cleanly without conflict or regression.
- User desktop environment (Niri + Noctalia) operates normally.

---

### Scenario 4: Automated Feature Discovery Test
Verify that adding a new feature file to `modules/` is automatically discovered by `import-tree` without editing `flake.nix`.

```sh
# 1. Create a dummy test feature
cat << 'EOF' > modules/services/test-feature.nix
{
  flake.modules.services.test-feature = {
    nixos = {
      environment.variables.TEST_DENDRITIC = "1";
    };
  };
}
EOF

# 2. Evaluate flake outputs
nix eval .#nixosConfigurations.desktop-pc.config.environment.variables.TEST_DENDRITIC

# 3. Clean up test feature
rm modules/services/test-feature.nix
```

**Expected Outcome**:
- Step 2 successfully evaluates and prints `"1"` without any modifications to `flake.nix`.

---

## 3. Related Artifacts

- [Feature Specification](spec.md)
- [Technical Research](research.md)
- [Data Model & Entities](data-model.md)
- [Flake Outputs Contract](contracts/flake-outputs-contract.md)
- [Feature Module Contract](contracts/feature-module-contract.md)
- [Host Composition Contract](contracts/host-composition-contract.md)
