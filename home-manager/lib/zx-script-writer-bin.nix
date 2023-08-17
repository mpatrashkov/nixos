# This returns a writer that creates an executable Google ZX script in `<pkg>/bin/%name`
# with the provided content. Similar to `writeShellScriptBin`, it consumes the name of
# the script and the NodeJS/ZX-script content as parameters.

{ pkgs }:

name: text:

let
  mjsBin = pkgs.writeTextFile {
    name = "${name}-mjs";
    executable = true;
    # For Google ZX, the .mjs extension is mandatory.
    destination = "/bin/${name}.mjs";
    text = ''
      #!${pkgs.zx}/bin/zx
      ${text}
    '';
  };
in
# Shebang script enables to call the zx-script without the .mjs version.
pkgs.writeTextFile {
  name = "${name}";
  executable = true;
  destination = "/bin/${name}";
  text = ''
    #!${mjsBin}/bin/${name}.mjs
  '';
}
