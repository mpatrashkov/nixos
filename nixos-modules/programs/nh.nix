{ pkgs, ... }:

{
  config = {
    environment.systemPackages = with pkgs; [
      nix-output-monitor
      nh
    ];
  };
}
