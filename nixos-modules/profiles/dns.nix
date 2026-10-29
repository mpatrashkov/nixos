{ lib, ... }:

{
  myNixOS.services = {
    adguardhome.enable = lib.mkDefault true;
    dnscrypt-proxy2.enable = lib.mkDefault true;
  };
}
