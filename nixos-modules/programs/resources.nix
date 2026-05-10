{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    resources
  ];
}
