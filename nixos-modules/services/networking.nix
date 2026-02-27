{ pkgs, ... }:
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

  # Fix for random network disconnects on Intel I225-V Ethernet, which is caused by aggressive power management (ASPM).
  systemd.services.disable-igc-aspm = {
    description = "Disable ASPM for Intel I225-V Ethernet";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Clear the ASPM L0s/L1 bits (the first two bits of the Link Control register)
      # The '-' prefix tells systemd to continue even if the command fails (e.g., if the PCI path changes)
      ExecStart = [
        "-${pkgs.pciutils}/bin/setpci -s 0000:00:1c.2 CAP_EXP+10.b=00"
        "-${pkgs.pciutils}/bin/setpci -s 0000:06:00.0 CAP_EXP+10.b=00"
      ];
    };
  };
}
