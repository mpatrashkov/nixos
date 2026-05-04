{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.stow
  ];
}
