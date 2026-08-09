{ pkgs, ... }:
let
  # A standalone patched copy of xkeyboard-config.  We deliberately do NOT use
  # `nixpkgs.overlays` here: overlaying xkeyboard-config would force a
  # from-source rebuild of the entire GNOME stack (mutter, gnome-shell, gjs,
  # …) because they all depend on it transitively — and some of those (e.g.
  # gjs) have flaky sandboxed test suites that then break the build.
  #
  # Instead we build only this small derivation and point libxkbcommon at it
  # at runtime via XKB_CONFIG_ROOT (and the X server via services.xserver.xkb.dir).
  # mutter/libxkbcommon read the XKB data at runtime, so no desktop rebuild
  # is needed.
  #
  # The patch remaps FK22/FK23/FK24 to their proper F22/F23/F24 keysyms.
  # Without it the XKB "inet" symbols file maps FK22→XF86TouchpadOn and
  # FK23→XF86TouchpadOff (both grabbed by gnome-settings-daemon's static
  # media-key bindings), so those keys never reach custom keybindings.
  xkeyboard-config-patched = pkgs.xkeyboard-config.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./patches/xkb-f22-f24-keysyms.patch
    ];
  });
in
{
  # X server (used by GDM) reads XKB data from here.
  services.xserver.xkb.dir = "${xkeyboard-config-patched}/etc/X11/xkb";

  # libxkbcommon (used by mutter on Wayland) runtime override.
  # https://xkbcommon.org/doc/current/group__include-path.html
  environment.sessionVariables.XKB_CONFIG_ROOT =
    "${xkeyboard-config-patched}/etc/X11/xkb";
}
