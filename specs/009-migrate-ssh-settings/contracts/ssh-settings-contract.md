# Interface Contract: SSH Client Configuration Settings

**Branch**: `009-migrate-ssh-settings` | **Date**: 2026-10-12 | **Spec**: [spec.md](../spec.md)

This contract defines the schema, types, and serialization behavior for the Home Manager `programs.ssh.settings` interface within `modules/services/ssh.nix`.

---

## 1. Nix Module Input Contract (`modules/services/ssh.nix`)

The `homeManager` section of `flake.modules.services.ssh` MUST declare:

```nix
homeManager = _: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "homelab" = {
        HostName = "192.168.1.180";
        User = "laurent";
        IdentityFile = "~/.ssh/id_ed25519";
        CheckHostIP = false;
      };
    };
  };
};
```

### Invariants:
1. `programs.ssh.matchBlocks` MUST NOT be declared or referenced.
2. `programs.ssh.enableDefaultConfig` MUST remain `false`.
3. Keys within `programs.ssh.settings` MUST be bare host alias strings.
4. Attributes inside host blocks MUST use canonical OpenSSH PascalCase naming (`HostName`, `User`, `IdentityFile`, `CheckHostIP`).

---

## 2. OpenSSH Client Output Contract (`~/.ssh/config`)

Home Manager serializes `programs.ssh.settings` to `~/.ssh/config` adhering to standard OpenSSH client syntax:

```text
Host homelab
  CheckHostIP no
  HostName 192.168.1.180
  IdentityFile ~/.ssh/id_ed25519
  User laurent
```

### Invariants:
1. **Header Format**: `Host <alias>` opens each block.
2. **Indentation**: Directives indented by two spaces (`  `).
3. **Boolean Rendering**: `CheckHostIP = false` renders as `CheckHostIP no`.
4. **Behavioral Equivalence**: All outgoing connections via `ssh homelab` resolve to the configured IP address (`192.168.1.180`), username (`laurent`), identity key, and host IP check settings.

---

## 3. Evaluation Diagnostics Contract

Running any flake evaluation command:
- `nix eval .#nixosConfigurations.desktop-pc.config.system.build.toplevel.drvPath`
- `nix flake check`
- `just check`

MUST NOT produce stderr matching:
`evaluation warning: .* `programs.ssh.matchBlocks` .* is deprecated. Use `programs.ssh.settings`.`
