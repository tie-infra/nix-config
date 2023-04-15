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

    flake-parts.url = "github:hercules-ci/flake-parts";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    imports = [
      ./hosts/bootstrap
      ./hosts/kazuma
      ./parts/erase-your-darlings
      ./parts/installer
      ./parts/minimal-shell
      ./parts/nix-flakes
      ./parts/ssh-keys
      ./parts/trust-admins
    ];

    perSystem = { self', inputs', pkgs, ... }: {
      formatter = pkgs.nixpkgs-fmt;

      minimalShells.direnv = with pkgs; [
        nixpkgs-fmt
        sops
        ssh-to-age
      ];
    };
  };
}
