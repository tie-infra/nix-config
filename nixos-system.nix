{
  inputs,
  lib,
  withSystem,
  ...
}:
let
  # See https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
  nixpkgsFlakeRegistryModule = {
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
  };

  baseModules = [
    nixpkgsFlakeRegistryModule
    inputs.sops-nix.nixosModules.sops
    ./modules/sops.nix
    ./modules/nix-flakes.nix
    ./modules/tcpmss.nix
    ./modules/machine-info.nix
    ./modules/base-configuration.nix
    ./modules/btrfs-erase-your-darlings.nix
    ./modules/trust-admins.nix
    ./modules/mcactivity.nix
    ./modules/outline.nix
    ./modules/flood.nix
    ./modules/jellyfin.nix
    ./modules/minio.nix
    ./modules/prowlarr.nix
    ./modules/radarr.nix
    ./modules/sonarr.nix
    ./modules/transmission.nix
    ./modules/zapret.nix
    { inherit disabledModules; }
  ];

  disabledModules = [
    "services/misc/jellyfin.nix"
    "services/misc/prowlarr.nix"
    "services/misc/radarr.nix"
    "services/misc/sonarr.nix"
    "services/networking/zapret.nix"
    "services/torrent/flood.nix"
    "services/torrent/transmission.nix"
    "services/web-apps/outline.nix"
    "services/web-servers/minio.nix"
  ];

  nixosSystem =
    pkgs: hostConfigurations:
    lib.nixosSystem {
      modules =
        hostConfigurations
        ++ baseModules
        ++ [
          # Avoid re-evaluating Nixpkgs.
          inputs.nixpkgs.nixosModules.readOnlyPkgs
          { nixpkgs.pkgs = pkgs; }
        ];
    };
in
{
  _module.args.nixosWithSystem =
    system: hostConfigurations: withSystem system ({ pkgs, ... }: nixosSystem pkgs hostConfigurations);
}
