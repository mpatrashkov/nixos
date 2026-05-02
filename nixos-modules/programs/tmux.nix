{ ... }:

{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    extraConfig = ''
      unbind C-b
      set-option -g prefix M-a
      bind-key M-a send-prefix

      set -g mouse on

      set -g status-right '#{?client_prefix,#[bg=yellow]#[fg=black] PREFIX #[default] ,}"#{=21:pane_title}"'

      bind r source-file /etc/tmux.conf \; display-message "tmux.conf reloaded."
    '';
  };
}
