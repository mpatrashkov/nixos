## Useful commands

### Reset monitor config - https://unix.stackexchange.com/a/801854
```
gdctl set -LM DP-4 -ps 1
```

## Known issues

- There is an issue with Spotify on wayland, which causes the spotify client to have ugly windows border. See `nixos-modules/programs/spotify.nix`.


## Future improvements

- Decide if `npins` is a suitable flake replacement, as flakes have to many limitation regarding pure elevation. See `nixos-modules/features/generations/default.nix`.