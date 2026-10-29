{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    jujutsu
    jjui
    pre-commit
    github-cli
  ];
}
