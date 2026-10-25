# Data Model & Configuration Schemas: OpenCode v2 on Homelab

**Feature Branch**: `022-add-opencode-homelab` | **Date**: 2026-10-25

## 1. Core Entities & Schemas

### Entity 1: OpenCode Mutualized Configuration (`OpenCodeConfig`)

Represents the centralized, declarative configuration shared across workstations (`desktop-pc`, `macbook-air-m4-15`) and `homelab`.

| Attribute | Type | Description | Default / Value | Invariant / Validation |
| --- | --- | --- | --- | --- |
| `package` | Package derivation | The OpenCode v2 executable package | `inputs.opencode.packages.${system}.opencode` | Must be OpenCode v2.x derivation supporting host system architecture. |
| `theme` | String | Terminal / TUI visual theme | `"nord"` | Must match a valid OpenCode theme identifier (`nord`). |
| `settings` | Attribute Set | Global user settings for OpenCode | `{}` (or standard defaults) | Valid JSON-serializable structure conforming to OpenCode configuration schema. |
| `enableMcpIntegration` | Boolean | Whether to enable Model Context Protocol servers | `true` | Must be a boolean value. |

**State Transitions**:

- *Defined in `modules/services/opencode.nix`* -> Evaluated by `flake-parts` -> Rendered as Home Manager `programs.opencode` on `desktop-pc`/`macbook-air-m4-15` OR rendered via `systemd.tmpfiles.rules` on `homelab`.

---

### Entity 2: OpenCode Web Service Daemon (`OpenCodeDaemon`)

Represents the headless systemd service running `opencode serve` on `homelab`.

| Attribute | Type | Description | Target Value | Constraints / Invariant |
| --- | --- | --- | --- | --- |
| `serviceName` | String | Systemd unit name | `"opencode-web"` | Must match `systemd.services.opencode-web`. |
| `executable` | Path | OpenCode binary path | `${opencodePackage}/bin/opencode` | Must be an executable Nix store path. |
| `commandArgs` | List of Strings | Command arguments for headless serve | `[ "serve" "--hostname" "127.0.0.1" "--port" "4096" ]` | Loopback binding `127.0.0.1` strictly enforced; port `4096`. |
| `workingDirectory` | Path | State directory for database and storage | `"/var/lib/opencode"` | Must be durable path managed by systemd `StateDirectory`. |
| `user` | String | System user executing daemon | `"opencode"` | Dedicated non-privileged system user. |
| `group` | String | System group | `"opencode"` | Dedicated system group. |
| `environmentFile` | Path | Runtime environment credentials file | `"/var/lib/opencode/opencode.env"` | Mode `0600`, contains `OPENCODE_SERVER_PASSWORD`. |
| `restartPolicy` | String | Service recovery policy | `"always"` | Restarts within 5 seconds on abnormal exit. |

**State Lifecycle**:

```text
[Inactive / Boot]
       │
       ▼ (systemd start)
[Pre-Start Validation] ──(Missing opencode.env?)──► [Generate secure random password]
       │
       ▼
[Active: Running opencode serve on 127.0.0.1:4096]
       │
       ├─► (Crash / Failure) ──► [Wait 5s] ──► [Restarting]
       │
       ▼ (systemd stop / reboot)
[Graceful Shutdown (SIGTERM)]
```

---

### Entity 3: Reverse Proxy Virtual Host (`CaddyVHost`)

Represents the Caddy reverse proxy endpoint exposing the OpenCode web interface securely over HTTPS.

| Attribute | Type | Description | Value | Invariant |
| --- | --- | --- | --- | --- |
| `hostname` | String | Fully qualified public domain name | `opencode.${vars.homelabDomain}` (`opencode.homelab.vaylet.fr`) | Must match user specification exactly. |
| `upstream` | String | Local loopback target | `"127.0.0.1:4096"` | Matches `OpenCodeDaemon` loopback listener. |
| `tlsProvider` | String | ACME automated certificate provider | Cloudflare DNS-01 | Managed by centralized Caddy module. |
| `httpPort` | Integer | Standard plaintext HTTP port | `80` (auto-redirect to `443`) | Plaintext access permanently redirected. |
| `httpsPort` | Integer | Standard encrypted HTTPS port | `443` | Allowed in firewall. |

---

### Entity 4: Persistent Storage Mapping (`StoragePreservation`)

Represents persistent path declarations ensuring impermanence compatibility on `homelab`.

| Source Path | Persistent Storage Path | Owner | Mode | Content / Role |
| --- | --- | --- | --- | --- |
| `/var/lib/opencode` | `/persistent/var/lib/opencode` | `opencode:opencode` | `0750` | OpenCode SQLite database, project workspaces, session history, and `opencode.env`. |
| `/home/laurent/.config/opencode` | Symlinked or preserved in user home | `laurent:users` | `0755` | Declarative `opencode.json` configuration file. |

---

## 2. Invariants & Validation Rules

1. **Port Exclusivity**: Port `4096` must not conflict with any other declared service in `modules/services/*.nix`.
2. **Loopback Isolation**: The daemon MUST NOT listen on `0.0.0.0` or public network interfaces; all external traffic MUST route through Caddy reverse proxy on port 443.
3. **Secret Hygiene**: Plaintext passwords MUST NEVER appear in Nix expressions, Nix store paths, or Git commits. The password file MUST have file mode `0600` and be owned by `opencode:opencode`.
4. **Theme Consistency**: All target machines (`desktop-pc`, `macbook-air-m4-15`, `homelab`) MUST evaluate the exact same visual theme (`"nord"`) for OpenCode.
