{ self, ... }: {
  flake = {
    overlays.jellyfin-ipv6 = import ./overlay.nix;
    nixosModules.jellyfin-ipv6.nixpkgs.overlays = [ self.overlays.jellyfin-ipv6 ];
  };
}
