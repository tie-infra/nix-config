{ self, inputs, lib, ... }: {
  perSystem = { system, config, ... }:
    let
      nixpkgsArgs = {
        localSystem = { inherit system; };

        overlays = [
          self.overlays.backports
          self.overlays.java-wrappers
          self.overlays.jellyfin-wal-backport
          self.overlays.sonarr-v4
          inputs.steam-games.overlays.default
          inputs.btrfs-rollback.overlays.default
        ];

        config.allowUnfreePredicate = inputs.steam-games.lib.unfreePredicate;
      };

      nixpkgsFun = newArgs: import inputs.nixpkgs (nixpkgsArgs // newArgs);

      pkgs = nixpkgsFun { };
    in
    {
      _module.args.pkgs = pkgs;

      packageSets = {
        default = { inherit pkgs; };
        x86_64-linux.pkgs = nixpkgsFun {
          # FIXME: we cannot use pkgsCross or crossSystem.config. Keep this
          # definition identical to localSystem until NixOS is released with
          # the fix. See https://github.com/NixOS/nixpkgs/pull/254763
          crossSystem.system = "x86_64-linux";
        };
      };
    };
}
