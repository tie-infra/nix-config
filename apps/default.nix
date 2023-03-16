{ nixpkgs, ... }:
lib:
system:
let
  makeApplication = name: pkg: {
    type = "app";
    program =
      let drv = pkg system;
      in if nixpkgs.lib.isDerivation drv
      then "${drv}/bin/${drv.name}"
      else drv;
  };
in
nixpkgs.lib.mapAttrs makeApplication (lib.importSubdirs ./.)
