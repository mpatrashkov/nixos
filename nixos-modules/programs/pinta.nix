{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    pinta
  ];
}
