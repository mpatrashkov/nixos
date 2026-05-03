{ pkgs, inputs, ... }:

{
  config.environment.systemPackages = [
    pkgs.nixd
    pkgs.nixfmt
  ];

  config.nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
}
