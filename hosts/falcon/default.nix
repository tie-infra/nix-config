{ nixosWithSystem, ... }:
{
  flake.nixosConfigurations.falcon = nixosWithSystem "x86_64-linux" [
    ./configuration.nix
    ./networking.nix
  ];
}
