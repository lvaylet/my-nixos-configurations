{pkgs, ...}: {
  # CouchDB Service
  # ---
  # Thanks to Caddy acting as a reverse proxy and Cloudflare Tunnel:
  #
  # 1. Access URLs:
  #    - Admin Interface (Fauxton): https://couchdb.vaylet.fr/_utils/
  #    - API Endpoint:              https://couchdb.vaylet.fr/
  #
  # 2. Credentials:
  #    - User: admin
  #    - Password: The one hashed in the 'extraConfig.admins' section below.
  #
  # 3. Network Flow:
  #    Client -> Cloudflare (HTTPS) -> Cloudflare Tunnel (Homelab) -> Caddy (http://127.0.0.1:80) -> CouchDB (127.0.0.1:5984)
  #
  # Reference: https://mynixos.com/options/services.couchdb
  services.couchdb = {
    enable = true;

    package = pkgs.couchdb3;

    # Listen on loopback interface only. Caddy will reverse proxy traffic securely in HTTPS.
    bindAddress = "127.0.0.1";

    # Users and authentication
    # Credentials are saved in `/var/lib/couchdb/local.ini`.
    # ---
    adminUser = "admin";
    extraConfig = {
      # Save extra settings to `/var/lib/couchdb/local.ini`.

      # List admin users and their hashed passwords.
      #
      # To create a new password for an admin user, SSH to the homelab and save
      # the plain text password to `/var/lib/couchdb/local.ini`:
      #
      # [admins]
      # <user> = <PLAIN_TEXT_PASSWORD>
      #
      # Then restart the service with `systemctl restart couchdb.service` and
      # check the new hash shows up in `/var/lib/couchdb/local.ini`:
      #
      # [admins]
      # <user> = -pbkdf2-71c01cb429088ac1a1e95f3482202622dc1e53fe,226701bece4ae0fc9a373a5e02bf5d07,10
      #
      # Finally, copy the has below for a declarative and secure setup.
      #
      # References:
      # - https://docs.couchdb.org/en/stable/intro/security.html#creating-a-new-admin-user
      # - https://docs.couchdb.org/en/stable/intro/security.html#hashing-passwords
      admins = {
        admin = "-pbkdf2:sha256-fb9162f9ba75d14d836baa0c90cd1010aa32d7901d976d89a9dd8bc6263428af,f967ec9a06d050d2620ae226f32040d1,600000";
        obsidian = "-pbkdf2:sha256-771deab41cca1e0ad56245fd496ba8ee3697ea63b3029e83e8af1fd019dfd8ae,6b17e726387b0d2dd3b7a8d0360708fd,600000";
      };

      # Obsidian LiveSync configuration: CORS, authentication...
      chttpd = {
        require_valid_user = true;
        enable_cors = true;
      };
      httpd = {
        enable_cors = true;
      };
      cors = {
        origins = "*";
        credentials = true;
        methods = "GET, POST, PUT, DELETE, HEAD";
        headers = "accept, authorization, content-type, origin, referer";
      };
    };
  };
}
