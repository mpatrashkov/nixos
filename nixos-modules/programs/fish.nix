{
  pkgs,
  ...
}:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      set fish_greeting # Disable greeting
      fastfetch --config "$HOME/.config/fastfetch/short-config.jsonc"
    '';
    shellAliases = {
      ls = "eza --icons -l -s=type -I=node_modules --hyperlink";
      cat = "bat";
    };
  };

  environment.systemPackages = with pkgs; [
    # Utils
    bat
    eza

    # Plugins
    grc
    fishPlugins.grc
  ];

  users.extraUsers.miro = {
    shell = pkgs.fish;
  };

  # Disable man page cache generation for fish, because it slows down nix builds a lot
  # See https://wiki.nixos.org/wiki/Fish#Disable_man_page_generation.
  # Remove when https://github.com/NixOS/nixpkgs/pull/414076 gets merged
  documentation.man.generateCaches = false;
}
