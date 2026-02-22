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
        path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
      '';
    };
  };

  boot.supportedFilesystems = [ "ntfs" ];

  # Latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
