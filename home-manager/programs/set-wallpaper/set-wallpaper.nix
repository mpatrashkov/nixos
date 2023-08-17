{ pkgs }:

pkgs.writeShellApplication {
  name = "set-wallpaper";

  runtimeInputs = [ pkgs.swww pkgs.coreutils ];

  text = ''
    swww img "$HOME/wallpaper/$(date +%-H).jpg"
  '';
}
