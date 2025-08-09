{ ... }:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 3000 ];
  };
}
