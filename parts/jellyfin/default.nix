{ self, ... }: {
  flake = {
    nixosModules.jellyfin-dynamic-user = import ./dynamic-user.nix;
    nixosModules.jellyfin-ipv6.nixpkgs.overlays = [ self.overlays.jellyfin-ipv6 ];
    overlays.jellyfin-ipv6 = import ./ipv6.nix;
  };
}
