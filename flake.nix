{
  description = "NixOS configuration";

  inputs = {
    # Currently using fork with
    # - https://github.com/NixOS/nixpkgs/pull/242191 (nixos/networkd: allow state ranges in RequiredForOnline)
    # - https://github.com/NixOS/nixpkgs/pull/236930 (update libgdiplus)
    # - https://github.com/NixOS/nixpkgs/pull/234603 (edac-utils: fixup edac-ctl perl shebang)
    # - https://github.com/NixOS/nixpkgs/pull/234124 (pufferpanel: build frontend from source)
    #nixpkgs.url = "nixpkgs/nixos-23.05";
    nixpkgs.url = "github:tie-infra/nixpkgs/nixos-23.05";

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
