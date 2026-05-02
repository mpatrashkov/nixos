{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.claude-code
    pkgs.gemini-cli
  ];
}
