{ pkgs }:

pkgs.writeShellApplication {
  name = "wlsunset-toggle";

  runtimeInputs = [ pkgs.wlsunset ];

  text = ''
    #!/usr/bin/bash
    if pidof wlsunset; then
        killall -9 wlsunset
    else
        wlsunset -l 42.5 -L 27.4
    fi
  '';
}
