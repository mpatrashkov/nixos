# Findings: Fix slow first-time (cold) DNS resolution

## Investigation (2026-08-10)

### Symptom
AdGuard Home logs show the first resolution of a new domain taking ~10s.

### Reproduction (timed cold queries)
Using raw UDP DNS queries (`printf | nc -u | head -c 12` to exit on first reply):

- Fresh domains via AdGuard `:53`: mix of ~0.1s and 5s / 10s / 15s / 20s / 25s.
- Same method directly to dnscrypt `127.0.0.1:5335`: identical multi-second
  stalls (e.g. `qwik.dev`, `deno.com`, `bun.sh` all hit 25s), while neighbours
  resolved in <0.3s.

Slow times cluster at near-exact multiples of 5s → one 5000ms upstream timeout
per failed server before failover.

### Root cause — dnscrypt-proxy (NOT AdGuard Home)
AGH has a single upstream (`127.0.0.1:5335`), so it merely forwards and inherits
dnscrypt's latency. `upstream_mode = load_balance` in AGH is a no-op with one
upstream.

Effective dnscrypt config contributing factors:
1. **No `server_names`** → `live servers: 341` in the LB pool (confirmed in
   startup log), many high-latency (AU/Asia/Africa, 200–460ms probes).
2. **`timeout = 5000`** → 5s wait on any dead/slow upstream before failover;
   two bad servers in a row = the observed ~10s.
3. **`ipv6_servers = true`** but host is **IPv6-unreachable**
   (`ip -6 route show default` empty, no global v6 addr, `ping6 → Network is
   unreachable`). IPv6-only upstreams in the pool always stall 5s.

### Why "first time only"
dnscrypt `cache = true`, `cache_min_ttl = 2400` (40 min). Cold query pays the
timeout; subsequent queries are cached and instant.

### Measured RTT of candidate fast servers (from this host's journal)
Consistent across many samples (no-filter, no-log, DNSSEC unless noted):
- `cloudflare` ≈ 5–8 ms
- `adguard-dns-unfiltered` ≈ 10–14 ms
- `adguard-dns-unfiltered-doh` ≈ 10–15 ms
- `dns-sb` (display `dns.sb`) ≈ 26–29 ms
- `scaleway-fr` ≈ 37–40 ms
- `google` — never appears: excluded by `require_nolog` (Google logs).

## Chosen fix (user-approved) — pin fast servers
Edit `nixos-modules/services/dnscrypt-proxy2.nix` settings:
- `server_names = [ "cloudflare" "adguard-dns-unfiltered" ]` (pin fastest
  no-log/no-filter/DNSSEC servers instead of load-balancing 341).
- `ipv6_servers = false` (host has no IPv6).
- `timeout = 1500` (fast failover if the primary ever blips).
- Drop `require_dnssec` / `require_nolog` / `require_nofilter` — redundant once
  servers are explicitly pinned.

Superseded approach: `lb_strategy`/`lb_estimator` tuning over the full pool was
initially planned, then replaced with explicit pinning per user preference.

Note: `require_dnssec` is not set in the NixOS module, so the generated TOML has
`require_dnssec = false`. The NixOS dnscrypt-proxy module still defaults
`require_nolog = true` / `require_nofilter = true`; both pinned servers satisfy
these, so there is no conflict.

## Results (2026-08-10, applied via `./scripts/nix-test`, activated)

Build + activation succeeded (`nixos-system` store path swapped, +56 bytes).

### Generated TOML confirms settings
`server_names = ["cloudflare", "adguard-dns-unfiltered"]`, `ipv6_servers =
false`, `timeout = 1500`, `require_dnssec = false`.

### dnscrypt-proxy startup after change
`Server with the lowest initial latency: cloudflare (rtt: 5ms), live servers: 2`
— pool reduced from **341 → 2** (cloudflare 5ms DoH, adguard-dns-unfiltered 11ms
DNSCrypt). No IPv6 timeout noise for the pinned pool.

### Cold-query timing (raw UDP, first-reply exit)
~30 brand-new domains tested via both `127.0.0.1:5335` and `127.0.0.1:53`:

| Path | Sample domains | Time range |
|------|----------------|-----------|
| dnscrypt :5335 | zola.build, gleam.run, roc-lang.org, unison-lang.org, grain-lang.org | 0.007–0.138s |
| AdGuard :53 | ziglang.org, nim-lang.org, crystal-lang.org, janet-lang.org, bevyengine.org, tauri.app, slint.dev, wails.io | 0.002–0.315s |

**Every cold query < ~0.32s; zero 5s/10s/25s stalls.** Before: intermittent
5/10/15/20/25s. Fix confirmed effective.

### Sanity
- `doubleclick.net` via `:53` → `0.0.0.0` (AGH ad-blocking intact).
- `github.com` via `:53` → `140.82.121.4` (normal resolution works).

### Follow-up
- Applied via `nix-test` (non-permanent). Run `./scripts/nix-switch` to persist
  across reboots + commit.
- Minor log noise: `[adguard-dns-unfiltered] uses a non-standard provider name`
  / `should upgrade to XChaCha20` — cosmetic, server still validates OK.
