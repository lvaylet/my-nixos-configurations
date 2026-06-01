_: {
  # Caddy Reverse Proxy Service
  services.caddy = {
    enable = true;

    # Trust the local Cloudflare Tunnel proxy and extract the real client IP
    globalConfig = ''
      servers {
        # Trust proxy headers from private IP ranges (like localhost where cloudflared runs)
        trusted_proxies static private_ranges

        # Use the original visitor IP provided by Cloudflare instead of the tunnel local IP
        client_ip_headers CF-Connecting-IP
      }
    '';

    virtualHosts."http://couchdb.vaylet.fr" = {
      extraConfig = ''
        # Reverse proxy CouchDB on localhost port 5984
        reverse_proxy 127.0.0.1:5984 {
          header_up Host {host}
          header_up X-Real-IP {remote}
        }
      '';
    };
  };
}
