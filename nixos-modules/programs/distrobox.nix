{ pkgs, ... }:

{
  # TODO: maybe replace with podman - https://wiki.nixos.org/wiki/Distrobox
  # Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";

  environment.systemPackages = [ pkgs.distrobox ];
}
