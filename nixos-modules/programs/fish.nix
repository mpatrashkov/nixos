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
      ${pkgs.worktrunk}/bin/wt config shell init fish | source

      if set -q TMUX
          set -l sock (ls -t /run/user/$UID/vscode-ipc-*.sock 2>/dev/null | head -n1)
          if test -n "$sock"
              set -gx VSCODE_IPC_HOOK_CLI "$sock"
          end
      end
    '';
    shellAliases = {
      ls = "eza --icons -l -s=type -I=node_modules --hyperlink";
      cat = "bat";
      nsp = "nix-shell -p (tv nixpkgs)";
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
}
