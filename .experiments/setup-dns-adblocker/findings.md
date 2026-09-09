# Findings: Setup DNS Adblocker (AdGuard Home)

## Implementation (2026-08-10)

Implemented via two files:
- `nixos-modules/services/dnscrypt-proxy2.nix` — added
  `listen_addresses = [ "127.0.0.1:5335" ]` to free port 53.
- `nixos-modules/services/adguardhome.nix` — new module. AdGuard Home binds
  `127.0.0.1:53`, forwards upstream to `127.0.0.1:5335`, web UI on
  `127.0.0.1:3000`, fully declarative (`mutableSettings = false`), AdGuard DNS
  filter enabled.

## Verification (via `./scripts/nix-test`, activated)

Build/activation succeeded. Store diff added `adguardhome-0.107.78`,
`AdGuardHome.yaml`, `unit-adguardhome.service`, pre-start script.

- `systemctl is-active adguardhome dnscrypt-proxy` → both `active`.
- Listeners (`ss -ulpn`):
  - `127.0.0.1:53`   → AdGuard Home
  - `127.0.0.1:5335` → dnscrypt-proxy2
- AGH log: `filter updated id=1 rules_count=164386` (AdGuard DNS filter loaded).
- dnscrypt-proxy2 log: selected `quad9-doh` upstream, 341 live servers.

### DNS resolution tests
| Query | Path | Result |
|-------|------|--------|
| `nixos.org` | AGH:53 | `99.83.231.61`, `75.2.60.5` (resolved) |
| `doubleclick.net` | AGH:53 | `0.0.0.0` (**BLOCKED**) |
| `example.com` | upstream :5335 | `104.20.23.154`, `172.66.147.243` (resolved) |

Chain confirmed working: Apps → AdGuard Home (:53) → dnscrypt-proxy2 (:5335) →
encrypted upstream. Ad/tracker blocking active.

### Notes / follow-ups
- First cold query to a brand-new domain occasionally times out once, then
  succeeds (cache warm-up); subsequent queries fine.
- AGH log warning: `permcheck: found unexpected permissions
  type=directory path=/var/lib/private/AdGuardHome perm=0755 want=0700` —
  cosmetic, from DynamicUser StateDirectory; does not affect operation.
- **Web dashboard login is the PLACEHOLDER `admin` / `changeme`.** Replace the
  bcrypt hash in `adguardhome.nix` with your own:
  `htpasswd -B -n -b admin '<password>'` → paste the part after `admin:`.
- This was applied via `nix-test` (non-permanent). Run `nix-switch` to persist
  across reboots + commit.
