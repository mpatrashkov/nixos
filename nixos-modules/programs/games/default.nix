{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    gnome-mines
  ];

  programs.gamescope.enable = true;

  # gamescope with PR #1897 ("Input holding") applied as a local patch:
  #   https://github.com/ValveSoftware/gamescope/pull/1897
  # Adds --libinput-hold-dev and --backend-disable-{keyboard,mouse} so a
  # gamescope subcompositor can claim evdev devices via libinput and ignore
  # input forwarded by the parent (GNOME) compositor — enabling per-instance
  # dedicated keyboard+mouse on a single-GPU, single-Wayland-session setup.
  #
  # The PR branch can't be used as `src` directly: its base has diverged
  # from upstream and the last commit re-adds a stray `subprojects/glm`
  # gitlink with no `.gitmodules` entry, which breaks the build. The patch
  # below is the 6 PR commits cherry-picked onto the nixpkgs gamescope tag
  # (3.16.23), with conflicts resolved and the broken gitlink dropped.
  # Remove this overlay once the PR is merged upstream.
  nixpkgs.overlays = [
    (final: prev: {
      gamescope = prev.gamescope.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ./patches/gamescope-1897-input-holding.patch
        ];
      });
    })
  ];
}
