---
title: "Fix slow first-time (cold) DNS resolution"
status: testing
priority: high
tags: [networking, performance, dns]
created: 2026-08-10
updated: 2026-08-10
---

First-time resolution of a brand-new domain intermittently takes 5–25 seconds
(often ~10s) as seen in AdGuard Home logs. Investigation traced the cause to
`dnscrypt-proxy`, not AdGuard Home.

## Hypothesis

The delay is caused by dnscrypt-proxy load-balancing cold queries across all
341 upstream servers (no `server_names`), combined with a 5000ms per-upstream
`timeout` and IPv6-only upstreams that are unreachable on this v4-only host.
When a cold query lands on a dead/slow/IPv6 server it stalls one or more full
5s timeouts before failing over. Once cached (cache_min_ttl=2400s) it is instant.

Fix: keep the full server pool but (1) add latency-aware load-balancing
(`lb_strategy = 'first'`, `lb_estimator = true`), (2) disable IPv6 upstreams
(`ipv6_servers = false`), and (3) lower `timeout` to ~1500ms for fast failover.

## Results

(see findings.md)
