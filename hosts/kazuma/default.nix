{ inputs, ... }@args: {
  flake.nixosConfigurations.kazuma = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ({ nixpkgs.hostPlatform.system = "x86_64-linux"; })
      (import ./configuration.nix args)
    ];
  };
}
