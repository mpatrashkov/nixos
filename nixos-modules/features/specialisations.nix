{ ... }:
{
  # Default specialisation
  myNixOS.services.gnome.enable = false;

  config.specialisation = {
    gnome.configuration = {
      myNixOS.services.gnome.enable = true;
    };
  };
}
