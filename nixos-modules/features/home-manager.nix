{ pkgs
, inputs
, ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  config = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    home-manager.users.miro = import ../../home-manager/home.nix;
  };
}
