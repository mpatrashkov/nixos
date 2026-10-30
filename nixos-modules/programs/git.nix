{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    jujutsu
    jjui
    github-cli
  ];
}
