{ config, pkgs, lib, ... }:

{
  imports = [
    ./services/polybar/polybar.nix
    ./programs/fuzzel/fuzzel.nix
    ./services/picom/picom.nix
    ./programs/alacritty/alacritty.nix
    # ./programs/android/android.nix
    ./programs/sway/sway.nix
    # ./programs/hyprland/hyprland.nix
    ./services/waybar/waybar.nix
    ./services/wallpaper/wallpaper.nix
    # ./programs/vscode/vscode.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "miro";
  home.homeDirectory = "/home/miro";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.  
  home.stateVersion = "23.05";

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    httpie
    killall
    sublime4
    font-awesome
    (python311.withPackages (ps: with ps; [
    ]))
    cascadia-code
    feh
    discord
    nodejs
    gh
    nodePackages.zx
    # wdisplays
    # kanshi
    distrobox
    swww

    gnome.gnome-software
    networkmanager_dmenu
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  services.gnome-keyring.enable = true;

  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 32;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk.theme.name = "Adwaita-dark";

  # home.file.".xinitrc".source = ./.xinitrc;
  # home.file."wallpaper.png".source = ./wallpaper.png;

  services.wallpaper.enable = true;

  xdg.configFile."networkmanager-dmenu/config.ini".text = ''
    [dmenu]
    dmenu_command = fuzzel --dmenu
    [editor]
    gui_if_available = True
  '';
}
