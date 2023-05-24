{
  description = "NixOS configuration";

  inputs = {
    # Currently using fork with
    # - no PR yet (eco-server package)
    #nixpkgs.url = "nixpkgs/nixos-23.05";
    nixpkgs.url = "github:tie-infra/nixpkgs/nixos-23.05";

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
