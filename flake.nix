{
  description = "Your new nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs"; # MESA/OpenGL HW workaround
    };
  };
  outputs = { nixpkgs, home-manager, ... } @ inputs:
    let
      system = "x86_64-linux";
      tools = import ./tools/default.nix { inherit inputs; };
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            # Required for sublime4
            "openssl-1.1.1u"
            "openssl-1.1.1v"
            "openssl-1.1.1w"
          ];
        };
      };
    in
    {
      nixosConfigurations = {
        nixos = tools.mkSystem ./nixos/configuration.nix;
      };
      homeConfigurations = {
        miro = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home-manager/home.nix
          ];
        };
      };

      nixosModules.default = ./nixos-modules;
    };
}
