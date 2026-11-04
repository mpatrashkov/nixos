# GNOME configuration preview

Preview the current desktop configuration in a fresh **nested GNOME Shell window**,
without logging out or activating NixOS:

```sh
./scripts/gnome-preview
./scripts/gnome-preview --size 1600x1000
```

Run from the desktop's Wayland session on x86_64 Linux. The entry point also works
from another directory when invoked by its absolute path. Inside the repository's
devenv, `gnome-preview` is on PATH. `--help` does not build anything.

The command builds `packages.x86_64-linux.gnome-preview` from the current checkout
with the existing lockfile. The first build may download dependencies. It does
not run `nix-test`, `nix-switch`, update flake inputs, publish, or change the boot
default. You do not need a rebuild/activation to use this tooling.

## Edit, preview, repeat

1. Edit the declarative settings under `nixos-modules/services/gnome/`, or the
   existing extension package definitions.
2. Run `./scripts/gnome-preview`.
3. Inspect the GNOME desktop inside the **Mutter Devkit** window. Your ordinary
   desktop remains running outside it.
4. Close the Devkit window or press Ctrl-C in the launching terminal to finish.
   Rerun the command after further edits to get a fresh Shell and fresh settings.

This is a separate Shell process, so changed extension code does not depend on
reloading extensions in the real desktop. It is not a second full GNOME login.
Visual confirmation is still necessary, especially for blur/rendering changes.

The build uses the evaluated `nixosConfigurations.nixos` Shell, compiled user
dconf databases, and extension packages. There is no fallback to the active
system's extension directory. Under JJ, newly created files must be snapshotted
(e.g. with `jj status`) so the Git-backed flake source can see them; do not use
Git staging to work around that in this checkout.

## What settings are used?

The preview starts with **no real-user dconf overrides**. Its profile contains a
fresh writable user database followed by the candidate system databases in their
original order. NixOS locks remain locked. GDM settings are not loaded.

This avoids two common surprises:

- Existing user overrides can mask changed system defaults, even after relogging.
- Existing applications may retain immutable `file-db:` paths from an older
  NixOS dconf profile after activation. The preview starts fresh processes with
  the candidate database paths instead.

Any settings written inside the preview are disposable and disappear on exit.
Nothing captures them into Nix automatically. The real-desktop capture workflow
and reversible live previews are separate tasks; **live previews are deferred**.

Extension packages are discovered by their `extensionUuid` metadata from the
candidate system packages and the existing Stylix user's theme packages. The
custom Multi-monitor Panel package exposes this metadata too. An enabled UUID
without a matching package produces a warning, not an automatic installation.
The current configuration enables Another Window Session Manager without
packaging it, so that warning is expected.

## Diagnostics

```sh
./scripts/gnome-preview --dry-run
```

This builds the candidate bundle and prints Shell/extension versions and paths,
the dconf profile, private environment, session-bus configuration, and system-bus
policy. It does **not** start Shell, D-Bus, or PipeWire processes. Its temporary
workspace is removed before returning.

Normal launches stream logs in the foreground, including verbose system-bus
proxy decisions. Messages saying `Registering session with GDM` or `Registering
display with GDM` describe attempted calls, not successful registrations: the
following proxy `*HIDDEN*`/filter messages and registration errors show them being
blocked. Do not grant the preview host service access to suppress those errors.

For read-only inspection while the preview is running, use the private session
bus address printed by the launcher, **not** your normal session bus:

```sh
DBUS_SESSION_BUS_ADDRESS='<printed private address>' \
  gdbus call --session \
  --dest org.gnome.Shell \
  --object-path /org/gnome/Shell \
  --method org.gnome.Shell.Extensions.ListExtensions
```

The returned paths should point into the candidate preview assets. Extension
state `1` means ACTIVE. The D-Bus object path is `/org/gnome/Shell`, not
`/org/gnome/Shell/Extensions`.

## Isolation and cleanup

Each invocation creates restrictive private HOME, XDG config/data/cache/state,
runtime and temporary directories under `/tmp/gnome-preview-*`.

- The private **session bus** can activate only dconf. It does not inherit the
  host's service directories, portals, systemd user manager, or user targets.
- A private `xdg-dbus-proxy` filters the **system bus**, denying all host service
  access. There are currently no allowlisted calls. GDM registration, logind
  control, polkit agent registration, hardware services, and host service
  activation are not permitted through it.
- GNOME 50's documented `--wayland --devkit` mode displays a private compositor
  through a viewer. Only the viewer connects to the outer Wayland socket.
- Devkit needs PipeWire, so a private helper uses its own runtime socket and
  minimal server/client configs. No host PipeWire/PulseAudio socket is passed
  through; no WirePlumber, hardware discovery, realtime/RTKit integration, or
  host audio/video service is started. The PipeWire session-manager *module*
  supplies protocol factories, not a running hardware/session-management daemon.
- The launcher is a Linux child subreaper. It adopts detached descendants
  (Devkit calls `setsid()`), terminates only its own unreaped children using
  pidfds, escalates after a grace period, and reaps them before removing state.
  If cleanup cannot finish, it reports an error and preserves the workspace.

As with any process supervisor, SIGKILL or machine failure can bypass cleanup;
prefer closing the window or Ctrl-C. Never clean up by globally killing every
`gnome-shell`, `pipewire`, or `mutter-devkit` process.

## Limits and expected warnings

**This is not a security sandbox for arbitrary code.** Processes share your Unix
user, filesystem visibility, kernel, GPU, and non-D-Bus system interfaces.
Extensions could bypass environment-based isolation if malicious. Do not use it
to run untrusted extensions or applications.

The stripped session intentionally lacks CalendarServer, settings daemons,
audio, GVfs/trash integration, authentication agents, and most application
launchers. Related warnings are expected. Do not enable host services to silence
them. Avoid launching browsers and other single-instance applications: they may
communicate with an existing instance through mechanisms other than D-Bus.

The preview has one virtual monitor by default, not the real monitor topology.
Host shortcuts may intercept input. Screen locking, power controls, portals,
fractional scaling, secondary panels, and other hardware/session integrations
are not faithfully reproduced. It does not validate kernel/XKB/GDM/system-service
changes.

Theme assets are included where available, but the preview does not copy the
real home or Home Manager-generated theme settings/files. It may use default
Adwaita styling, missing desktop icons, or a plain background. It does not run
wallpaper-daemon. Full GTK/Qt/font/theme-file parity is outside this first phase.

NixOS activation or real-desktop mutations still require their normal separate
approvals; successfully running the preview does not authorize either.
