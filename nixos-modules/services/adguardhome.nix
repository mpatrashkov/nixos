{ ... }:

{
  config = {
    services.adguardhome = {
      enable = true;

      # Bind the web dashboard to localhost only.
      host = "127.0.0.1";
      port = 3053;

      # Fully declarative: Nix owns the config; web-UI edits reset on rebuild.
      mutableSettings = false;

      settings = {
        # --- DNS listener (this is what clients query) ---
        dns = {
          bind_hosts = [ "127.0.0.1" ];
          port = 53;

          # Forward everything to the local encrypted resolver.
          upstream_dns = [ "127.0.0.1:5335" ];
          bootstrap_dns = [ "127.0.0.1:5335" ];

          # dnscrypt-proxy2 already enforces DNSSEC; AGH just forwards.
          enable_dnssec = false;

          # Only trust our local upstream; no plaintext fallback.
          upstream_mode = "load_balance";
        };

        # --- Filtering ---
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
          # Refresh blocklists every 24h.
          filters_update_interval = 24;
        };

        # AGH's built-in ad/tracker blocking service.
        filters = [
          {
            enabled = true;
            name = "AdGuard DNS filter";
            id = 1;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          }
        ];

        # --- Web dashboard login ---
        # Generate your own hash:  htpasswd -B -n -b admin 'YOUR_PASSWORD'
        # then paste the part AFTER "admin:" below. This is a PLACEHOLDER for
        # password "changeme" — REPLACE for real security.
        users = [
          {
            name = "admin";
            password = "$2y$05$Fjd1WoUfz9TGqfL6L3ONaeGgEa5Z7X0ohcKvn6PdP2x/8BCBIvIK.";
          }
        ];
      };
    };
  };
}
