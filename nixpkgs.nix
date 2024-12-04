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
          (import ./overlays/sonarr_4.nix)
          (final: _: {
            # edac-utils: unstable-2015-01-07 -> unstable-2023-01-30
            # https://github.com/NixOS/nixpkgs/pull/234603
            edac-utils = final.callPackage (inputs.nixpkgs-unstable + "/pkgs/os-specific/linux/edac-utils") { };
          })
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
