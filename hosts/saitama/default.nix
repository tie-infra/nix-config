{ inputs, nixosWithSystem, ... }: {
  flake.nixosConfigurations.saitama = nixosWithSystem "x86_64-linux" [
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    ./configuration.nix
  ];
}
