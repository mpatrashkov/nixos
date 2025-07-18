{ pkgs, ... }:

{
  config = {
    environment.sessionVariables = {
      NH_FLAKE = "/home/miro/flake";
    };

    environment.systemPackages = with pkgs; [
      nix-output-monitor
      nh
    ];
  };
}
