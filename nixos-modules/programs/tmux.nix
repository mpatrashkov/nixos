{ pkgs, ... }:

let
  tmux-fzf-links = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "fzf-links";
    version = "1.4.15";
    src = pkgs.fetchFromGitHub {
      owner = "alberti42";
      repo = "tmux-fzf-links";
      rev = "1.4.15";
      hash = "sha256-ZAZNOBE4n7tXpszNFw6Ri8BlV9s/4x9H2NovqRmOrCY=";
    };
    rtpFilePath = "fzf-links.tmux";
  };
in
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    plugins = [ tmux-fzf-links ];
    extraConfigBeforePlugins = ''
      set-option -g @fzf-links-python "${pkgs.python3}/bin/python3"
      set-option -g @fzf-links-fzf-path "${pkgs.fzf}/bin/fzf"
      set-option -g @fzf-links-use-colors on
    '';
    extraConfig = ''
      unbind C-b
      set-option -g prefix M-a
      bind-key M-a send-prefix

      bind & kill-window

      set -g mouse on

      set -g status-right '#{?client_prefix,#[bg=yellow]#[fg=black] PREFIX #[default] ,}"#{=21:pane_title}"'

      bind r source-file /etc/tmux.conf \; display-message "tmux.conf reloaded."
    '';
  };
}
