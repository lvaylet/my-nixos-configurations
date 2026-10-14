# Feature Specification: Secure Remote Service Exposure via Tailscale and Caddy

**Feature Branch**: `feat-https-with-tailscale-and-caddy`

**Created**: 2026-10-14

**Status**: Draft

**Input**: User description: "Je souhaite exposer les services comme Home Assistant et n8n de manière sécurisée à l'extérieur du réseau local de mon domicile grâce à Tailscale, avec HTTPS géré par Caddy. La documentation officielle de Tailscale sur NixOS explique comment combiner Tailscale et Caddy : https://wiki.nixos.org/wiki/Tailscale#Configuring_TLS"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Secure Remote Access to Home Automation (Priority: P1)

As a home network user away from home, I want to access my Home Assistant dashboard securely from my smartphone or laptop through the private mesh network with valid HTTPS encryption, so that I can monitor and control home automation devices safely without exposing any open ports on my home internet router.

**Why this priority**: Core value of the feature; provides secure, encrypted, and trusted remote home management while maintaining strong privacy and zero public attack surface.

**Independent Test**: Connect a client device (laptop or phone) to the private mesh network while outside the local home network (e.g. over cellular data), open the designated Home Assistant HTTPS URL in a web browser or native app, and confirm that the interface loads with a trusted TLS connection (zero security warnings) and device states update in real time.

**Acceptance Scenarios**:

1. **Given** an authorized client connected to the private mesh network, **When** the user accesses the secure Home Assistant endpoint, **Then** the application interface loads over HTTPS with a trusted certificate and enables real-time device control.
2. **Given** an active Home Assistant dashboard session over the secure mesh connection, **When** real-time entity updates occur, **Then** bi-directional WebSocket connections remain stable and stream state changes without disconnection or polling errors.
3. **Given** an unauthorized device or any connection attempt from the public internet without mesh network credentials, **When** attempting to reach the service endpoint, **Then** the connection is completely unreachable and rejected.

---

### User Story 2 - Secure Remote Access to Workflow Automation (Priority: P1)

As an automation administrator away from home, I want to access the n8n automation interface securely with valid HTTPS encryption over the private mesh network, so that I can design, monitor, and execute automated workflows without exposing administration interfaces or API credentials to the public internet.

**Why this priority**: Core requirement for remote administration and monitoring of homelab workflows while ensuring sensitive third-party credentials and integration webhooks remain protected.

**Independent Test**: Connect to the private mesh network from an external network, navigate to the n8n secure URL in a browser, log in, execute an automated workflow, and verify that execution results and node data stream in real time over a valid HTTPS connection.

**Acceptance Scenarios**:

1. **Given** an authorized administrator on the private mesh network, **When** accessing the workflow automation URL over HTTPS, **Then** the application loads with a valid, trusted TLS certificate and allows full workflow creation, editing, and execution inspection.
2. **Given** an authorized webhook or API request sent to the automation service through the mesh network, **When** the request arrives over HTTPS, **Then** the service accepts the request, validates the payload, and executes the designated workflow.
3. **Given** an unauthenticated connection attempt from outside the mesh network, **When** reaching the automation service port, **Then** traffic is blocked at the network firewall.

---

### User Story 3 - Automated and Trusted TLS Certificate Lifecycle (Priority: P1)

As a homelab administrator, I want TLS certificates for all proxied services to be provisioned and renewed automatically through the reverse proxy and mesh network integration, so that all browser sessions and client applications maintain valid cryptographic trust without manual certificate generation or recurring maintenance.

**Why this priority**: Eliminates security warnings in browsers and mobile applications (e.g. Home Assistant Companion app), ensures end-to-end encryption in transit, and eliminates manual certificate rotation overhead.

**Independent Test**: Inspect the TLS certificate chain presented by the reverse proxy on all exposed service endpoints using a browser or command-line diagnostic tool, confirming that the certificate is cryptographically valid, matches the host's private mesh domain name, and is automatically maintained across service restarts.

**Acceptance Scenarios**:

1. **Given** the reverse proxy and mesh network services are operational, **When** a client establishes an HTTPS connection to a proxied service, **Then** the reverse proxy presents a trusted TLS certificate matching the node's mesh domain name without requiring manual certificate installation on the client.
2. **Given** an active certificate approaching its renewal window, **When** the certificate reaches the renewal threshold, **Then** the reverse proxy automatically acquires an updated certificate without service interruption or administrative intervention.
3. **Given** the host reboots, **When** system services start up, **Then** previously acquired certificates in persistent storage are reused immediately, avoiding redundant re-issuance requests or startup delays.

---

### User Story 4 - Standardized and Extensible Service Proxying (Priority: P2)

As a homelab maintainer, I want a standardized reverse proxy architecture that makes it straightforward to securely expose additional internal homelab services in the future, so that all internal web applications follow consistent encryption, security headers, and access control policies.

**Why this priority**: Ensures long-term maintainability, prevents duplicated reverse proxy configurations across services, and provides a clear architectural pattern for future homelab applications.

**Independent Test**: Configure a new internal web application to be exposed through the reverse proxy, apply the configuration, and confirm that the new application becomes accessible over HTTPS with a valid certificate and proper header forwarding.

**Acceptance Scenarios**:

1. **Given** an internal service running on a local port or container, **When** declared for exposure through the reverse proxy, **Then** it automatically receives HTTPS termination, mesh domain routing, and trusted proxy header forwarding.
2. **Given** an internal service receiving requests via the reverse proxy, **When** processing incoming connections, **Then** client connection metadata (source IP, protocol, host) is accurately forwarded to the backend service.

---

### Edge Cases

- **Transient Connectivity Loss During Certificate Provisioning**: When coordination servers or certificate authorities are temporarily unreachable at startup, the reverse proxy must continue serving valid cached certificates and retry provisioning in the background without crashing.
- **Persistent Storage and Ephemeral Root Reboots**: On hosts using ephemeral root filesystems, certificate caches, reverse proxy state, and cryptographic material must be retained in persistent storage to prevent certificate re-issuance rate limits upon reboot.
- **Long-Lived Streaming Connections**: Reverse proxy timeouts and buffering must accommodate persistent WebSocket connections used by Home Assistant and real-time execution feedback in n8n without dropping idle connections.
- **Direct Unencrypted HTTP Requests**: If a client attempts an unencrypted HTTP connection to a service endpoint, the system must automatically upgrade the request to HTTPS or reject it cleanly without exposing plaintext data.
- **Large Payload and Backup Transfers**: The reverse proxy configuration must support large file uploads (such as Home Assistant backup archives or n8n binary data workflows) without failing prematurely due to default request body size limits.
- **Host Firewall and Network Interface Binding**: The reverse proxy must bind properly to the private mesh network interface while preventing unauthorized access from untrusted external interfaces.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide reverse proxy routing for Home Assistant and n8n to allow secure remote access over the private Tailscale mesh network.
- **FR-002**: The system MUST terminate TLS and serve all exposed services exclusively over HTTPS using valid certificates issued for the host's Tailscale domain name.
- **FR-003**: The reverse proxy MUST integrate with the local Tailscale service to automatically fetch, manage, and renew trusted TLS certificates without manual administrator intervention.
- **FR-004**: The system MUST restrict external service access strictly to authorized devices participating in the private mesh network, requiring zero inbound port forwarding on the home router.
- **FR-005**: The reverse proxy MUST support persistent, bi-directional WebSocket connections to enable real-time UI updates and state streaming for Home Assistant and n8n.
- **FR-006**: The reverse proxy MUST forward standard client headers (including original client IP, host, and protocol) to upstream backend services.
- **FR-007**: Home Assistant MUST be configured to recognize the reverse proxy as a trusted forwarding proxy, enabling correct client IP identification and preventing HTTP 400 Bad Request errors.
- **FR-008**: All TLS certificates, private keys, and reverse proxy operational state MUST be stored in persistent storage to survive host reboots and ephemeral root storage rollbacks.
- **FR-009**: The reverse proxy service MUST start automatically upon system boot after network connectivity and persistent storage targets are fulfilled.
- **FR-010**: The reverse proxy configuration MUST follow a modular architecture within the services domain, allowing individual services to declare their proxy routing cleanly and declaratively.
- **FR-011**: The system MUST open the necessary service ports on the host firewall to allow incoming traffic from the private mesh network.
- **FR-012**: If an unencrypted HTTP connection is attempted on an exposed port, the system MUST redirect the connection to HTTPS.

### Key Entities

- **Proxied Service Endpoint**: A declared routing definition that maps a private mesh HTTPS domain name and port to an internal service port or container socket.
- **Mesh Domain Name**: The fully qualified domain name (FQDN) assigned to the host within the private Tailscale network (e.g. `<host>.<tailnet>.ts.net`).
- **TLS Certificate Set**: The cryptographic public certificate chain and private key issued by the mesh network certificate authority for the host's domain.
- **Reverse Proxy Service**: The central routing and TLS termination daemon (Caddy) managing incoming HTTPS requests and dispatching them to backend applications.
- **Trusted Proxy Mapping**: The network trust configuration within backend services allowing reverse proxy request delegation and client address forwarding.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of remote connections to Home Assistant and n8n over the private mesh network use valid HTTPS with 0 security warnings or certificate errors in browsers and client apps.
- **SC-002**: 0 inbound ports opened on the home internet router and 0 public IP addresses exposed to the public internet for the proxied services.
- **SC-003**: Home Assistant dashboard loads and establishes an active WebSocket session in under 3 seconds over the private mesh network under standard cellular or external Wi-Fi conditions.
- **SC-004**: 100% of automated workflows and webhook calls in n8n execute successfully over HTTPS with less than 200 milliseconds of proxy routing latency overhead.
- **SC-005**: 100% of acquired TLS certificates and proxy configurations survive a complete host system reboot without requiring certificate re-issuance or manual re-authentication.
- **SC-006**: The entire system configuration evaluates and validates with 0 errors across project quality gates (`nix flake check`, `just lint`, `just check`).

## Assumptions

- The host machine (`homelab`) is enrolled in a Tailscale network (tailnet) with MagicDNS and HTTPS certificate features enabled in the Tailscale admin console.
- Authorized users access services from client devices (laptops, mobile phones) running an authenticated Tailscale client on the same tailnet.
- Backend services (Home Assistant and n8n) execute locally on the homelab host as system services or containers.
- Standard home router configurations do not need inbound port forwarding (ports 80 and 443 remain closed to the public internet).
- Services are addressed using their designated service ports on the host's Tailscale domain name (e.g. `https://<host>.<tailnet>.ts.net:8123` for Home Assistant, `https://<host>.<tailnet>.ts.net:5678` for n8n) or dedicated virtual host routes.
- The reverse proxy service account has permission to communicate with the local Tailscale daemon to retrieve certificates.
