{ config, pkgs, lib, ... }:

{
  imports = [
    ./services/polybar/polybar.nix
    ./programs/rofi-wayland-unwrapped/rofi-wayland-unwrapped.nix
    ./services/picom/picom.nix
    ./programs/alacritty/alacritty.nix
    # ./programs/android/android.nix
    ./programs/sway/sway.nix
    # ./programs/hyprland/hyprland.nix
    ./services/waybar/waybar.nix
    ./services/wallpaper/wallpaper.nix
    # ./programs/vscode/vscode.nix
    ./programs/zsh/zsh.nix
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
    spotify

    gnome.adwaita-icon-theme

    (import ./programs/set-wallpaper/set-wallpaper.nix { inherit pkgs; })

    htop
    playerctl
    qbittorrent
    mangohud
    bitwarden-cli
    ngrok
    ddcutil
    
    # jdk17
    prismlauncher
    # android-studio

    gnome.gnome-system-monitor
    libreoffice
    chromium
    gnome.dconf-editor
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  services.gnome-keyring.enable = true;

  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 32;
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      # name = "Materia-dark";
      # package = pkgs.materia-theme;
      name = "Gruvbox-Dark-B";
      package = pkgs.gruvbox-gtk-theme;
      # package = pkgs.gnome.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.gruvbox-dark-icons-gtk;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  # qt = {
  #   enable = true;
  #   platformTheme = "gnome";
  #   style = {
  #     name = "adwaita-dark";
  #   };
  # };

  services.wallpaper.enable = true;

  xdg.configFile."networkmanager-dmenu/config.ini".text = ''
    [dmenu]
    dmenu_command = rofi -dmenu -i
    [editor]
    gui_if_available = True
  '';
}
