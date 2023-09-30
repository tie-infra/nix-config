{ nixosWithSystem, ... }: {
  flake.nixosConfigurations.akane = nixosWithSystem "x86_64-linux" [ ./configuration.nix ];
}
