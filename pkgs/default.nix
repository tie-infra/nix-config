{ nixpkgs, ... }:
lib:
system:
lib.mergePackages (
  nixpkgs.lib.mapAttrs (_: pkg: pkg system) (lib.importSubdirs ./.)
)
