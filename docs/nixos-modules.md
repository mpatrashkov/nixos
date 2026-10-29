# Opt-in NixOS modules

All custom switches default to `false`. Importing `nixos-modules/` registers modules; it does not select them. This does not change upstream NixOS defaults.

Hosts select profiles under `myNixOS.profiles`:

| Profile | Includes |
| --- | --- |
| `base` | Shared user and locale, Fish, CLI/Nix utilities, Stow, generation metadata |
| `development` | Editors, Git/JJ, AI and development tools, tmux |
| `desktop` | GNOME, audio, fonts, theme, terminal, graphical apps |
| `gaming` | Steam and games |
| `dns` | AdGuard Home and dnscrypt-proxy2 |

Profiles are independent: `desktop` does not implicitly enable `base`, `development`, `gaming`, or `dns`. Host-specific boot, networking, Keychron, and YeetMouse selections remain in the host configuration.

```nix
myNixOS = {
  profiles = {
    base.enable = true;
    development.enable = true;
    desktop.enable = true;
  };

  # Profiles use mkDefault, so ordinary false overrides their selections.
  programs.spotify.enable = false;

  # Individual modules can also be selected without a profile.
  services.boot.enable = true;
};
```

## Adding modules

Place a module in `nixos-modules/services/`, `programs/`, or `features/`. The loader creates `myNixOS.<category>.<filename>.enable` using `mkEnableOption`, and gates its configuration on that switch. A directory with `default.nix` works as a module too.

A new module remains disabled until explicitly selected by a host or added to a profile. Profile membership is declared in `nixos-modules/profiles/` with `lib.mkDefault true`; profiles themselves use the same opt-in loader.

The loader's `imports` and option declarations are unconditional. Imported configuration fragments must respect their parent module's switch. Check upstream modules for enabled-by-default behavior too; `programs/nix-index-database.nix` explicitly connects the upstream switch to ours.

Do not add documentation or other non-module files to these auto-discovered directories. Do not select the deprecated Home Manager feature in a profile.

## Evaluation checks

```sh
nix eval --raw .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.wsl.config.system.build.toplevel.drvPath
```

These evaluate only; they do not activate a configuration. Use the approved rebuild workflow for a test activation or switch.
