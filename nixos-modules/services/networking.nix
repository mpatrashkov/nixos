{ ... }:
{
  networking = {
    hostName = "nixos";
    nameservers = [
      "127.0.0.1"
      "::1"
    ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 3000 ];
  };
}
