---
title: "Investigate system freeze during devenv switch"
status: in_progress
priority: high
tags: [kernel, freeze, usb, audio, nixos, rcu]
created: 2026-10-30
updated: 2026-10-30
---

## Incident

User reported the PC froze during/after the approved devenv switch attempt and required a power-button reboot. Related rollout: `setup-project-devenv.md`. Published source is `e2b2d6b2f7c1831c67f34bb47c030ee7ec4bf663`; intended switch did not become the persistent default.

## Evidence

- Previous boot: `e13ea1cd9bbe4b809da339bcfc656366`, kernel 7.2.9. Current boot: `066d8a722b454aa78aa3888aac8e0017`.
- After reboot, both `/run/current-system` and the persistent system profile resolve to `Reenable-home-manager-and-wallpaper-daemon-ea02aa7c4673`, not the target `setup-devenv-e2b2d6b2f7c1`. No nh/Nix process from the attempt survives.
- Previous-boot journal contains repeated expedited RCU stalls involving CPU 26 and kernel hung-task reports. At 20:14:52, Nix PID 51621 was blocked in `synchronize_rcu_expedited` during `namespace_unlock -> nsproxy_free -> do_exit -> do_group_exit -> exit_group`. This was kernel-side process teardown, not evidence that compilation was still progressing. The report also says `Blocked by coredump`; it does not by itself establish a Nix crash cause.
- Kernel worker 48501 was blocked in the `netns cleanup_net` workqueue: `synchronize_rcu_expedited -> nf_conntrack_cleanup_net_list -> ops_undo_list -> cleanup_net`. Later hung-task reports include Chrome threads and another worker. RCU stall reports persist through 20:29:41.
- Simultaneously, the journal was flooded with `usb 1-5.2.3: BOGUS urb flags, 600 --> 200`, `usb_submit_urb`, and `snd_complete_urb [snd_usb_audio]` warnings through the last recorded entries at 20:30:20.
- Current sysfs identifies USB path `1-5.2.3` as `Shure MV6`, manufacturer `Shure Inc`. This is a lead, not proof that the microphone caused the RCU stalls/freeze.
- Current-boot bounded query found no matching USB warning entries; system failed-unit list is empty. Boot timestamps show a clock discontinuity, so avoid treating wall-clock differences across boots as reliable elapsed time.
- The switch command runner timed out after 120 seconds, killing the unprivileged coordinator while root nh/Nix remained. No second switch, rollback, driver changes, reboot command, or process-kill recovery was initiated by the assistant.

## Next investigation

Correlate the earliest RCU stall stack/CPU state with USB warnings and netns cleanup using bounded journal queries. Investigate the running kernel/USB-audio behavior and Shure MV6 connection before retrying deployment. Do not conclude that devenv package removals caused the kernel freeze merely from timing. Any kernel/configuration workaround requires review and separate activation approval.
