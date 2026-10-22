# Darwin Host Contract: `macbook-air-m4-15`

**Feature**: `021-integrate-macbook-air`
**Contract Version**: 1.0.0
**Scope**: Declaration, builder interface, and output specification for macOS hosts

---

## 1. Flake Output Specification

The repository flake MUST expose the Darwin configuration under `flake.darwinConfigurations`:

```nix
flake.darwinConfigurations.macbook-air-m4-15 = config.flake.lib.mkDarwinHost {
  system = "aarch64-darwin";
  features = with config.flake.modules; [
    # Base Settings
    core.base
    core.git
    core.neovim

    # Desktop & Shell
    desktop.apps
    desktop.editors
    desktop.fonts
    desktop.shell
    desktop.terminal

    # Services
    services.ssh
  ];
  extraModules = [
    {
      networking.hostName = "macbook-air-m4-15";
    }
  ];
};
```

---

## 2. Builder Specification: `mkDarwinHost`

The helper function in `modules/core/lib.nix` MUST adhere to the following interface:

### Signature

```nix
mkDarwinHost = {
  system ? "aarch64-darwin",
  features ? [],
  extraModules ? [],
  enableHomeManager ? true,
}: ...
```

### Module Extraction Rules

1. **Darwin System Modules**:
   Extract all `f.darwin` elements from attribute sets `f` in `features` where `f ? darwin`.
2. **Home Manager Modules**:
   Extract all `f.homeManager` elements from attribute sets `f` in `features` where `f ? homeManager`.
3. **Special Arguments**:
   Inject `{ inherit inputs; outputs = config.flake; vars = config.flake.vars; }` into both Darwin and Home Manager module evaluation contexts.
4. **Home Manager Darwin Integration**:
   When `enableHomeManager = true`, import `inputs.home-manager.darwinModules.home-manager`, configure `useGlobalPkgs = true`, `useUserPackages = true`, and apply user modules to `users.${config.flake.vars.userName}`.

---

## 3. Host System Defaults on Darwin

The `core.base.darwin` module MUST configure:

- **Nix Daemon**: Flakes and nix-command enabled, trusted users including `root` and `${vars.userName}`.
- **Garbage Collection**: Weekly automated cleanup.
- **Security**: PAM Touch ID authentication for `sudo` operations (`security.pam.enableSudoTouchIdAuth = true`).
- **User Record**: Account name matching `vars.userName`, home directory at `/Users/${vars.userName}`.
