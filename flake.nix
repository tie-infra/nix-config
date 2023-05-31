{
  description = "NixOS configuration";

  inputs = {
    # Currently using fork with
    # - no PR yet (eco-server package)
    # - https://github.com/NixOS/nixpkgs/pull/234603 (edac-utils: fixup edac-ctl perl shebang)
    # - https://github.com/NixOS/nixpkgs/pull/234124 (pufferpanel: build frontend from source)
    #nixpkgs.url = "nixpkgs/nixos-23.05";
    nixpkgs.url = "github:tie-infra/nixpkgs/nixos-23.05";

    systems.url = "systems";

    flake-parts.url = "flake-parts";

    sops-nix.url = "sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    minimal-shell.url = "github:tie-infra/minimal-shell";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import inputs.systems;

    imports = [
      inputs.minimal-shell.flakeModule
      ./hosts/bootstrap
      ./hosts/kazuma
      ./parts/base-system
      ./parts/erase-your-darlings
      ./parts/installer
      ./parts/jellyfin-ipv6
      ./parts/nix-flakes
      ./parts/ssh-keys
      ./parts/trust-admins
    ];

    perSystem = { pkgs, ... }: {
      formatter = pkgs.nixpkgs-fmt;

      minimalShells.direnv = with pkgs; [
        nixpkgs-fmt
        sops
        ssh-to-age
      ];
    };
  };
}
