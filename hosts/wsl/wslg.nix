{ pkgs, ... }:

let
  # WSLg reads this from the Windows user profile, so it must be a real file there (not a symlink).
  # Applies to every WSL distro; needs `wsl --shutdown` to take effect.
  wslgconfig = pkgs.writeText "wslgconfig" ''
    [system-distro-env]
    WESTON_RDP_HI_DPI_SCALING=true
    WESTON_RDP_FRACTIONAL_HI_DPI_SCALING=false
    WESTON_RDP_DEBUG_DESKTOP_SCALING_FACTOR=200
  '';
in
{
  # Guarded so activation doesn't fail if /mnt/c isn't mounted yet at boot.
  system.activationScripts.wslgconfig = ''
    if [ -d /mnt/c/Users/miro ]; then
      install -m 644 ${wslgconfig} /mnt/c/Users/miro/.wslgconfig
    fi
  '';
}
