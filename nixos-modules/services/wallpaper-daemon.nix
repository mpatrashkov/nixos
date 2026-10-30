{ inputs, ... }:

{
  imports = [ inputs.wallpaper-daemon.nixosModules.default ];

  services.wallpaper-daemon = {
    enable = true;
    rotateInterval = "1h";
    fetchInterval = "6h";
    country = "US";
    locale = "en-US";
  };
}
