{
  inputs,
  ...
}:
let
  # The upstream nix/module.nix has a bug in the LUT `apply` function: it uses
  # `t[0]` / `t[1]`, which is invalid Nix (it parses as applying the list `t` to
  # the argument `[0]`) and errors at build time whenever LUT mode is used.
  # Patch the source tree to use `builtins.elemAt` instead, then import the
  # patched module. The module builds the kernel module itself via a relative
  # `./package.nix`, which resolves inside the patched source.
  #
  # `applyPatches` is a pure source transformation, so we build it from a pinned
  # nixpkgs. Using the module-system `pkgs` here would create an infinite
  # recursion (imports -> pkgs -> module config).
  # Patch the FULL repo source (yeetmouse-src), not just the nix/ subdir: the
  # package's fileset uses `root = ./..` and must resolve to the repo root.
  patchPkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
  patchedSrc = patchPkgs.applyPatches {
    name = "yeetmouse-patched";
    src = inputs.yeetmouse-src; # full repo
    # Two upstream bugs in nix/module.nix that break LUT mode at eval/build time:
    #  1. `t[0]`/`t[1]` is invalid Nix list indexing (parses as function application).
    #  2. `value = length params.data;` yields an integer, but the udev rule
    #     interpolates it into a string without `toString`.
    postPatch = ''
      substituteInPlace nix/module.nix \
        --replace-fail \
          'map (t: "''${toString t[0]},''${toString t[1]}") ls' \
          'map (t: "''${toString (builtins.elemAt t 0)},''${toString (builtins.elemAt t 1)}") ls' \
        --replace-fail \
          'value = length params.data;' \
          'value = toString (length params.data);'
    '';
  };

  # module.nix is a curried function `shortRev: { pkgs, config, lib, ... }: ...`
  # Its relative `./package.nix` resolves to ${patchedSrc}/nix/package.nix, whose
  # `root = ./..` correctly points at ${patchedSrc} (the repo root).
  yeetmouseModule = import "${patchedSrc}/nix/module.nix" inputs.yeetmouse.shortRev;
in
{
  imports = [ yeetmouseModule ];

  config = {
    hardware.yeetmouse = {
      enable = true;
      sensitivity = 1.0;

      # Windows "Enhanced Pointer Precision" (EPP) curve as a sensitivity-ratio
      # look-up table. Source: YeetMouse author, issue #67
      # (github.com/AndyFilter/YeetMouse/issues/67). Each pair is
      # [input-speed output-ratio]. Upstream extends to x=140; trimmed at
      # x=98.85 because the module's type caps each point at 100.0 (the driver
      # extrapolates the near-flat tail from the last points).
      mode.lut.data = builtins.fromJSON (builtins.readFile ./windows_lut.json);
    };
  };
}
