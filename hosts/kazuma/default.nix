{ inputs, ... }@args: {
  flake.nixosConfigurations.kazuma = inputs.nixpkgs.lib.nixosSystem {
    modules = [ (import ./configuration.nix args) ];
  };
}
