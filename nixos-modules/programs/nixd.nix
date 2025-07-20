{ pkgs, inputs, ... }:

{
  config.environment.systemPackages = [
    pkgs.nixd
    pkgs.nixfmt-rfc-style
  ];

  config.nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
}
