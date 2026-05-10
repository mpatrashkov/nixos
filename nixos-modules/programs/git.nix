{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    pre-commit
    github-desktop
    github-cli
  ];
}
