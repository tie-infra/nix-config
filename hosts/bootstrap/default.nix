{ nixosWithSystem, ... }: {
  flake.nixosConfigurations.bootstrap-x86-64 = nixosWithSystem "x86_64-linux" [ ./configuration.nix ];
}
