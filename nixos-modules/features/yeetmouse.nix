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
      mode.lut.data = [
        [
          1.505
          0.5684
        ]
        [
          1.519
          0.5711
        ]
        [
          1.562
          0.5788
        ]
        [
          1.632
          0.5908
        ]
        [
          1.731
          0.6059
        ]
        [
          1.858
          0.6229
        ]
        [
          2.014
          0.6409
        ]
        [
          2.197
          0.6588
        ]
        [
          2.409
          0.676
        ]
        [
          2.65
          0.6923
        ]
        [
          2.918
          0.7073
        ]
        [
          3.215
          0.7209
        ]
        [
          3.54
          0.7332
        ]
        [
          3.893
          0.7443
        ]
        [
          4.275
          0.7542
        ]
        [
          4.684
          0.7923
        ]
        [
          5.122
          0.8357
        ]
        [
          5.589
          0.8743
        ]
        [
          6.083
          0.9088
        ]
        [
          6.606
          0.9397
        ]
        [
          7.157
          0.9673
        ]
        [
          7.737
          0.9922
        ]
        [
          8.344
          1.014
        ]
        [
          8.98
          1.035
        ]
        [
          9.644
          1.053
        ]
        [
          10.34
          1.069
        ]
        [
          11.06
          1.084
        ]
        [
          11.81
          1.098
        ]
        [
          12.58
          1.11
        ]
        [
          13.39
          1.122
        ]
        [
          14.22
          1.201
        ]
        [
          15.08
          1.286
        ]
        [
          15.97
          1.364
        ]
        [
          16.89
          1.436
        ]
        [
          17.84
          1.502
        ]
        [
          18.82
          1.563
        ]
        [
          19.82
          1.62
        ]
        [
          20.85
          1.673
        ]
        [
          21.91
          1.722
        ]
        [
          23.0
          1.767
        ]
        [
          24.11
          1.81
        ]
        [
          25.26
          1.849
        ]
        [
          26.43
          1.886
        ]
        [
          27.63
          1.921
        ]
        [
          28.86
          1.954
        ]
        [
          30.12
          1.984
        ]
        [
          31.41
          2.013
        ]
        [
          32.72
          2.04
        ]
        [
          34.06
          2.065
        ]
        [
          35.43
          2.089
        ]
        [
          36.83
          2.112
        ]
        [
          38.26
          2.133
        ]
        [
          39.71
          2.153
        ]
        [
          41.2
          2.172
        ]
        [
          42.71
          2.19
        ]
        [
          44.25
          2.208
        ]
        [
          45.82
          2.224
        ]
        [
          47.42
          2.239
        ]
        [
          49.04
          2.254
        ]
        [
          50.69
          2.268
        ]
        [
          52.38
          2.282
        ]
        [
          54.09
          2.294
        ]
        [
          55.82
          2.306
        ]
        [
          57.59
          2.318
        ]
        [
          59.38
          2.329
        ]
        [
          61.21
          2.34
        ]
        [
          63.06
          2.35
        ]
        [
          64.94
          2.359
        ]
        [
          66.85
          2.369
        ]
        [
          68.78
          2.378
        ]
        [
          70.75
          2.386
        ]
        [
          72.74
          2.394
        ]
        [
          74.76
          2.402
        ]
        [
          76.81
          2.41
        ]
        [
          78.88
          2.417
        ]
        [
          80.99
          2.424
        ]
        [
          83.12
          2.431
        ]
        [
          85.29
          2.437
        ]
        [
          87.48
          2.443
        ]
        [
          89.69
          2.449
        ]
        [
          91.94
          2.455
        ]
        [
          94.22
          2.46
        ]
        [
          96.52
          2.466
        ]
        [
          98.85
          2.471
        ]
      ];
    };
  };
}
