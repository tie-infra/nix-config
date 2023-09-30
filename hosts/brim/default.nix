{ nixosWithSystem, ... }: {
  flake.nixosConfigurations.brim = nixosWithSystem "x86_64-linux" [ ./configuration.nix ];
}
