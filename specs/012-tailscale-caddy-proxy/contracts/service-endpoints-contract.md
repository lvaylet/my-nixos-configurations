# Interface Contract: Service Proxy Endpoints

**Branch**: `feat-https-with-tailscale-and-caddy` | **Date**: 2026-10-14 | **Spec**: [spec.md](../spec.md)

This contract defines the network endpoints, reverse proxy routing definitions, firewall allocations, and proxy trust settings for Home Assistant and n8n on `*.homelab.vaylet.fr`.

---

## 1. Home Assistant Proxy Contract (`modules/services/home-automation.nix`)

The Home Assistant service module MUST declare reverse proxy routing for its web interface on `ha.${vars.homelabDomain}` (`ha.homelab.vaylet.fr`) on standard HTTPS port 443:

```nix
# In modules/services/home-automation.nix
services.caddy = {
  enable = true;
  virtualHosts."ha.${vars.homelabDomain}" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:8123
    '';
  };
};

networking.firewall.allowedTCPPorts = [
  443   # Home Assistant HTTPS via Caddy
  8123  # Home Assistant HTTP direct access (local LAN)
];
```

### Upstream Proxy Trust Invariant

In Home Assistant (>= 2026.10), reverse proxy trust is configured via the Web UI (**Settings** > **System** > **Network**):

- **Use reverse proxy**: Enabled
- **Trusted proxies**: `127.0.0.1` and `::1`
(The legacy `http:` YAML block in `configuration.yaml` is deprecated and ignored).

### Behavioral Guarantees

- Remote clients accessing `https://ha.homelab.vaylet.fr` connect to port 443 with a valid Let's Encrypt TLS certificate.
- Caddy reverse-proxies requests to Home Assistant at `127.0.0.1:8123`.
- Long-lived WebSocket connections (`/api/websocket`) for real-time dashboard events are sustained without disconnect timeouts.
- Local LAN devices can continue connecting directly to `http://<lan-ip>:8123`.

---

## 2. n8n Workflow Automation Proxy Contract (`modules/services/n8n.nix`)

The n8n service module MUST declare reverse proxy routing for its web interface and webhook endpoints on `n8n.${vars.homelabDomain}` (`n8n.homelab.vaylet.fr`) on standard HTTPS port 443:

```nix
# In modules/services/n8n.nix
virtualisation.oci-containers.containers.n8n = {
  # ...
  ports = [
    # Bind strictly to localhost loopback:
    "127.0.0.1:5679:5678"
  ];
  environment = {
    # ...
    WEBHOOK_URL = "https://n8n.${vars.homelabDomain}/";
  };
};

services.caddy = {
  enable = true;
  virtualHosts."n8n.${vars.homelabDomain}" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:5679
    '';
  };
};

networking.firewall.allowedTCPPorts = [
  443  # Caddy HTTPS
];
```

### Behavioral Guarantees

- Remote clients accessing `https://n8n.homelab.vaylet.fr` connect to port 443 with a valid Let's Encrypt TLS certificate.
- Unencrypted n8n HTTP traffic on container port 5678 is bound strictly to `127.0.0.1:5679` and is never exposed directly on physical or VPN network interfaces.
- Incoming webhook triggers and REST API calls preserve original client headers (`X-Forwarded-For`, `X-Forwarded-Proto`).
- Inbound TCP port 443 is permitted through the host firewall.

---

## 3. Extensibility Guidelines for Future Homelab Services

To expose any additional internal service (such as `filebrowser`, `jellyfin`, or `portainer`) through Caddy on dedicated subdomains:

1. **Colocate in the Service Feature Module**:
   - Define the `services.caddy.virtualHosts` declaration directly within `modules/services/<service>.nix`.
   - Never add inline reverse proxy definitions to `modules/hosts/homelab.nix` (Constitutional Principle II).

2. **Access Domain Identity**:
   - Accept `vars` in the module parameter list (`{ config, lib, vars, ... }:`) and reference `vars.homelabDomain`.

3. **Port & Routing Scheme**:
   - Address the endpoint via `"<service>.${vars.homelabDomain}"` on port 443.
   - Proxy to loopback `127.0.0.1:<internalPort>`.
   - Caddy automatically requests Let's Encrypt certificates using the global Cloudflare DNS-01 ACME policy.

4. **Firewall Declaration**:
   - Ensure port 443 is open in `networking.firewall.allowedTCPPorts`.

5. **Loopback Isolation**:
   - For containerized services, ensure container port mappings bind strictly to `127.0.0.1` so unencrypted plaintext traffic cannot be intercepted on physical or VPN network interfaces.
