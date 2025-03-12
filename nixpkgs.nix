{ inputs, lib, ... }:
{
  perSystem =
    { system, ... }:
    let
      nixpkgsArgs = {
        localSystem = {
          inherit system;
        };

        overlays = [
          inputs.steam-games.overlays.default
          inputs.btrfs-rollback.overlays.default
          (import ./overlays/java-wrappers.nix)
          (import ./overlays/mcactivity.nix)
          (import ./overlays/zapret/default.nix)
        ];

        config.allowUnfreePredicate =
          let
            allowUnfree = {
              steamworks-sdk-redist = true;
              satisfactory-server = true;
              palworld-server = true;
              eco-server = true;
              outline = true;
            };
          in
          pkg: builtins.hasAttr (lib.getName pkg) allowUnfree;
      };

      nixpkgsFun = newArgs: import inputs.nixpkgs (nixpkgsArgs // newArgs);
    in
    {
      _module.args = {
        pkgs = nixpkgsFun { };
        pkgsCross = {
          x86-64 = nixpkgsFun { crossSystem.config = "x86_64-unknown-linux-gnu"; };
        };
      };
    };
}
