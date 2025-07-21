{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      fastfetch
    '';
    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
    ];
    shellAliases = {
      ls = "eza --icons -l -s=type -I=node_modules --hyperlink";
      cat = "bat";
    };
  };
}
