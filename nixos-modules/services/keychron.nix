{ config, lib, ... }:

let
  cfg = config.myNixOS.services.keychron;
in {
  config = lib.mkIf cfg.enable {
    services.udev.extraRules = ''
      # Keychron keyboard rule for VIA / Launcher web apps
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="0b30", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
  };
}
