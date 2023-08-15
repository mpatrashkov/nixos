{ pkgs }:

pkgs.writeShellApplication {
    name = "set-wayland-display";

    runtimeInputs = [ pkgs.swww pkgs.coreutils ];

    text = ''
        swww img "$HOME/wallpaper/$(date +%-H).jpg"
    '';
}