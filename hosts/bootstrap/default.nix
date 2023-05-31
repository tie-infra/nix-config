{ inputs, ... }@args: {
  flake.nixosConfigurations.bootstrap-x86-64 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ({ nixpkgs.hostPlatform.system = "x86_64-linux"; })
      (import ./configuration.nix args)
    ];
  };
}
