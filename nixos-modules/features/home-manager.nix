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

    home-manager.users.miro = {
      home.username = "miro";
      home.homeDirectory = "/home/miro";
      home.stateVersion = "23.05";
    };
  };
}
