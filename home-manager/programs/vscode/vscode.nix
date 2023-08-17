{ pkgs, ... }:

{
  home.file.".config/code-flags.conf".source = ./code-flags.conf;
}
