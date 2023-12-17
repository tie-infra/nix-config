{ self, inputs, lib, package-sets-lib, ... }:
let
  inherit (package-sets-lib)
    concatFilteredPackages
    availableOnHostPlatform;

  installer = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.base-system
      inputs.nixpkgs.nixosModules.readOnlyPkgs
      ./installer.nix
    ];
  };

  # Some packages cannot be cross-compiled from macOS.
  buildPlatformIsNotDarwin =
    { pkgs, ... }: _: !pkgs.stdenv.buildPlatform.isDarwin;
in
{
  perSystem = { config, ... }: {
    packages = concatFilteredPackages buildPlatformIsNotDarwin
      ({ name, pkgs, ... }: {
        "installer-iso-${name}" =
          let cfg = installer.extendModules { modules = [{ nixpkgs.pkgs = pkgs; }]; }; in
          cfg.config.system.build.isoImage;
      })
      { inherit (config.packageSets) x86_64-linux; };
  };
}
