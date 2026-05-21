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

  tmux-super-fingers = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "super-fingers";
    version = "unstable-2026-05-08";
    src = pkgs.fetchFromGitHub {
      owner = "artemave";
      repo = "tmux_super_fingers";
      rev = "523dc9b7a79f1ceb8d9be72e22c263c4a7cd3bdf";
      hash = "sha256-GiOkSADuWz19ndsVlKiKatPnplUpmukoZTPakIXWqF0=";
    };
    rtpFilePath = "tmux_super_fingers.tmux";
    postInstall =
      let
        runtimeDeps = pkgs.lib.makeBinPath [
          pkgs.python3
          pkgs.lsof
          pkgs.file
          pkgs.procps
          pkgs.coreutils
          pkgs.xdg-utils
          pkgs.tmux
        ];
      in
      ''
        substituteInPlace $target/run.py \
          --replace-fail '#!/usr/bin/env python3' '#!${pkgs.python3}/bin/python3'
        substituteInPlace $target/run.sh \
          --replace-fail '#!/usr/bin/env bash' '#!${pkgs.bash}/bin/bash
        export PATH=${runtimeDeps}:$PATH'
      '';
  };

  super-fingers-action = pkgs.writeText "super-fingers-vscode.py" ''
    import os
    import mimetypes
    from tmux_super_fingers.actions.action import Action
    from tmux_super_fingers.targets.file_target import FileTarget

    class SmartOpenAction(Action):
        def perform(self):
            path = self.target_payload.file_path
            mime, _ = mimetypes.guess_type(path)
            is_text = mime is not None and mime.startswith("text/")
            if mime is None or is_text:
                arg = path
                if self.target_payload.line_number:
                    arg += f":{self.target_payload.line_number}"
                os.system(f'code -g "{arg}"')
            else:
                os.system(f'xdg-open "{path}"')

    FileTarget.primary_action = SmartOpenAction
  '';
in
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    plugins = [
      tmux-fzf-links
      tmux-super-fingers
    ];
    extraConfigBeforePlugins = ''
      set-option -g @fzf-links-python "${pkgs.python3}/bin/python3"
      set-option -g @fzf-links-fzf-path "${pkgs.fzf}/bin/fzf"
      set-option -g @fzf-links-use-colors on

      set -ga update-environment EDITOR
      set -g @super-fingers-key f
      set -g @super-fingers-extend ${super-fingers-action}
    '';
    extraConfig = ''
      unbind C-b
      set-option -g prefix M-a
      bind-key M-a send-prefix

      bind & kill-window

      set -g visual-activity off
      set-option -g focus-events on

      # Required for kitty graphics protocol (image previews) to work through tmux.
      set -gq allow-passthrough on

      set -g mouse on

      set -g status-right '#{?client_prefix,#[bg=yellow]#[fg=black] PREFIX #[default] ,}"#{=21:pane_title}"'

      bind r source-file /etc/tmux.conf \; display-message "tmux.conf reloaded."

      # Rename auto-named session "0" to the lowest unused integer >= 1
      # so the session switcher starts numbering from 1 instead of 0.
      set-hook -g session-created 'run-shell -b "{ if [ \"#{hook_session_name}\" = 0 ]; then n=1; while ${pkgs.tmux}/bin/tmux has-session -t==\"$n\" 2>/dev/null; do n=$((n+1)); done; ${pkgs.tmux}/bin/tmux rename-session -t==0 \"$n\"; fi; } >/dev/null 2>&1"'
    '';
  };
}
