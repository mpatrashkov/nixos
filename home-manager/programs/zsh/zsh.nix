{ pkgs, config, ... }:

{
    programs.zsh = {
        enable = true;
        shellAliases = {
            ll = "ls -l";

        };
        history = {
            size = 10000;
            path = "${config.xdg.dataHome}/zsh/history";
        };

        oh-my-zsh = {
            enable = true;
            plugins = [ "git" "sudo" "docker" ];
            theme = "robbyrussell";
        };

        initExtra = ''
            export PATH=$PATH:$HOME/scripts/src
            export ANDROID_JAVA_HOME=${pkgs.jdk.home}
            export ANDROID_HOME=~/Android/Sdk
        '';
    };
}