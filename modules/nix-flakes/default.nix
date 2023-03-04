{ nixpkgs, ... }: lib:
{ pkgs, ... }: {
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # See https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
  nix.registry.nixpkgs.flake = nixpkgs;
}
