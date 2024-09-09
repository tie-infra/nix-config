{ nixosWithSystem, ... }:
{
  flake.nixosConfigurations.saitama = nixosWithSystem "x86_64-linux" [ ./configuration.nix ];
}
