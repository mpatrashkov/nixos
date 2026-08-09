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

    yeetmouse = {
      url = "github:AndyFilter/YeetMouse?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Full repo source (not just the nix/ subdir) — needed because the
    # package's fileset uses `root = ./..`, which must resolve to the repo root.
    yeetmouse-src = {
      url = "github:AndyFilter/YeetMouse";
      flake = false;
    };

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

    opencode-src = {
      url = "github:anomalyco/opencode/v1.18.15";
      flake = false;
    };

    another-window-session-manager-src = {
      url = "github:nlpsuge/gnome-shell-extension-another-window-session-manager/cf23fef152ce90692fc1df984f6fd945725334be";
      flake = false;
    };

    whitesur-wallpapers-src = {
      url = "github:vinceliuice/WhiteSur-wallpapers/5c1d7ca20b8de0a7efe443792c19e49277262e02";
      flake = false;
    };

    hatter-icon-theme-src = {
      url = "github:Mibea/Hatter/a6ad2f74f07f66df9cb4e9e85653cd1bd90539d7";
      flake = false;
    };

    vlc-pause-click-plugin-src = {
      url = "github:nurupo/vlc-pause-click-plugin/2.2.0";
      flake = false;
    };

    tmux-fzf-links-src = {
      url = "github:alberti42/tmux-fzf-links/1.4.15";
      flake = false;
    };

    tmux-super-fingers-src = {
      url = "github:artemave/tmux_super_fingers/523dc9b7a79f1ceb8d9be72e22c263c4a7cd3bdf";
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

      nixosModules.default = ./nixos-modules;
    };
}
