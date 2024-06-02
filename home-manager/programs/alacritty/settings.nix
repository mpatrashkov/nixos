{
  env = {
    "TERM" = "xterm-256color";
  };

  window.opacity = 1;

  window = {
    padding.x = 10;
    padding.y = 10;
    decorations = "None";
  };

  font = {
    size = 12.0;

    normal.family = "Cascadia Code";
    bold.family = "Cascadia Code";
    italic.family = "Cascadia Code";
  };

  cursor.style = "Beam";

  keyboard.bindings = [
    {
      key = "C";
      mods = "Control";
      action = "Copy";
    }
    {
      key = "V";
      mods = "Control";
      action = "Paste";
    }
    {
      key = "C";
      mods = "Super";
      chars = "\\u0003";
    }
  ];

  colors = {
    # Default colors
    primary = {
      background = "0x1d2021";
      foreground = "0xd4be98";
    };

    # Normal colors
    normal = {
      black = "0x32302f";
      red = "0xea6962";
      green = "0xa9b665";
      yellow = "0xd8a657";
      blue = "0x7daea3";
      magenta = "0xd3869b";
      cyan = "0x89b482";
      white = "0xd4be98";
    };

    # Bright colors
    bright = {
      black = "0x32302f";
      red = "0xea6962";
      green = "0xa9b665";
      yellow = "0xd8a657";
      blue = "0x7daea3";
      magenta = "0xd3869b";
      cyan = "0x89b482";
      white = "0xd4be98";
    };
  };
}
