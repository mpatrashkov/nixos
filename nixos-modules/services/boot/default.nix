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
      style.wallpapers = [ ./22.png ];
    };
  };

  boot.supportedFilesystems = [ "ntfs" ];

  # Latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
