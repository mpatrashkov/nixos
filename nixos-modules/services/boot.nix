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
    };
  };

  boot.supportedFilesystems = [ "ntfs" ];

  # Latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
