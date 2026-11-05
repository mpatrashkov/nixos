# Pi subagents

The NixOS configuration pins **Pi 1.5.0** through `pi-src` in `flake.nix`.
The installation helper pins **[pi-subagents 0.85.0](https://github.com/nicobailon/pi-subagents)**.
This extension requires Pi >=1.2.0. Do not install it into the old Pi 1.1.0 runtime.

## Install

After building and separately approving the Pi NixOS upgrade:

```sh
pi --version # 1.5.0
./scripts/pi-install-subagents
pi list
```

The helper invokes `pi install npm:pi-subagents@0.85.0`. It does not upgrade Pi,
activate NixOS, or launch agents. Package installation downloads executable
third-party code; review it before installation. The package version is pinned,
but its transitive dependency resolution is managed by Pi/npm, not a Nix lock.

Pi's native installer adds the package declaration to the existing personal
`~/.pi/agent/settings.json` and installs it in Pi's managed package cache.
Keep that settings file machine-local: it contains personal preferences and a
device ID. Do not replace it with shared Stow settings or commit it, credentials,
sessions, caches, or dependencies. Rerun the helper on another machine to reproduce
the top-level package selection. Existing Stow-managed extensions remain separate.

Start a **fresh Pi process** after the upgrade and installation. `/reload` can
refresh extensions but cannot replace a running Pi 1.1.0 executable with 1.5.0.
The existing Neovim `review_plan` tool must still be available.

## Check and use

Run `/subagents-doctor` in fresh Pi to check registration and optional integrations.
Missing optional integrations are not a reason to install extra packages blindly.
`/subagents-guide` provides installed-version guidance.

Built-in roles include:

- `scout`: local codebase reconnaissance.
- `worker`: implementation of an authorized task.
- `reviewer`: read-only review.
- `oracle`: a second opinion on a decision or plan.
- `delegate`: general delegation.
- `researcher` and `evidence-auditor`: web research roles requiring optional
  **pi-web-access**, which this setup does not install.

Example user-triggered foreground smoke test: open Pi in a disposable directory
with a small text file, then ask:

> Use scout in the foreground to summarize the files here. Read only; do not edit
> files, start background jobs, or use external tools/services beyond the model.

This calls a model and may incur charges. Installation and static checks do not
prove that foreground or detached/background delegation works. Check foreground
behavior first; background execution needs separate validation against the
Nix-packaged SDK and is not assumed to work merely because `pi --version` succeeds.

The extension does not automatically start a reviewer at installation. Do not
enable watchdogs, recurring schedules, or automatic delegation as an installation
side effect. Child agents are **not an OS sandbox**: their instructions/tool
restrictions do not isolate credentials, filesystem permissions, or the network.
They must preserve repository rules, including explicit plan-review boundaries
and separate NixOS test/switch and publication approval. Plan approval must never
be interpreted as permission for a child to activate or publish.

## Update and remove

Upgrade Pi through the Nix source pin and matching dependency/data hashes, not
`pi update`. Change the pinned extension version in `scripts/pi-install-subagents`
only after reviewing the new release, then rerun the helper. Avoid unversioned
package declarations or broad package updates when reproducing this selection.

Remove the personal package with Pi's native manager:

```sh
pi remove npm:pi-subagents@0.85.0
```

Restart Pi afterward. Removing the package does not revert the Nix-managed Pi
upgrade or necessarily delete stored run artifacts; inspect the extension's
installed-version documentation before deleting machine-local data.
