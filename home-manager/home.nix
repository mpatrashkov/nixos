{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./programs/rofi-wayland-unwrapped/rofi-wayland-unwrapped.nix
    # ./programs/alacritty/alacritty.nix
    ./programs/fish/fish.nix
    ./programs/hyprland/hyprland.nix
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
    (python311.withPackages (
      ps: with ps; [
      ]
    ))
    cascadia-code
    feh
    nodejs
    gh
    nodePackages.zx
    # wdisplays
    # kanshi
    distrobox
    swww

    gnome-software
    networkmanager_dmenu
    spotify

    adwaita-icon-theme

    htop
    playerctl
    qbittorrent
    bitwarden-cli
    ngrok
    ddcutil

    # jdk17
    prismlauncher
    # android-studio

    gnome-system-monitor
    libreoffice
    dconf-editor

    nemo
    webcord
    github-desktop
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  gtk = {
    enable = true;
    iconTheme = {
      name = "oomox-gruvbox-dark";
      package = pkgs.gruvbox-dark-icons-gtk;
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

  xdg.configFile."networkmanager-dmenu/config.ini".text = ''
    [dmenu]
    dmenu_command = rofi -dmenu -i
    [editor]
    gui_if_available = True
  '';

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  services.xembed-sni-proxy = {
    enable = true;
  };
}
