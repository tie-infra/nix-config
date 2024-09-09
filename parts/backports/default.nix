{ inputs, ... }:
{
  flake.overlays.backports = final: _prev: {
    # edac-utils: unstable-2015-01-07 -> unstable-2023-01-30
    # https://github.com/NixOS/nixpkgs/pull/234603
    edac-utils = final.callPackage (
      inputs.nixpkgs-unstable + "/pkgs/os-specific/linux/edac-utils/default.nix"
    ) { };
  };
}
