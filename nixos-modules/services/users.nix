{ ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.miro = {
    isNormalUser = true;
    description = "Miroslav Patrashkov";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "docker"
      "input"
      "kvm"
      "adbusers"
      "i2c"
      "dialout"
      "ydotool"
    ];
  };

  security.sudo.extraConfig = ''
    Defaults pwfeedback
    miro ALL=(ALL:ALL) NOPASSWD: SETENV: /run/current-system/sw/bin/nixos-rebuild
  '';
}
