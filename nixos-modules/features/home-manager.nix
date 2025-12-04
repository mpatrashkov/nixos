{
  inputs,
  outputs,
  tools,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  config = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    home-manager.extraSpecialArgs = { inherit inputs outputs tools; };
    home-manager.sharedModules = [ outputs.homeManagerModules.default ];

    home-manager.users.miro = ../../home-manager/home.nix;
  };
}
