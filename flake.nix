{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    agenix.url = "github:ryantm/agenix";
  };

  # TODO nixosConfigurations.${name}.config.system.build.isoImage
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
