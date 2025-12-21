{
  description = "Your new nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags.url = "github:Aylur/ags";
    stylix.url = "github:danth/stylix";

    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs-small";

    # This input gets overridden by a command line argument when building the flake.
    # For some reason untracked files do not get included in the store, otherwise
    # https://github.com/NixOS/nix/issues/11930
    last-commit-message = {
      url = "path:./last-commit-message";
      flake = false;
    };
  };
  outputs =
    { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      tools = import ./tools/default.nix { inherit inputs; };
    in
    {
      nixosConfigurations = {
        nixos = tools.mkSystem ./nixos/configuration.nix;
      };

      homeManagerModules.default = ./home-manager-modules;
      nixosModules.default = ./nixos-modules;
    };
}
