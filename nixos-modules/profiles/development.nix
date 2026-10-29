{ lib, ... }:

{
  myNixOS.programs = {
    ai.enable = lib.mkDefault true;
    devtools.enable = lib.mkDefault true;
    direnv.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    neovim.enable = lib.mkDefault true;
    nix-prefetch-github.enable = lib.mkDefault true;
    nixd.enable = lib.mkDefault true;
    tmux.enable = lib.mkDefault true;
    worktrunk.enable = lib.mkDefault true;
    zx.enable = lib.mkDefault true;
  };
}
