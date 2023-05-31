{ inputs, ... }@args: {
  flake.nixosConfigurations.brim = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ({ nixpkgs.hostPlatform.system = "x86_64-linux"; })
      (import ./configuration.nix args)
    ];
  };
}
