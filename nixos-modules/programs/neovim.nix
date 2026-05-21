{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  environment.systemPackages = with pkgs; [
    gcc # Required for nvim-treesitter parser compilation
    gnumake
    ripgrep
    fd
    imagemagick # For snacks.nvim image preview
    prettier
    svelte-language-server
    typescript-language-server
    typescript
  ];
}
