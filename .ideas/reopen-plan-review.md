---
title: "Reopen Neovim from the plan review decision menu"
status: testing
priority: medium
tags: [pi, neovim, planning, review, annotations]
created: 2026-10-31
updated: 2026-10-31
---

After closing a plan review, offer an explicit action to reopen Neovim and continue reading/editing annotations without ending the review call. Reuse the same read-only snapshot and persisted annotations; refresh the annotation count and available final actions after each editor exit. Pending stays the default. Reopening never submits feedback or grants approval.

Require a fresh valid editor receipt on every pass, preserve changed-plan and report-integrity checks, and retain cancellation/error cleanup. Do not alter the unapproved DNS plan used as the motivating example.

## Implementation and validation

- Added an explicit reopen action to the post-editor menu for both tool and command reviews. Repeated passes reuse the same read-only snapshot and saved annotations, reread the fresh receipt, and rebuild available final choices. Pending remains first/default.
- Removed the previous receipt before each editor launch, preventing a successful earlier pass from authorizing a subsequent failed one. Final report/plan hash validation and existing explicit feedback/approval boundaries remain in place.
- Updated `docs/pi-plan-review.md`; existing Pi Stow links already point to the edited source. No NixOS changes or publication.
- Twelve disposable integration checks using real headless Neovim passed: repeated reopening and persistence, edited feedback, comment removal enabling approval, comment addition disabling approval, pending/Escape, missing second receipt, second editor failure, changed plan, cancellation, forged approval with comments, and report tampering.
- Strict TypeScript checking against installed Pi types and whitespace checks passed. Temporary validation scripts, fixtures, and generated state were deleted; no retained tests. Interactive terminal appearance/focus still needs manual confirmation after `/reload`.
- The motivating DNS plan retains SHA-256 `58f982f75ba25aa2c6350d42d60858b62eda88c35e4ef9059c84f157348c9ae0` and is not approved or implemented by this task.
