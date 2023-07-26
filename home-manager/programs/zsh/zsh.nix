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
    };
}