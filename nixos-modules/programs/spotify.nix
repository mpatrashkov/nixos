{
  pkgs,
  ...
}:

{
  # NOTE: There is an issue with Spotify on wayland, which causes the spotify client to have ugly windows border
  environment.systemPackages = [ pkgs.spotify ];
}
