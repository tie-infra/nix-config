{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";

    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs-unstable.flake = false;

    # Waiting for backport in https://github.com/NixOS/nixpkgs/pull/258111
    nixpkgs-backport-242191.url = "nixpkgs/backport-242191-to-release-23.05";
    nixpkgs-backport-242191.flake = false;

    systems.url = "systems";

    flake-parts.url = "flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nixos-hardware.url = "nixos-hardware";

    sops-nix.url = "sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";

    package-sets.url = "github:tie-infra/package-sets";
    minimal-shell.url = "github:tie-infra/minimal-shell";

    btrfs-rollback.url = "github:tie-infra/btrfs-rollback";
    btrfs-rollback.inputs.nixpkgs.follows = "nixpkgs";
    btrfs-rollback.inputs.flake-parts.follows = "flake-parts";

    steam-games.url = "github:tie-infra/steam-games";
    steam-games.inputs.nixpkgs.follows = "nixpkgs";
    steam-games.inputs.flake-parts.follows = "flake-parts";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import inputs.systems;

    imports = [
      inputs.package-sets.flakeModule
      inputs.minimal-shell.flakeModule
      ./nixpkgs.nix
      ./top-level.nix
    ];
  };
}
