---
date: 2026-08-10
status: pending_review
---

# Plan: Fix slow first-time (cold) DNS resolution

## Problem

First-time resolution of a new domain intermittently takes 5–25s (often ~10s),
visible in AdGuard Home logs. Root cause is **dnscrypt-proxy**, not AdGuard Home:

- No `server_names` → all **341** upstream servers in the load-balancing pool,
  many high-latency/flaky.
- `timeout = 5000` (5s) → each dead/slow upstream stalls a full 5s before
  failover; two in a row ≈ the observed 10s.
- `ipv6_servers = true` while the host is **IPv6-unreachable** → IPv6-only
  upstreams always stall 5s when selected.

Once resolved, dnscrypt caches (`cache_min_ttl = 2400`), so only the cold query
is slow. See `findings.md` for full reproduction and evidence.

## Decisions (confirmed with user)

1. **Pin `server_names`** to the two fastest, reliable, no-log / no-filter /
   DNSSEC servers measured on this host:
   `[ "cloudflare" "adguard-dns-unfiltered" ]`
   (cloudflare ≈5ms, adguard-dns-unfiltered ≈11ms — both consistently fast in
   this host's own dnscrypt logs).
2. **Disable IPv6 upstreams** (`ipv6_servers = false`) — host is v4-only.
3. **Lower `timeout` to 1500ms** for fast failover between the two pinned
   servers.
4. **Drop** the now-redundant global filters `require_dnssec`, `require_nolog`,
   `require_nofilter` (both pinned servers already satisfy all three; explicit
   pinning supersedes property-based filtering).
5. Google DNS considered and **excluded** — it does not claim `no-log`.

## Change

Single file: `nixos-modules/services/dnscrypt-proxy2.nix`.

```diff
     services.dnscrypt-proxy = {
       enable = true;
       settings = {
         # Move off port 53 so AdGuard Home can bind it. dnscrypt-proxy2 now acts
         # purely as AdGuard Home's encrypted upstream resolver.
         listen_addresses = [ "127.0.0.1:5335" ];

-        ipv6_servers = true;
-        require_dnssec = true;
+        # This host has no working IPv6 route; IPv6-only upstreams otherwise
+        # stall a full `timeout` before failover on every cold query.
+        ipv6_servers = false;
+
+        # Pin the two fastest, reliable, no-log / no-filter / DNSSEC-validating
+        # servers (RTTs measured from this host's own dnscrypt logs:
+        # cloudflare ~5ms, adguard-dns-unfiltered ~11ms). This replaces
+        # load-balancing across ~341 servers, which was the cause of cold-query
+        # stalls when a query landed on a dead/slow/IPv6 upstream.
+        server_names = [ "cloudflare" "adguard-dns-unfiltered" ];
+
+        # Fail over between the two pinned servers in 1.5s instead of the 5s
+        # default, so a transient blip on the primary never costs 5s.
+        timeout = 1500;

         sources.public-resolvers = {
```

### Resulting settings block (for reference)

```nix
settings = {
  listen_addresses = [ "127.0.0.1:5335" ];

  ipv6_servers = false;

  server_names = [ "cloudflare" "adguard-dns-unfiltered" ];

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
```

Note: the `sources.public-resolvers` block is **retained** — dnscrypt still
needs the resolver list to look up the certs/addresses for the pinned
`server_names`.

## Notes / rationale

- Config names verified: `cloudflare` and `adguard-dns-unfiltered` are the exact
  DNSCrypt entries (both appear by these names in this host's journal). Display
  name `dns.sb` would map to config `dns-sb`, but it is not used here.
- `NixOS services.dnscrypt-proxy.settings` maps 1:1 to the generated
  `dnscrypt-proxy.toml`, so these keys land directly in the TOML.
- No AdGuard Home change needed; it has a single upstream and simply forwards.
- Both pinned servers are DNSCrypt (UDP/TCP) — DNSSEC-validating, no-log,
  no-filter — so dropping `require_*` changes no behavior for them.

## Verification (after apply/test)

1. `systemctl status dnscrypt-proxy` → active. Startup log should now list only
   the pinned servers (e.g. `dnscrypt servers with the lowest initial latency`
   referencing cloudflare / adguard-dns-unfiltered), NOT 341 live servers.
2. Confirm generated TOML: locate it via
   `systemctl show -p ExecStart --value dnscrypt-proxy` and check it contains
   `server_names = ['cloudflare', 'adguard-dns-unfiltered']`,
   `ipv6_servers = false`, `timeout = 1500`, and no `require_*` lines.
3. Timed cold-query loop over ~15 brand-new domains via both `127.0.0.1:5335`
   and `127.0.0.1:53`:
   - Method: `printf "<dns-query>" | nc -u -w5 127.0.0.1 <port> | head -c 12`
     wrapped in `time` (exits on first reply).
   - Expectation: no query exceeds ~1.5s; typical cold query < 0.3s; zero 5s /
     10s multiples.
4. Sanity: `doubleclick.net` via `:53` still returns `0.0.0.0` (AGH blocking
   intact); a normal domain resolves correctly.
5. Append before/after timing table to `findings.md`.

## Rollback

Revert the changed lines in `nixos-modules/services/dnscrypt-proxy2.nix`
(restore `ipv6_servers = true` + `require_dnssec = true`, remove `server_names`
and `timeout`) and re-run `./scripts/nix-switch`.

## Apply

Per repo workflow (AGENTS.md), this is a NixOS config change → after approval,
ask the user to choose **switch** / **test** / **do nothing** (short header
`NixOS Action`), and on switch prompt for a commit message (header `Git Commit`),
then run `./scripts/nix-switch "<msg>"` (or `./scripts/nix-test`). After apply,
update this plan's `status` to `approved` and append results to `findings.md`.

## Files touched

- `nixos-modules/services/dnscrypt-proxy2.nix` (edit)
- `.experiments/fix-slow-cold-dns-resolution/` (idea.md, findings.md, plan.md)
```
