# Steam-specific tweaks and workarounds.
#
# Recommended per-game launch options:
#
#   LD_PRELOAD="" gamescope --mangoapp -H 2160 -f -r 60 -- %command%
#
# Why run games through gamescope:
#   XWayland and fractional scaling don't cooperate well — games end up rendering
#   at the scaled resolution and getting upscaled by XWayland, which looks blurry
#   and hurts performance. Wrapping the game in gamescope makes it render at the
#   native resolution and lets gamescope handle the scaling instead.
#
# gamescope flags used above:
#   -H 2160     Output height in pixels (4K). Adjust to your display.
#   -f          Run fullscreen.
#   -r 60       Cap the refresh rate at 60 Hz. Empirically improves performance
#               in some games; worth experimenting with per game.
#   --mangoapp  Render the MangoHud overlay as a separate gamescope client
#               (more reliable than loading the MangoHud Vulkan layer into the
#               game process).
#
# Why LD_PRELOAD="":
#   Steam injects libraries via LD_PRELOAD that, in some games, cause progressive
#   lag/stutter after ~30 minutes of play. Clearing LD_PRELOAD for the game's
#   process avoids this. Upstream issue:
#   https://github.com/ValveSoftware/steam-for-linux/issues/11446

{ config, pkgs, ... }:

{
  programs.steam = {
    enable = true;

    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];

    package = pkgs.steam.override {
      extraPkgs =
        pkgs: with pkgs; [
          libkrb5
          keyutils
          libxcb
          mangohud
        ];
    };
  };

  systemd.user.services.steam = {
    description = "Steam (silent autostart)";
    after = [
      "graphical-session.target"
      "gnome-session-manager.target"
    ];
    requisite = [ "gnome-session-manager.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    path = [ pkgs.gamescope ];
    serviceConfig = {
      ExecStart = "${config.programs.steam.package}/bin/steam -silent";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  programs.gamescope = {
    enable = true;
    # `capSysNice` is intentionally left at its default (false). See the
    # ananicy block below for the reason and the workaround.
  };

  # Gamescope + CAP_SYS_NICE workaround.
  #
  # Problem:
  #   Gamescope wants CAP_SYS_NICE so it can renice itself for low-latency
  #   presentation. The nixpkgs option `programs.gamescope.capSysNice` is
  #   supposed to grant this by setting a file capability on the gamescope
  #   binary. In practice, when Steam launches a game through gamescope the
  #   capability is either never granted or stripped along the runtime/wrapper
  #   path, and the game fails to launch at all.
  #
  # Upstream tracking:
  #   https://github.com/NixOS/nixpkgs/issues/217119
  #   https://github.com/NixOS/nixpkgs/issues/351516
  #
  # Workaround:
  #   Run `ananicy-cpp`, a userspace daemon that watches processes and applies
  #   nice / scheduling / I/O-class adjustments from the outside based on a
  #   rules database. Because it acts on gamescope externally (as root), no
  #   file capability needs to be granted to the binary — ananicy bumps
  #   gamescope's nice value to a strongly negative number once it is running.
  #   End-state matches what `capSysNice = true` was supposed to achieve,
  #   without the capability plumbing that breaks Steam.
  #
  # Ruleset:
  #   `ananicy-rules-cachyos` is the most actively maintained ananicy ruleset.
  #   It covers gamescope plus sensible desktop/gaming defaults (compilers →
  #   SCHED_BATCH, games → high priority, indexers → SCHED_IDLE, etc.).
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # `steam-tui` couldn't be made to work reliably; left disabled for now.
  # environment.systemPackages = with pkgs; [
  #   steam-tui
  #   steamcmd
  # ];
}
