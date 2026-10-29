{ pkgs, ... }:

{
  # Developer man pages: syscalls (2), libc (3), POSIX (0p/1p/3p)
  documentation.dev.enable = true;

  environment.systemPackages = with pkgs; [
    devenv
    man-pages
    man-pages-posix
  ];
}
