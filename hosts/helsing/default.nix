{ nixosWithSystem, ... }: {
  flake.nixosConfigurations.helsing = nixosWithSystem "x86_64-linux" [ ./configuration.nix ];
}
