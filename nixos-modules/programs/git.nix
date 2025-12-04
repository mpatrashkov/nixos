{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    pre-commit
  ];
}
