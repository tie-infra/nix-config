{
  flake.overlays.sonarr-v4 = final: prev: {
    sonarr_4 = final.callPackage ./package.nix { };
  };
}
