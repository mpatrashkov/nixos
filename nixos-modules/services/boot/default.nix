{
  pkgs,
  ...
}:

{
  # Bootloader
  boot.loader = {
    efi = {
      efiSysMountPoint = "/boot";
      canTouchEfiVariables = false;
    };

    limine = {
      enable = true;
      efiInstallAsRemovable = true;

      extraEntries = ''
        /Windows 11
        protocol: efi
        path: uuid(0c96b87f-8fdf-431b-b63e-f028ce90a4ea):/EFI/Microsoft/Boot/bootmgfw.efi
      '';
    };
  };

  boot.supportedFilesystems = [ "ntfs" ];

  # Latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
