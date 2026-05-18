{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.nix-search-tv
    pkgs.television
  ];
}
