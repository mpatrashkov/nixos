{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tor-browser
    kdePackages.kleopatra
  ];
}
