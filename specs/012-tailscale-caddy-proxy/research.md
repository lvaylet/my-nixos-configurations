# Technical Research: Secure Remote Service Exposure via Tailscale and Caddy

**Branch**: `feat-https-with-tailscale-and-caddy` | **Date**: 2026-10-14 | **Spec**: [spec.md](spec.md)

This document consolidates architectural decisions, rationale, best practices, and alternatives evaluated for exposing internal homelab services (Home Assistant and n8n) securely over Tailscale with Caddy-managed HTTPS.

---

## 1. TLS Certificate Provisioning: Caddy Native Tailscale Integration vs Manual / ACME

### Decision

Utilize Caddy's native Tailscale certificate provisioning integration enabled via NixOS option `services.tailscale.permitCertUid = "caddy"`.

```nix
# modules/services/tailscale.nix
services.tailscale = {
  enable = true;
  permitCertUid = "caddy";
};
```

In Caddy virtual host configurations, declare virtual hosts matching the machine's Tailscale domain name:

```nix
# modules/services/caddy.nix / service modules
services.caddy.virtualHosts."${config.networking.hostName}.${config.flake.vars.tailscaleDomain}" = {
  extraConfig = ''
    reverse_proxy 127.0.0.1:8123
  '';
};
```

### Rationale

- **Zero Configuration & Native Support**: Since version 2.5, Caddy automatically recognizes `.ts.net` hostnames. When a client requests an HTTPS connection for a `.ts.net` virtual host, Caddy fetches and renews certificates directly from the local `tailscaled` daemon socket via Tailscale's LocalAPI.
- **Public CA Trust**: Tailscale-issued certificates are genuine Let's Encrypt certificates for the tailnet domain. They are natively trusted by operating systems, iOS/Android mobile devices, and browsers without requiring custom root CA installation.
- **Security & Permissions**: Tailscale daemon restricts certificate access to authorized local users. Setting `services.tailscale.permitCertUid = "caddy"` sets `TS_PERMIT_CERT_UID=caddy` in the `tailscaled` service environment, granting unprivileged Caddy access to fetch certificates while preventing other unprivileged users on the host from accessing certificate keys.
- **Elimination of Self-Signed Warnings**: Replaces the previous `issuer internal` setup in `modules/services/n8n.nix`, which caused browser security warnings and broken WebSockets on unmanaged devices.

### Alternatives Considered

- **Internal Caddy CA (`tls { issuer internal }`)**: Previously used in `modules/services/n8n.nix`. Requires manual root CA certificate installation into client trust stores (Firefox, macOS keychain, Android system store, iOS profiles), which is cumbersome on mobile devices and causes security warnings in mobile apps like Home Assistant Companion.
- **ACME HTTP-01 / DNS-01 Challenges**: Requires either exposing port 80 to the public internet (violating the private mesh requirement) or configuring DNS API credentials (violating zero-secrets and requiring a custom public domain name). Tailscale native TLS requires neither.
- **Standalone `tailscale cert` Cron / Systemd Service**: Manually running `tailscale cert` via systemd timers to write certs to a shared directory. Inferior to Caddy's native integration, which handles certificate caching, renewal timing, and in-memory TLS handshakes automatically.

---

## 2. Service Addressing and Port Allocation Strategy

### Decision

Address services using dedicated virtual host endpoints under the machine's Tailscale fully qualified domain name (FQDN): `<hostname>.<tailnetDomain>`:

1. **Home Assistant**: Served on standard HTTPS port `443` (e.g. `https://homelab.<tailnet>.ts.net/`), reverse proxying to `127.0.0.1:8123`.
2. **n8n Workflow Automation**: Served on dedicated HTTPS port `5678` (e.g. `https://homelab.<tailnet>.ts.net:5678/`), reverse proxying to internal container port `127.0.0.1:5679`.

```text
External Client (Tailscale Mesh)
   │
   ├── https://homelab.tailnet.ts.net (port 443) ────────► Caddy ──► 127.0.0.1:8123 (Home Assistant)
   │
   └── https://homelab.tailnet.ts.net:5678 (port 5678) ──► Caddy ──► 127.0.0.1:5679 (n8n container)
```

### Rationale

- **Single Machine FQDN Constraint**: Tailscale MagicDNS assigns a single FQDN per node (`<hostname>.<tailnet>.ts.net`). Tailscale does not issue wildcard certificates (`*.homelab.<tailnet>.ts.net`) for single nodes.
- **Home Assistant Companion App Compatibility**: Home Assistant's official mobile app and web frontend function best on root URL paths (`/`) on standard port 443. This provides a clean URL (`https://homelab.<tailnet>.ts.net`) without specifying non-standard ports.
- **Port Conflict Resolution for Home Assistant**: Home Assistant container uses `--network=host` for local LAN mDNS and UPnP discovery, binding to host port 8123. By having Caddy terminate HTTPS on port 443 and proxy to `127.0.0.1:8123`, there is zero port conflict between Caddy and Home Assistant on the host. Local network users can still use `http://<lan-ip>:8123`, while remote users access `https://homelab.<tailnet>.ts.net`.
- **n8n Port Standard**: n8n container binds strictly to `127.0.0.1:5679`. Caddy listens on port 5678 with TLS, preserving the standard port 5678 expected by n8n webhooks and integrations without conflicting with standard port 443.
- **Rejection of Path-Based Multiplexing (`/homeassistant` vs `/n8n`)**: Both Home Assistant and n8n have complex static asset loaders, deep client-side routing, and WebSocket connections that frequently malfunction when mounted on sub-paths without extensive header rewrite rules and backend base-path configuration. Dedicated ports eliminate routing ambiguity.

### Alternatives Considered

- **Multiple Tailscale Daemons in Containers**: Running multiple `tailscaled` daemons in userspace networking mode to give each service a unique Tailscale IP/hostname. Adds heavy systemd service complexity, multiple auth keys, and excessive background resource usage. Rejected in favor of single-node multi-port Caddy routing.
- **Sub-path Routing on Port 443**: Multiplexing `/ha/` and `/n8n/` on port 443. Rejected due to asset loading failures and webhook routing conflicts in n8n.

---

## 3. WebSocket Streaming and Reverse Proxy Headers

### Decision

Configure Caddy `reverse_proxy` directives with standard streaming support and ensure backend services are configured to trust reverse proxy headers.

```caddy
reverse_proxy 127.0.0.1:8123 {
  # Caddy automatically forwards X-Forwarded-For, X-Forwarded-Proto,
  # and handles HTTP/1.1 Upgrade: websocket headers natively.
}
```

In Home Assistant's configuration (`configuration.yaml`), declare HTTP proxy trust:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 127.0.0.1
    - ::1
```

### Rationale

- **Caddy Native WebSocket Support**: Caddy's `reverse_proxy` handler detects `Upgrade: websocket` headers automatically and maintains full-duplex TCP streaming tunnels without custom configuration.
- **Home Assistant Proxy Enforcement**: Home Assistant incorporates security mechanisms that reject requests with `X-Forwarded-For` headers with HTTP 400 Bad Request unless the proxy IP is explicitly listed in `http.trusted_proxies`. Setting `127.0.0.1` and `::1` allows Caddy to proxy traffic securely while allowing Home Assistant to see the client's actual Tailscale IP address for security auditing and authentication logs.
- **n8n Native Header Handling**: n8n container is already configured with `N8N_PROTOCOL="https"` and `N8N_PORT="5678"`, which aligns with Caddy terminating HTTPS on port 5678 and forwarding requests to `127.0.0.1:5679`.

### Alternatives Considered

- **Disabling `use_x_forwarded_for` in Home Assistant**: Would cause Home Assistant to log all remote connections as originating from `127.0.0.1`, breaking IP-based rate limiting, geo-location, and audit logs. Rejected.

---

## 4. Dendritic Architecture and Configuration Options

### Decision

1. **Declare `tailscaleDomain` in `modules/core/vars.nix`**:
   Add a centralized repository option `config.flake.vars.tailscaleDomain` (type `lib.types.str`, default `"tailnet-2900.ts.net"` or configurable) to hold the Tailscale tailnet domain.
2. **Update `modules/services/tailscale.nix`**:
   Add `services.tailscale.permitCertUid = "caddy";` when Caddy is enabled, granting Caddy certificate fetching permissions.
3. **Update `modules/services/caddy.nix`**:
   Ensure Caddy opens ports 443 and 80 (or auto_https redirect), and retains state preservation for `/var/lib/caddy` under `/persistent`.
4. **Update `modules/services/home-automation.nix`**:
   Add Caddy virtualHost on port 443 for `${config.networking.hostName}.${config.flake.vars.tailscaleDomain}` proxying to `127.0.0.1:8123`. Open TCP port 443 in `networking.firewall.allowedTCPPorts`.
5. **Update `modules/services/n8n.nix`**:
   Update Caddy virtualHost for port 5678 from `":5678"` with `issuer internal` to `"${config.networking.hostName}.${config.flake.vars.tailscaleDomain}:5678"` leveraging native Tailscale TLS.

### Rationale

- **Constitutional Principle II (Dendritic Modularity)**: Host definitions (`modules/hosts/homelab.nix`) remain purely composable; they merely list `services.caddy`, `services.tailscale`, `services.home-automation`, and `services.n8n`. Each service declares its own proxy route and firewall ports.
- **Constitutional Principle IV (Zero Secrets)**: No certificates, private keys, or credentials are hardcoded in git. All TLS certificates are retrieved at runtime via Tailscale LocalAPI and stored in `/var/lib/caddy` which is preserved under `/persistent`.
- **Constitutional Principle I (Declarative State)**: Reboots of the ephemeral tmpfs root do not lose certificate caches or require renewed TLS handshakes with Tailscale CA servers.

---

## 5. Firewall and Interface Security

### Decision

Open TCP ports `443` and `5678` in the host firewall:

```nix
networking.firewall.allowedTCPPorts = [
  443   # Home Assistant HTTPS via Caddy
  5678  # n8n HTTPS via Caddy
  8123  # Home Assistant direct HTTP (local LAN)
];
```

Optionally bind or restrict Caddy virtual hosts if tailnet isolation is required, or rely on Tailscale's overlay networking where ports are reached via Tailscale IP addresses without public router forwarding.

### Rationale

- Home router does NOT forward external WAN ports `443` or `5678` to `homelab`. Therefore, the ports are unreachable from the public internet.
- Traffic arrives either over the local LAN (192.168.1.0/24) or over the Tailscale encrypted mesh interface (`tailscale0`).
- Because Caddy's virtual hosts are named `<host>.<tailnet>.ts.net`, only requests presenting the Tailscale SNI hostname are answered with the valid certificate.
