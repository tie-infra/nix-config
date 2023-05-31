{ inputs, ... }@args: {
  flake.nixosConfigurations.saitama = inputs.nixpkgs.lib.nixosSystem {
    modules = [ (import ./configuration.nix args) ];
  };
}
