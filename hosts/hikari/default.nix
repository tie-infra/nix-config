{ nixosWithSystem, ... }: {
  flake.nixosConfigurations.hikari = nixosWithSystem "x86_64-linux" [ ./configuration.nix ];
}
