{
  imports = [
    ./hosts/akane
    ./hosts/bootstrap
    ./hosts/brim
    ./hosts/kazuma
    ./hosts/saitama

    ./parts/base-system
    ./parts/btrfs-on-bcache
    ./parts/erase-your-darlings
    ./parts/installer
    ./parts/machine-info
    ./parts/nix-flakes
    ./parts/nixos-with-system
    ./parts/services
    ./parts/trust-admins
  ];

  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixpkgs-fmt;

    minimalShells.direnv = with pkgs; [
      nixpkgs-fmt
      sops
      ssh-to-age
      go-task
    ];
  };
}
