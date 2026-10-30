# Data Model: Secure Remote Service Exposure via Tailscale and Caddy

**Branch**: `feat-https-with-tailscale-and-caddy` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

This document formalizes the entities, configuration schemas, attributes, relationships, and validation constraints for exposing Home Assistant and n8n over Tailscale with Caddy-managed HTTPS.

---

## 1. Entities & Configuration Schemas

### Entity 1: Tailnet Identity Variable (`modules/core/vars.nix`)

Represents the declarative repository-wide configuration option that defines the base Tailscale tailnet domain.

| Option / Attribute | Type | Default Value | Description |
|---|---|---|---|
| `config.flake.vars.tailscaleDomain` | `lib.types.str` | `"tailnet-2900.ts.net"` | Base Tailscale domain name used to assemble host FQDNs (`<hostname>.<tailscaleDomain>`) |

#### Relationships

- **Referenced by**: `modules/services/home-automation.nix` and `modules/services/n8n.nix` to construct fully qualified domain names for Caddy virtual hosts without string duplication or host-level boilerplate.

---

### Entity 2: Tailscale TLS Authorization (`modules/services/tailscale.nix`)

Represents the Tailscale service configuration granting the reverse proxy daemon permission to fetch TLS certificates via the local daemon socket.

| Option / Attribute | Value | Description |
|---|---|---|
| `services.tailscale.enable` | `true` | Enables the Tailscale daemon |
| `services.tailscale.permitCertUid` | `"caddy"` | Authorizes the `caddy` system user to request TLS certificates via LocalAPI |

#### Invariants & Validation

- Whenever Caddy is deployed alongside Tailscale, `services.tailscale.permitCertUid` MUST equal `"caddy"`.

---

### Entity 3: Central Caddy Reverse Proxy & Persistence (`modules/services/caddy.nix`)

Represents the base reverse proxy daemon configuration, systemd startup ordering, and state preservation.

| Option / Attribute | Value / Schema | Purpose |
|---|---|---|
| `services.caddy.enable` | `true` | Central reverse proxy service |
| `services.caddy.globalConfig` | String (`auto_https disable_redirects\nskip_install_trust`) | Disables automatic HTTP-to-HTTPS redirect port binding conflicts and skips read-only root CA installation |
| `systemd.services.caddy.after` | `[ "local-fs.target" "tailscaled.service" ]` | Ensures persistent storage is mounted and the Tailscale daemon is running before Caddy initiates certificate retrieval |
| `preservation.preserveAt."/persistent".directories` | `[ { directory = "/var/lib/caddy"; user = "caddy"; group = "caddy"; mode = "0750"; } ]` | Persists acquired Tailscale TLS certificates, keys, and ACME cache across ephemeral root reboots |

---

### Entity 4: Home Assistant Proxy Endpoint (`modules/services/home-automation.nix`)

Represents the reverse proxy configuration exposing Home Assistant on port 443 of the host's Tailscale domain.

| Option / Attribute | Value / Schema | Purpose |
|---|---|---|
| `services.caddy.virtualHosts."${config.networking.hostName}.${config.flake.vars.tailscaleDomain}"` | Submodule | Virtual host on standard HTTPS port 443 |
| `...extraConfig` | `'reverse_proxy 127.0.0.1:8123'` | Proxies HTTPS traffic to internal Home Assistant instance, handling WebSockets automatically |
| `networking.firewall.allowedTCPPorts` | `[ 443 8123 ]` | Opens port 443 for HTTPS proxy traffic and retains port 8123 for direct local LAN traffic |
| Container Configuration (`configuration.yaml`) | `http.use_x_forwarded_for: true`, `http.trusted_proxies: [ "127.0.0.1", "::1" ]` | Prevents HTTP 400 Bad Request errors when receiving proxied requests |

---

### Entity 5: n8n Workflow Automation Proxy Endpoint (`modules/services/n8n.nix`)

Represents the reverse proxy configuration exposing n8n on port 5678 of the host's Tailscale domain.

| Option / Attribute | Value / Schema | Purpose |
|---|---|---|
| `services.caddy.virtualHosts."${config.networking.hostName}.${config.flake.vars.tailscaleDomain}:5678"` | Submodule | Virtual host on dedicated HTTPS port 5678 |
| `...extraConfig` | `'reverse_proxy 127.0.0.1:5679'` | Proxies HTTPS traffic to the internal container binding |
| `virtualisation.oci-containers.containers.n8n.ports` | `[ "127.0.0.1:5679:5678" ]` | Container binds strictly to loopback interface on internal port 5679 |
| `networking.firewall.allowedTCPPorts` | `[ 5678 ]` | Opens port 5678 for HTTPS proxy traffic |

---

### Entity 6: Certificate Storage Layout (`/persistent/var/lib/caddy`)

Represents the on-disk directory structure managed by Caddy where Tailscale TLS certificates and metadata reside.

```text
/persistent/var/lib/caddy/
├── .config/
│   └── caddy/
│       └── autosave.json
└── .local/
    └── share/
        └── caddy/
            ├── certificates/
            │   └── local/ (or tailscale domain directory)
            │       ├── <host>.<tailnet>.ts.net.crt
            │       └── <host>.<tailnet>.ts.net.key
            └── locks/
```

| Path | Type | Owner:Group | Mode | Persistence Requirement |
|---|---|---|---|---|
| `/var/lib/caddy` | Directory | `caddy:caddy` | `0750` | Preserved at `/persistent/var/lib/caddy` |
| `/var/lib/caddy/.local` | Directory | `caddy:caddy` | `0700` | Contains certificate cache |

---

## 2. Invariants & Business Rules

1. **Constitutional Modularity Invariant**: No inline reverse proxy routing logic may appear in `modules/hosts/homelab.nix`. Each service module (`modules/services/home-automation.nix`, `modules/services/n8n.nix`) MUST declare its own Caddy virtual host and firewall rules.
2. **Permission Invariant**: `services.tailscale.permitCertUid` MUST be configured whenever Caddy is enabled on a host with Tailscale, ensuring Caddy has access to `tailscaled.sock`.
3. **Loopback Isolation Invariant**: Backend services that do not require raw LAN exposure (such as the n8n container) MUST bind strictly to `127.0.0.1` so unencrypted traffic cannot be intercepted from other network interfaces.
4. **Proxy Trust Invariant**: Upstream services behind Caddy that inspect client IP addresses (such as Home Assistant) MUST be configured with `trusted_proxies` containing loopback addresses (`127.0.0.1` and `::1`).
5. **Startup Ordering Invariant**: `systemd.services.caddy.after` MUST include `tailscaled.service` to prevent race conditions during boot when Caddy attempts to acquire certificates.
