---
date: 2026-08-10
status: implemented
---

# Plan: Setup DNS Adblocker via AdGuard Home

## Goal

Add system-level DNS ad/tracker blocking using **AdGuard Home**, layered on top
of the existing `dnscrypt-proxy2` encrypted resolver. AdGuard Home takes over
local port 53 and forwards all upstream queries to dnscrypt-proxy2, preserving
encryption + DNSSEC. Configuration is **fully declarative** (Nix is the source
of truth; web-UI edits are reset on rebuild).

## Architecture / DNS chain

```
Applications
   │  (nameserver 127.0.0.1  →  port 53)
   ▼
AdGuard Home            127.0.0.1:53      ← filtering + blocklists + web UI (:3000)
   │  (upstream_dns)
   ▼
dnscrypt-proxy2         127.0.0.1:5335    ← encrypted DoH/DNSCrypt + DNSSEC
   │
   ▼
Public encrypted resolvers (unchanged)
```

**Before:** dnscrypt-proxy2 listens on the implicit default `127.0.0.1:53`;
NetworkManager + `networking.nameservers` point clients at `127.0.0.1`.

**After:** dnscrypt-proxy2 moves to `127.0.0.1:5335`; AdGuard Home binds
`127.0.0.1:53`. The existing `nameservers = [ "127.0.0.1" "::1" ]` and the
NetworkManager `dns = "127.0.0.1;"` profile stay valid — clients still hit
`127.0.0.1:53`, which is now AdGuard Home. No networking.nix changes required.

## Decisions (resolved)

- **Adblocker:** AdGuard Home (`services.adguardhome`), not Pi-hole/dnscrypt-native.
- **Upstream:** existing dnscrypt-proxy2, relocated to `127.0.0.1:5335`.
- **Config mode:** fully declarative (`mutableSettings = false`).
- **Filter lists:** AdGuard DNS filter (plus AGH's built-in filtering).
- **Web UI auth:** placeholder bcrypt hash in Nix; user replaces it with their
  own (`htpasswd -B -n -b admin '<password>'`).
- **Web UI port:** 3000 (already open in the firewall; bound to localhost).

---

## Step 1 — Relocate dnscrypt-proxy2 to port 5335

Add an explicit `listen_addresses` so dnscrypt-proxy2 stops binding the default
`127.0.0.1:53` and instead serves as AdGuard Home's upstream on `5335`.

File: `nixos-modules/services/dnscrypt-proxy2.nix`

```diff
     services.dnscrypt-proxy = {
       enable = true;
       settings = {
+        # Move off port 53 so AdGuard Home can bind it. dnscrypt-proxy2 now acts
+        # purely as AdGuard Home's encrypted upstream resolver.
+        listen_addresses = [ "127.0.0.1:5335" ];
+
         ipv6_servers = true;
         require_dnssec = true;
```

Note: the existing `networking.networkmanager.dns = "none"` and the
`enp6s0-static` DNS override in this file remain unchanged and correct — they
still route clients to `127.0.0.1:53`, which will now be AdGuard Home.

---

## Step 2 — Create the AdGuard Home service module

Create a new module. Because of the repo's auto-loader (`nixos-modules/default.nix`
wraps every file in `services/` with a `myNixOS.services.<name>.enable` option),
the filename becomes the toggle name `adguardhome` and the config is only applied
when enabled (default `true`).

New file: `nixos-modules/services/adguardhome.nix`

```nix
{ ... }:

{
  config = {
    services.adguardhome = {
      enable = true;

      # Bind the web dashboard to localhost only.
      host = "127.0.0.1";
      port = 3000;

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
        # password "changeme" — REPLACE before/after first switch.
        users = [
          {
            name = "admin";
            password = "$2y$05$m5wJ7Tt0liHytdA0w7z4XePtvB0oxg2gm3lyOZ5vE9r5hE3wS2G6q";
          }
        ];
      };
    };
  };
}
```

Notes:
- `services.adguardhome.settings` maps 1:1 onto AdGuard Home's `AdGuardHome.yaml`.
- The filter URL `filter_1.txt` is the "AdGuard DNS filter" from the official
  HostlistsRegistry.
- The bcrypt hash above is a documented placeholder; the Build agent will surface
  a reminder to replace it. If the user does not replace it, the dashboard login
  is `admin` / `changeme`.

---

## Step 3 — Firewall (no change needed)

- Web UI is bound to `127.0.0.1`, so no inbound firewall rule is required.
- Port 3000 is already in `allowedTCPPorts` (harmless, can stay).
- DNS on `127.0.0.1:53` is loopback-only; the NixOS firewall does not filter
  loopback, so no port 53 rule is needed.

No edits to `nixos-modules/services/networking.nix`.

---

## Step 4 — Verify

Per repo AGENTS.md, after writing the changes the Build agent must stop and ask
how to proceed (switch / test / nothing). Recommended: **test** first
(`./scripts/nix-test`), then verify, then **switch**.

Verification checklist (run after test/switch activation):

```bash
# 1. Both services healthy
systemctl status adguardhome dnscrypt-proxy

# 2. dnscrypt-proxy2 is on 5335, AdGuard Home on 53
ss -ulpn | grep -E ':53 |:5335 '

# 3. Normal domain resolves (through AGH → dnscrypt-proxy2)
dig +short example.com @127.0.0.1

# 4. A known ad/tracker domain is blocked (returns 0.0.0.0 or NXDOMAIN)
dig +short doubleclick.net @127.0.0.1

# 5. Web dashboard reachable locally
curl -sI http://127.0.0.1:3000 | head -n1
```

Expected: step 3 returns a real IP; step 4 returns `0.0.0.0`/empty/NXDOMAIN;
dashboard returns HTTP 200/302.

Record all output in `.experiments/setup-dns-adblocker/findings.md`.

---

## Rollback

- Set `myNixOS.services.adguardhome.enable = false;` in
  `nixos/configuration.nix` (or delete `adguardhome.nix`), and revert the
  `listen_addresses` line in `dnscrypt-proxy2.nix`. Rebuild. dnscrypt-proxy2
  returns to owning port 53 exactly as before.

## Risk / edge cases

- **Port 53 race:** dnscrypt-proxy2 must be relocated in the *same* rebuild that
  enables AdGuard Home, or AGH fails to bind 53. Both changes ship together here.
- **First-run wizard:** providing `users` + `dns` in `settings` skips the AGH
  setup wizard; the service starts already configured.
- **Password:** placeholder hash must be replaced for real security; dashboard is
  localhost-only which limits exposure in the meantime.

## Files touched

- `nixos-modules/services/dnscrypt-proxy2.nix` (edit: add `listen_addresses`)
- `nixos-modules/services/adguardhome.nix` (new)
