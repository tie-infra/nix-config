{
  imports = [
    ./secrets

    ./hosts/akane
    ./hosts/bootstrap
    ./hosts/brim
    ./hosts/helsing
    ./hosts/kazuma
    ./hosts/saitama

    ./parts/backports
    ./parts/base-system
    ./parts/erase-your-darlings
    ./parts/installer
    ./parts/java-wrappers
    ./parts/machine-info
    ./parts/mcactivity
    ./parts/nix-flakes
    ./parts/nixos-with-system
    ./parts/services
    ./parts/sonarr-v4
    ./parts/trust-admins
  ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.deadnix.enable = true;
        programs.nixfmt.enable = true;
      };

      minimalShells.direnv = with pkgs; [
        nixpkgs-fmt
        sops
        ssh-to-age
        go-task
      ];
    };
}
