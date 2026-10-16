---
title: "Fix libvirt TPM-bound credential after TPM changes"
status: idea
priority: medium
tags: [nixos, libvirt, tpm, credentials]
created: 2026-10-16
updated: 2026-10-16
---

## Diagnosis

`libvirtd.service` fails before daemon startup with status `243/CREDENTIALS` and
"TPM key integrity check failed. Key most likely does not belong to this TPM."
Its upstream `10-secret.conf` loads the encrypted credential from
`/var/lib/libvirt/secrets/secrets-encryption-key`.

The initializer `virt-secret-init-encryption.service` only creates this file if
it is absent. The secrets directory currently contains only that credential
(no stored libvirt secret definitions or values were visible in the listing).
The failure also occurred with libvirt 12.4.0, before the latest nix-test.

## Proposed recovery

Confirm no existing libvirt secrets require the old key. Back up (move, do not
delete) the obsolete credential, run the initializer, and restart libvirtd.
Existing encrypted secrets would require recovering the original key or
re-provisioning their values; a fresh key cannot decrypt them.
Do not clear the TPM or delete systemd's machine-wide credential.secret.

No configuration changes or recovery commands have been applied.
