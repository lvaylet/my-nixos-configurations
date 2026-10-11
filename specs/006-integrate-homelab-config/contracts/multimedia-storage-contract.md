# Interface Contract: Multimedia Storage & Permission Coordination

**Branch**: `006-integrate-homelab-config` | **Date**: 2026-10-10 | **Spec**: [spec.md](../spec.md)

This contract defines the permission structure, service account coordination, and systemd tmpfiles enforcement rules for shared multimedia storage across downloading, file management, and media streaming services.

---

## 1. Group & User Schema

All multimedia services and directories MUST adhere to fixed POSIX identifiers:

```nix
users = {
  groups = {
    multimedia = {
      gid = 995; # Fixed GID across boots
    };
    qbittorrent = {};
    filebrowser = {};
  };

  users = {
    qbittorrent = {
      isSystemUser = true;
      uid = 991;
      group = "qbittorrent";
    };
    filebrowser = {
      isSystemUser = true;
      uid = 992;
      group = "filebrowser";
    };
  };
};
```

---

## 2. Directory Layout & Inheritance Invariants

Shared media directories reside under `/data` and MUST be configured with the SetGID bit (`2775`) so all files created within them automatically inherit the `multimedia` group:

| Directory | Owner | Group | Mode | Description |
|---|---|---|---|---|
| `/data` | `root` | `multimedia` | `0775` | Root media container |
| `/data/downloads` | `qbittorrent` | `multimedia` | `2775` | Incoming and completed downloads |
| `/data/media` | `filebrowser` | `multimedia` | `2775` | Curated library organized by Filebrowser |

---

## 3. Systemd Tmpfiles Invariant (Mop-Up Type `z`)

To prevent mount-time race conditions on an impermanent system, directory permission enforcement MUST use rule type `z` instead of `d`:

```nix
systemd.tmpfiles.rules = [
  # Type Path              Mode User         Group      Age Argument
  "z     /data           0775 root         multimedia -"
  "z     /data/downloads 2775 qbittorrent  multimedia -"
  "z     /data/media     2775 filebrowser  multimedia -"
];
```

*Invariant*: Type `z` rules act only after the path exists (post-preservation mount) without prematurely creating paths before preservation bind mounts are initialized.
