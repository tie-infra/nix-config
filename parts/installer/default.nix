{
  self,
  inputs,
  lib,
  ...
}:
let
  installer = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.base-system
      inputs.nixpkgs.nixosModules.readOnlyPkgs
      ./installer.nix
    ];
  };

  isoImageFor =
    pkgs:
    let
      cfg = installer.extendModules { modules = [ { nixpkgs.pkgs = pkgs; } ]; };
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
