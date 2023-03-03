{
  description = "NixOS configuration";

  inputs = {
    # Currently using fork with https://github.com/NixOS/nixpkgs/pull/219351
    #nixpkgs.url = "nixpkgs/nixos-22.11";
    nixpkgs.url = "github:tie-infra/nixpkgs/nixos-22.11";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = inputs:
    let lib = import ./lib inputs;
    in {
      nixosModules = lib.importSubdirs ./modules;
      nixosConfigurations = lib.import ./systems;
      packages = lib.forAllSystems (lib.import ./pkgs);
      devShells = lib.forAllSystems (lib.import ./shell);
      formatter = lib.forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
