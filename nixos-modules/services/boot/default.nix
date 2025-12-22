{
  pkgs,
  ...
}:

{
  # Bootloader
  boot.loader = {
    efi.efiSysMountPoint = "/boot";
    limine = {
      enable = true;
      efiInstallAsRemovable = true;

      extraEntries = ''
        /Windows 11
        protocol: efi
        path: uuid(b1a860f6-3e30-4262-aefb-93b85625b83e):/EFI/Microsoft/Boot/bootmgfw.efi
      '';
    };
  };

  boot.supportedFilesystems = [ "ntfs" ];

  # Latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
