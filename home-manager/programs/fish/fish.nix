{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      set fish_greeting # Disable greeting
      fastfetch --config "$HOME/.config/fastfetch/short-config.jsonc"
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
