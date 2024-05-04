{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";

    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs-unstable.flake = false;

    flake-parts.url = "flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nixos-hardware.url = "nixos-hardware";

    sops-nix.url = "sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";

    minimal-shell.url = "github:tie-infra/minimal-shell";

    btrfs-rollback.url = "github:tie-infra/btrfs-rollback";
    btrfs-rollback.inputs.nixpkgs.follows = "nixpkgs";
    btrfs-rollback.inputs.flake-parts.follows = "flake-parts";

    steam-games.url = "github:tie-infra/steam-games";
    steam-games.inputs.nixpkgs.follows = "nixpkgs";
    steam-games.inputs.flake-parts.follows = "flake-parts";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];

    imports = [
      inputs.minimal-shell.flakeModule
      ./nixpkgs.nix
      ./top-level.nix
    ];
  };
}
