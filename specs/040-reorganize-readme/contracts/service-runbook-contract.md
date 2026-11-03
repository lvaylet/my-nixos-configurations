# Contract: Homelab Services Guide

**Feature Branch**: `040-reorganize-readme`

**Created**: 2026-11-03

**Target File**: `docs/services/homelab-services.md`

---

## 1. Document Structure & Scope

The `docs/services/homelab-services.md` document serves as the comprehensive configuration manual for all 12 services running on `homelab`.

- **Breadcrumb Header**: `[← Back to README](../../README.md)`
- **Mandatory Sections**:
  1. **Hosted Services Catalog & Topology**:
     - Complete table of services, runtime type (Native / OCI container), network ports, persistent storage mounts, and descriptions.
  2. **Reverse Proxy & HTTPS Architecture**:
     - Caddy with Cloudflare DNS-01 ACME challenge for automated Let's Encrypt certificates.
     - Full subdomain routing table (`ha.homelab.vaylet.fr`, `n8n.homelab.vaylet.fr`, `uptime.homelab.vaylet.fr`, `opencode.homelab.vaylet.fr`, `code.homelab.vaylet.fr`, `waha.homelab.vaylet.fr`, `sgdf.homelab.vaylet.fr`, `fb.homelab.vaylet.fr`, `portainer.homelab.vaylet.fr`, `jellyfin.homelab.vaylet.fr`, `qbittorrent.homelab.vaylet.fr`).
  3. **Step-by-Step Service Configuration Recipes**:
     - Recipe 1: Cloudflare Wildcard DNS Setup & API Token Provisioning (`cloudflare.env` - Bash & Fish).
     - Recipe 2: Home Assistant Reverse Proxy Authorization (Web UI setup and loopback trust).
     - Recipe 3: WAHA WhatsApp Credentials & Device QR Pairing (`waha.env` - Bash & Fish).
     - Recipe 4: Uptime Kuma Setup & Portainer Docker Socket Monitoring.
     - Recipe 5: Tailscale SSH Access Control Policy (JSON ACL snippet).
     - Recipe 6: OpenCode Initial Setup, Declarative Skills Bundle, and Password Retrieval (Bash & Fish).
     - Recipe 7: SGDF Tools API Setup, Token Retrieval, and n8n Integration (Bash & Fish).
     - Recipe 8: Code-Server Web Code Editor Setup & Extension Parity (Bash & Fish).
     - Recipe 9: Automated Container Image Updates via Podman and Systemd Timer (`just update-containers` - Bash & Fish).
  4. **Shared Multimedia Storage (`/data`)**:
     - Group `multimedia` (GID `995`), SetGID bit (`2775`), and systemd tmpfiles `z` rules across `qbittorrent`, `filebrowser`, and `jellyfin`.

---

## 2. Invariants

- Plaintext secrets MUST NOT be written into documentation; provide secure generation commands (`tr -dc 'a-f0-9' < /dev/urandom...`) for all tokens.
- Strict dual-shell (**Bash** and **Fish**) command parity across every operational snippet.
- Must pass `just lint-md` with zero warnings.
