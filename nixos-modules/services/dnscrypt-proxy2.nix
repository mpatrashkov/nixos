{ ... }:

{
  config = {
    services.dnscrypt-proxy = {
      enable = true;
      settings = {
        # Move off port 53 so AdGuard Home can bind it. dnscrypt-proxy2 now acts
        # purely as AdGuard Home's encrypted upstream resolver.
        listen_addresses = [ "127.0.0.1:5335" ];

        # This host has no working IPv6 route; IPv6-only upstreams otherwise
        # stall a full `timeout` before failover on every cold query.
        ipv6_servers = false;

        # Pin the two fastest, reliable, no-log / no-filter / DNSSEC-validating
        # servers (RTTs measured from this host's own dnscrypt logs:
        # cloudflare ~5ms, adguard-dns-unfiltered ~11ms). This replaces
        # load-balancing across ~341 servers, which was the cause of cold-query
        # stalls when a query landed on a dead/slow/IPv6 upstream.
        server_names = [ "cloudflare" "adguard-dns-unfiltered" ];

        # Fail over between the two pinned servers in 1.5s instead of the 5s
        # default, so a transient blip on the primary never costs 5s.
        timeout = 1500;

        sources.public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
      };
    };

    systemd.services.dnscrypt-proxy.serviceConfig = {
      StateDirectory = "dnscrypt-proxy";
    };

    networking.networkmanager = {
      dns = "none";

      ensureProfiles.profiles.enp6s0-static = {
        ipv4 = {
          dns = "127.0.0.1;";
          ignore-auto-dns = true;
        };
      };
    };
  };
}
