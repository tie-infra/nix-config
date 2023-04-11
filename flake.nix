{
  description = "NixOS configuration";

  inputs = {
    # Currently using fork with
    # - https://github.com/NixOS/nixpkgs/pull/219351 (disable BIOS boot for ISO)
    # - https://github.com/NixOS/nixpkgs/pull/220506 (update pufferpanel)
    # - https://github.com/NixOS/nixpkgs/pull/225379 (add myself pufferpanel maintainers)
    # - https://github.com/NixOS/nixpkgs/pull/225274 (pufferpanel module)
    # - https://github.com/NixOS/nixpkgs/pull/205557 (concatLines for pufferpanel module)
    #nixpkgs.url = "nixpkgs/nixos-22.11";
    nixpkgs.url = "github:tie-infra/nixpkgs/nixos-22.11";
    agenix.url = "github:ryantm/agenix";
  };

  outputs = inputs:
    let lib = import ./lib inputs;
    in {
      apps = lib.forAllSystems (lib.import ./apps);
      packages = lib.forAllSystems (lib.import ./pkgs);
      devShells = lib.forAllSystems (lib.import ./shell);
      formatter = lib.forAllSystems (system: inputs.nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      nixosModules = lib.importSubdirs ./modules;
      nixosConfigurations = lib.import ./systems;
    };
}
