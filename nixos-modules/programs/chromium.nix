{ pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      chromium
    ];

    environment.etc = {
      "chromium-flags.conf".text = ''
        --enable-features=VaapiVideoDecodeLinuxGL
        --ozone-platform=wayland
      '';
    };
  };
}
