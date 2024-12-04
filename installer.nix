{ inputs, lib, ... }:
let
  installer = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ./modules/base-configuration.nix
      ./modules/installer.nix
    ];
  };

  isoImageFor =
    pkgs:
    let
      cfg = installer.extendModules {
        modules = [
          inputs.nixpkgs.nixosModules.readOnlyPkgs
          { nixpkgs.pkgs = pkgs; }
        ];
      };
    in
    cfg.config.system.build.isoImage;
in
{
  perSystem =
    { pkgsCross, ... }:
    {
      packages = {
        installer-iso-x86-64 = isoImageFor pkgsCross.x86-64;
      };
    };
}
