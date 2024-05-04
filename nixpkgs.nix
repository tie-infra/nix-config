{ self, inputs, ... }: {
  perSystem = { system, ... }:
    let
      nixpkgsArgs = {
        localSystem = { inherit system; };

        overlays = [
          self.overlays.backports
          self.overlays.java-wrappers
          self.overlays.jellyfin-wal-backport
          self.overlays.mcactivity
          self.overlays.sonarr-v4
          inputs.steam-games.overlays.default
          inputs.btrfs-rollback.overlays.default
        ];

        config.allowUnfreePredicate = inputs.steam-games.lib.unfreePredicate;
      };

      nixpkgsFun = newArgs: import inputs.nixpkgs (nixpkgsArgs // newArgs);
    in
    {
      _module.args = {
        pkgs = nixpkgsFun { };
        pkgsCross = {
          x86-64 = nixpkgsFun {
            crossSystem.config = "x86_64-unknown-linux-gnu";
          };
        };
      };
    };
}
