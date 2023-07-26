# { config, pkgs, lib, ... }:

# {
#     systemd.timers."swww" = {
#         wantedBy = [ "timers.target" ];
#         timerConfig = {
#             OnCalendar = "hourly";
#             Unit = "swww.service";
#         };
#     };

#     systemd.services."swww" = {
#         script = builtins.readFile ./swww.sh;
#         serviceConfig = {
#             Type = "oneshot";
#             User = "root";
#         };
#     };
# }

{ config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.wallpaper;
in {
  options = {
    services.wallpaper = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to enable wallpaper.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    systemd.user.timers."swww" = {
        Install = {
            WantedBy = [ "timers.target" ];
        };
        Timer = {
            OnBootSec = "1s";
            OnCalendar = "hourly";
            Unit = "swww.service";
        };
    };

    systemd.user.services."swww" = {
        Unit = {
          Description = "Manage time sensitive wallpapers with swww";
          After = [ "sway-session.target" ];
        };

        Service = {
            Type = "oneshot";
            ExecStart = 
              let setWalllpaper = (import ../../programs/set-wallpaper/set-wallpaper.nix { inherit pkgs; });
              in "${setWalllpaper}/bin/set-wallpaper";
        };
    };
  };
}