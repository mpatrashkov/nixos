{ pkgs, ... }:

{
  config = {
    environment.sessionVariables = {
      FLAKE = "/home/miro/flake";
    };

    environment.systemPackages = with pkgs; [
      nix-output-monitor
      nh
    ];
  };
}
