{ config, pkgs, lib, ... }:

{
  imports = [
    ./programs/rofi-wayland-unwrapped/rofi-wayland-unwrapped.nix
    ./programs/alacritty/alacritty.nix
    ./services/waybar/waybar.nix
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

    cinnamon.nemo
    insomnia
    webcord
    github-desktop
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

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
      name = "oomox-gruvbox-dark";
      package = pkgs.gruvbox-dark-icons-gtk;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  # qt = {
  #   enable = true;
  #   platformTheme = "gnome";
  #   style = {
  #     name = "adwaita-dark";
  #   };
  # };

  xdg.configFile."networkmanager-dmenu/config.ini".text = ''
    [dmenu]
    dmenu_command = rofi -dmenu -i
    [editor]
    gui_if_available = True
  '';

  xdg.desktopEntries = {
    insomnia = {
      # TODO: Add icon
      name = "Insomnia";
      genericName = "GraphQL;REST;gRPC;SOAP;openAPI;GitOps;";
      exec = "insomnia --enable-features=UseOzonePlatform --ozone-platform=wayland %U";
      terminal = false;
      categories = [ "Development" ];
      mimeType = [ "text/html" "text/xml" ];
    };
  };

  # xdg.configFile."sway/config".source = ./config/sway;
  # xdg.configFile."hyprland/config".source = ./config/hyprland.conf;
  # home.file.".config/hypr/hyprland-start.sh".source = ./config/hyprland-start.sh;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  services.xembed-sni-proxy = {
    enable = true;
  };
}
