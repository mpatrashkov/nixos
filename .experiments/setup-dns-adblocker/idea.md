---
title: "Setup DNS Adblocker (AdGuard Home)"
status: in_progress
priority: high
tags:
  - network
  - security
created: 2026-08-10
updated: 2026-08-10
---

Set up a system-level DNS adblocker using AdGuard Home, layered on top of the
existing dnscrypt-proxy2 encrypted resolver.

## Hypothesis

AdGuard Home can bind local port 53 and provide DNS-level ad/tracker blocking
plus a web dashboard, while forwarding all upstream queries to the existing
dnscrypt-proxy2 instance (moved to 127.0.0.1:5335) so encryption/DNSSEC is
preserved. Configuration is fully declarative via `services.adguardhome`.

## Results

(Populated during implementation in findings.md)
