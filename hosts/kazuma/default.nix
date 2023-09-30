{ nixosWithSystem, ... }: {
  flake.nixosConfigurations.kazuma = nixosWithSystem "x86_64-linux" [ ./configuration.nix ];
}
